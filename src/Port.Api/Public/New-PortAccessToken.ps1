function New-PortAccessToken {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$ClientSecret,

        [Parameter()]
        [string]$BaseUri
    )

    <#
    .SYNOPSIS
    Request a new access token from the Port API.

    .DESCRIPTION
    Calls the Port access token endpoint using client credentials. If parameters are not provided, uses values set via Set-PortConnection.

    .PARAMETER ClientId
    Optional client ID; if omitted, uses the value set via Set-PortConnection.

    .PARAMETER ClientSecret
    Optional client secret; if omitted, uses the value set via Set-PortConnection.

    .PARAMETER BaseUri
    Optional base API URI; if omitted, uses the value set via Set-PortConnection.

    .EXAMPLE
    New-PortAccessToken

    .EXAMPLE
    New-PortAccessToken -ClientId 'id' -ClientSecret 'secret' -BaseUri 'https://api.getport.io'

    .EXAMPLE
    # With prior Set-PortConnection, omit parameters for convenience
    Set-PortConnection -ClientId 'id' -ClientSecret 'secret' -BaseUri 'https://api.getport.io'
    $tok = New-PortAccessToken
    $tok.AccessToken.Substring(0,10)

    .NOTES
    Does not write secrets to logs. Caches token and a pre-expiry timestamp in memory.
    .LINK
    SPEC.md
    #>

    $ctx = $script:PortContext
    if (-not $ClientId) { $ClientId = $ctx.ClientId }
    if (-not $ClientSecret) { $ClientSecret = $ctx.ClientSecret }
    if (-not $BaseUri) { $BaseUri = $ctx.BaseUri }

    if (-not $ClientId -or -not $ClientSecret) {
        throw 'ClientId and ClientSecret must be provided or set via Set-PortConnection.'
    }
    if (-not $BaseUri) { throw 'BaseUri must be provided or set via Set-PortConnection.' }

    # Build full auth URI robustly (avoid ambiguous Uri ctor overloads)
    $uri = "$( $BaseUri.TrimEnd('/') )/v1/auth/access_token"
    $body = @{ clientId = $ClientId; clientSecret = $ClientSecret }

    $irmParams = @{
        Method      = 'POST'
        Uri         = $uri
        Body        = ($body | ConvertTo-Json)
        Headers     = @{ 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }
        ErrorAction = 'Stop'
    }

    try {
        Write-Verbose ("Requesting access token from {0}" -f $uri)
        $resp = Invoke-RestMethod @irmParams
    } catch {
        # Surface clearer message if possible; avoid leaking secrets
        $response = $_.Exception.Response
        if ($response -and $response.ContentLength -gt 0) {
            try {
                $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                $content = $reader.ReadToEnd()

                $statusCode = $response.StatusCode
                try { $statusCode = [int]$response.StatusCode } catch { }
                $msg = $null
                $errorCode = $null
                try {
                    $json = $content | ConvertFrom-Json -ErrorAction Stop
                    $msg = $json.message ?? $json.error ?? $null
                    $errorCode = $json.error ?? $json.code
                } catch { }
                if ([string]::IsNullOrWhiteSpace($msg)) { $msg = $content }

                $summary = "Port API auth failed: $statusCode"
                if ($errorCode) { $summary += " $errorCode" }
                $summary += " - $msg"

                $ex = [System.Exception]::new($summary)
                $ex.Data['PortApiAuthError'] = [pscustomobject]@{
                    StatusCode = $statusCode
                    Error      = $errorCode
                    Message    = $msg
                    Uri        = $uri
                }
                $err = New-Object System.Management.Automation.ErrorRecord(
                    $ex,
                    ("PortApiAuth:{0}{1}" -f $statusCode, ($(if ($errorCode) { ":$errorCode" } else { '' }))),
                    [System.Management.Automation.ErrorCategory]::SecurityError,
                    $uri
                )
                if ($PSCmdlet) { $PSCmdlet.ThrowTerminatingError($err) } else { throw $ex }
            } catch { throw $_ }
        }
        throw $_
    }

    # Expect shape like: { accessToken: '...', expiresIn: 3600 }
    $token = $resp.accessToken ?? $resp.token ?? $resp.access_token
    $expiresIn = $resp.expiresIn ?? $resp.expires_in
    if (-not $token) { throw 'Access token not found in response.' }

    $script:PortContext.AccessToken = $token
    if ($expiresIn -is [int] -and $expiresIn -gt 0) {
        $script:PortContext.TokenExpiry = (Get-Date).AddSeconds([int]$expiresIn - 60)
    } else {
        # Fallback: set 55 minutes
        $script:PortContext.TokenExpiry = (Get-Date).AddMinutes(55)
    }

    [pscustomobject]@{
        AccessToken = $script:PortContext.AccessToken
        ExpiresAt   = $script:PortContext.TokenExpiry
        BaseUri     = $BaseUri
    }
}
