function Set-PortConnection {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri = 'https://api.getport.io'
    )

    <#
    .SYNOPSIS
    Set Port API connection details in the current session.

    .DESCRIPTION
    Stores client credentials and base API URI in module scope for subsequent commands.

    .PARAMETER ClientId
    The Port client ID from your tenant credentials.

    .PARAMETER ClientSecret
    The Port client secret from your tenant credentials. Not persisted.

    .PARAMETER BaseUri
    The base API URI for your region (e.g. https://api.getport.io).

    .EXAMPLE
    Set-PortConnection -ClientId 'id' -ClientSecret 'secret' -BaseUri 'https://api.getport.io'

    .EXAMPLE
    # Use default BaseUri (EU) and then request a token
    Set-PortConnection -ClientId 'id' -ClientSecret 'secret'
    $null = New-PortAccessToken
    # Subsequent calls will reuse the cached token until near expiry

    .NOTES
    Secrets are stored only in memory for the session and are not logged.
    .LINK
    SPEC.md
    #>

    if ($PSCmdlet.ShouldProcess($BaseUri, 'Set Port connection context')) {
        $script:PortContext = [ordered]@{
            ClientId     = $ClientId
            ClientSecret = $ClientSecret
            BaseUri      = $BaseUri.TrimEnd('/')
            AccessToken  = $null
            TokenExpiry  = Get-Date '2001-01-01'
        }
        Write-Verbose ("Connection context set for BaseUri: {0}" -f $script:PortContext.BaseUri)
        return [pscustomobject]$script:PortContext
    }
}
