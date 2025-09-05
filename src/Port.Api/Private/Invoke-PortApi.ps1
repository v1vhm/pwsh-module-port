function Invoke-PortApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET','POST','PUT','PATCH','DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [string]$BaseUri
    )

    # Module-scoped context
    if (-not $BaseUri) { $BaseUri = $script:PortContext.BaseUri }
    if (-not $BaseUri) { throw 'BaseUri is not set. Use Set-PortConnection or pass -BaseUri.' }

    # Ensure token is available
    if (-not $script:PortContext.AccessToken -or (Get-Date) -ge $script:PortContext.TokenExpiry) {
        # Acquire a new token via public helper
        $null = New-PortAccessToken -ErrorAction Stop
    }

    # Build full request URI robustly (avoid ambiguous Uri ctor overloads)
    $uri = "$( $BaseUri.TrimEnd('/') )/$( $Path.TrimStart('/') )"

    $defaultHeaders = @{
        'Authorization' = "Bearer $($script:PortContext.AccessToken)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
    if ($Headers) {
        foreach ($k in $Headers.Keys) { $defaultHeaders[$k] = $Headers[$k] }
    }

    $irmParams = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $defaultHeaders
        ErrorAction = 'Stop'
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $irmParams['Body'] = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }

    try {
        # Verbose (no secrets): log method/uri and basic body shape
        Write-Verbose ("HTTP {0} {1}" -f $Method, $uri)
        if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body -and -not ($Body -is [string])) {
            $bodyKeys = ($Body | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
            if ($bodyKeys) { Write-Verbose ("Request body keys: {0}" -f ($bodyKeys -join ', ')) }
        }
        Invoke-RestMethod @irmParams
    }
    catch {
        $response = $_.Exception.Response
        if ($response -and $response.ContentLength -gt 0) {
            try {
                $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                $content = $reader.ReadToEnd()

                # Defaults
                $statusCode = $response.StatusCode
                try { $statusCode = [int]$response.StatusCode } catch { }
                $errorCode = $null
                $msg = $null
                $details = $null

                # Try to parse JSON error for clearer message
                try {
                    $json = $content | ConvertFrom-Json -ErrorAction Stop
                    $errorCode = $json.error ?? $json.code
                    $msg = $json.message ?? $json.error ?? $null
                    $details = $json.details
                } catch { }

                if ([string]::IsNullOrWhiteSpace($msg)) { $msg = $content }

                $pathHint = $null
                if ($details -and $details.instancePath) { $pathHint = [string]$details.instancePath }

                $summary = "Port API error: $statusCode"
                if ($errorCode) { $summary += " $errorCode" }
                $summary += " - $msg"
                if ($pathHint) { $summary += " (path: $pathHint)" }

                # Build rich ErrorRecord without leaking secrets
                $ex = [System.Exception]::new($summary)
                $ex.Data['PortApiError'] = [pscustomobject]@{
                    StatusCode   = $statusCode
                    Error        = $errorCode
                    Message      = $msg
                    InstancePath = $pathHint
                    Uri          = $uri
                    Raw          = $content
                }

                $category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                if ($statusCode -is [int]) {
                    if ($statusCode -eq 401 -or $statusCode -eq 403) { $category = [System.Management.Automation.ErrorCategory]::SecurityError }
                    elseif ($statusCode -eq 404) { $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound }
                    elseif ($statusCode -ge 400 -and $statusCode -lt 500) { $category = [System.Management.Automation.ErrorCategory]::InvalidData }
                    elseif ($statusCode -ge 500) { $category = [System.Management.Automation.ErrorCategory]::InvalidOperation }
                }

                $errId = "PortApi:$statusCode" + ($(if ($errorCode) { ":$errorCode" } else { '' }))
                $err = New-Object System.Management.Automation.ErrorRecord($ex, $errId, $category, $uri)
                if ($PSCmdlet) { $PSCmdlet.ThrowTerminatingError($err) } else { throw $ex }
            } catch {
                throw $_
            }
        }
        throw $_
    }
}
