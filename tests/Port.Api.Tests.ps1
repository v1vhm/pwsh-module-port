Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/../src/Port.Api/Port.Api.psd1" -Force

Describe 'Port.Api module scaffolding' {
    It 'exports expected public functions' {
        $cmds = Get-Command -Module 'Port.Api' | Select-Object -ExpandProperty Name
        $cmds | Should -Contain 'Set-PortConnection'
        $cmds | Should -Contain 'New-PortAccessToken'
        $cmds | Should -Contain 'Set-PortEntity'
    }

    It 'sets connection context' {
        $ctx = Set-PortConnection -ClientId 'x' -ClientSecret 'y' -BaseUri 'https://example.test'
        $ctx.ClientId | Should -Be 'x'
        $ctx.ClientSecret | Should -Be 'y'
        $ctx.BaseUri | Should -Be 'https://example.test'
    }
}

Describe 'New-PortAccessToken' {
    InModuleScope Port.Api {
        BeforeAll {
            Set-PortConnection -ClientId 'CLIENT' -ClientSecret 'SECRET' -BaseUri 'https://api.getport.io' | Out-Null
        }

        It 'posts to /v1/auth/access_token and caches token' {
            $script:LastInvokeParams = $null
            Mock -CommandName Invoke-RestMethod -MockWith {
                param($Method,$Uri,$Body,$Headers)
                $script:LastInvokeParams = @{ Method=$Method; Uri=$Uri; Body=$Body; Headers=$Headers }
                # Simulate Port response
                [pscustomobject]@{ accessToken = 'abc123'; expiresIn = 3600 }
            }

            $result = New-PortAccessToken
            $result.AccessToken | Should -Be 'abc123'
            $result.ExpiresAt | Should -BeGreaterThan (Get-Date)

            # Validate the request parameters captured by the mock
            $script:LastInvokeParams | Should -Not -BeNullOrEmpty
            $script:LastInvokeParams.Uri | Should -Be 'https://api.getport.io/v1/auth/access_token'
            $script:LastInvokeParams.Method | Should -Be 'POST'

            # Verify exactly one call was made (from within module scope)
            Should -Invoke -CommandName Invoke-RestMethod -Times 1 -Exactly
        }
    }
}

Describe 'Set-PortEntity' {
    InModuleScope Port.Api {
        BeforeEach {
            # Reset connection each test
            Set-PortConnection -ClientId 'CLIENT' -ClientSecret 'SECRET' -BaseUri 'https://api.getport.io' | Out-Null
        }

        It 'respects -WhatIf via ShouldProcess' {
            # Ensure no HTTP call is made when -WhatIf is used
            Mock -CommandName Invoke-PortApi

            Set-PortEntity -BlueprintId 'service' -Identifier 'svc-1' -Properties @{ name = 'x' } -WhatIf

            Should -Invoke -CommandName Invoke-PortApi -Times 0 -Exactly
        }

        It 'calls Invoke-PortApi with correct path and body' {
            # Prevent real token acquisition during test
            Mock -CommandName New-PortAccessToken -MockWith { [pscustomobject]@{ AccessToken='token'; ExpiresAt=(Get-Date).AddMinutes(30) } }

            Mock -CommandName Invoke-PortApi -Verifiable -ParameterFilter {
                $Method -eq 'POST' -and 
                $Path -eq 'v1/blueprints/service/entities?upsert=true&merge=true' -and 
                $Body.identifier -eq 'svc-1' -and 
                $Body.blueprint -eq 'service' -and 
                $Body.properties.name -eq 'My Service' -and 
                $Body.title -eq 'Service One'
            } -MockWith {
                # Simulate Port response entity
                [pscustomobject]@{ identifier='svc-1'; blueprint='service'; title='Service One'; properties=@{ name='My Service' } }
            }

            $resp = Set-PortEntity -BlueprintId 'service' -Identifier 'svc-1' -Title 'Service One' -Properties @{ name = 'My Service' }

            $resp.identifier | Should -Be 'svc-1'
            $resp.title | Should -Be 'Service One'

            Assert-VerifiableMock
        }
    }
}

Describe 'Invoke-PortApi token refresh and error flow' {
    InModuleScope Port.Api {
        BeforeEach {
            Set-PortConnection -ClientId 'CLIENT' -ClientSecret 'SECRET' -BaseUri 'https://api.getport.io' | Out-Null
            # Force expiry to require refresh
            $script:PortContext.AccessToken = 'expired-token'
            $script:PortContext.TokenExpiry = (Get-Date).AddMinutes(-10)
        }

        It 'refreshes token when expired before calling API' {
            $script:Captured = $null

            Mock -CommandName New-PortAccessToken -MockWith { 
                $script:PortContext.AccessToken = 'new-token'
                [pscustomobject]@{ AccessToken='new-token'; ExpiresAt=(Get-Date).AddMinutes(30) }
            }

            Mock -CommandName Invoke-RestMethod -MockWith {
                param($Method,$Uri,$Headers)
                $script:Captured = @{ Method=$Method; Uri=$Uri; Auth=$Headers['Authorization'] }
                [pscustomobject]@{ ok = $true }
            }

            $resp = Invoke-PortApi -Method GET -Path 'v1/ping'
            $resp.ok | Should -BeTrue

            # Ensure refresh occurred and auth header used new token
            Should -Invoke -CommandName New-PortAccessToken -Times 1 -Exactly
            $script:Captured.Auth | Should -Be 'Bearer new-token'
            $script:Captured.Uri  | Should -Be 'https://api.getport.io/v1/ping'
        }

        It 'bubbles exceptions from Port calls' {
            Mock -CommandName New-PortAccessToken -MockWith { [pscustomobject]@{ AccessToken='tok'; ExpiresAt=(Get-Date).AddMinutes(30) } }
            Mock -CommandName Invoke-RestMethod -MockWith { throw 'Synthetic failure 422: validation' }

            { Invoke-PortApi -Method POST -Path 'v1/blueprints/svc/entities' -Body @{ identifier='x' } } | Should -Throw
        }

        It 'surfaces 401 Unauthorized with body content' {
            function New-FakeHttpException {
                param([int]$Status,[string]$Content)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                $resp = New-Object psobject
                $resp | Add-Member NoteProperty StatusCode $Status
                $resp | Add-Member NoteProperty ContentLength $bytes.Length
                $resp | Add-Member NoteProperty Bytes $bytes
                $resp | Add-Member ScriptMethod GetResponseStream { param() ([System.IO.MemoryStream]::new($this.Bytes)) }
                $ex = [System.Exception]::new("HTTP $Status")
                $ex | Add-Member NoteProperty Response $resp
                return $ex
            }

            Mock -CommandName New-PortAccessToken -MockWith { [pscustomobject]@{ AccessToken='tok'; ExpiresAt=(Get-Date).AddMinutes(30) } }
            Mock -CommandName Invoke-RestMethod -MockWith { throw (New-FakeHttpException -Status 401 -Content '{"message":"Unauthorized"}') }

            $thrown = $false; $msg = $null
            try { 
                Invoke-PortApi -Method GET -Path 'v1/secure'
            } catch {
                $thrown = $true; $msg = $_.Exception.Message
            }
            $thrown | Should -BeTrue
            $msg | Should -Match '401'
            $msg | Should -Match 'Unauthorized'
        }

        It 'surfaces 422 Validation error with body content' {
            function New-FakeHttpException2 {
                param([int]$Status,[string]$Content)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                $resp = New-Object psobject
                $resp | Add-Member NoteProperty StatusCode $Status
                $resp | Add-Member NoteProperty ContentLength $bytes.Length
                $resp | Add-Member NoteProperty Bytes $bytes
                $resp | Add-Member ScriptMethod GetResponseStream { param() ([System.IO.MemoryStream]::new($this.Bytes)) }
                $ex = [System.Exception]::new("HTTP $Status")
                $ex | Add-Member NoteProperty Response $resp
                return $ex
            }

            Mock -CommandName New-PortAccessToken -MockWith { [pscustomobject]@{ AccessToken='tok'; ExpiresAt=(Get-Date).AddMinutes(30) } }
            Mock -CommandName Invoke-RestMethod -MockWith { throw (New-FakeHttpException2 -Status 422 -Content '{"message":"validation error"}') }

            $thrown = $false; $msg = $null
            try {
                Invoke-PortApi -Method POST -Path 'v1/blueprints/svc/entities' -Body @{ identifier='x' }
            } catch {
                $thrown = $true; $msg = $_.Exception.Message
            }
            $thrown | Should -BeTrue
            $msg | Should -Match '422'
            $msg | Should -Match 'validation'
        }
    }
}
