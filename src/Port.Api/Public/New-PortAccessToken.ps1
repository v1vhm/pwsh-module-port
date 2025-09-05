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

    .EXAMPLE
    New-PortAccessToken

    .EXAMPLE
    New-PortAccessToken -ClientId 'id' -ClientSecret 'secret' -BaseUri 'https://api.getport.io'
    #>

    $ctx = $script:PortContext
    if (-not $ClientId) { $ClientId = $ctx.ClientId }
    if (-not $ClientSecret) { $ClientSecret = $ctx.ClientSecret }
    if (-not $BaseUri) { $BaseUri = $ctx.BaseUri }

    if (-not $ClientId -or -not $ClientSecret) {
        throw 'ClientId and ClientSecret must be provided or set via Set-PortConnection.'
    }
    if (-not $BaseUri) { throw 'BaseUri must be provided or set via Set-PortConnection.' }

    $uri = [System.Uri]::new($BaseUri.TrimEnd('/'), 'v1/auth/access-token')
    $body = @{ clientId = $ClientId; clientSecret = $ClientSecret }

    $irmParams = @{
        Method      = 'POST'
        Uri         = $uri.AbsoluteUri
        Body        = ($body | ConvertTo-Json)
        Headers     = @{ 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }
        ErrorAction = 'Stop'
    }

    try {
        $resp = Invoke-RestMethod @irmParams
    } catch {
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

