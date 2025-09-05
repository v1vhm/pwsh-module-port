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
