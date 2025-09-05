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

    .EXAMPLE
    Set-PortConnection -ClientId 'id' -ClientSecret 'secret' -BaseUri 'https://api.getport.io'
    #>

    if ($PSCmdlet.ShouldProcess($BaseUri, 'Set Port connection context')) {
        $script:PortContext = [ordered]@{
            ClientId     = $ClientId
            ClientSecret = $ClientSecret
            BaseUri      = $BaseUri.TrimEnd('/')
            AccessToken  = $null
            TokenExpiry  = Get-Date '2001-01-01'
        }
        return [pscustomobject]$script:PortContext
    }
}

