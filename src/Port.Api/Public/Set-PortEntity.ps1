function Set-PortEntity {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BlueprintId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Identifier,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$Properties,

        [Parameter()]
        [hashtable]$Relations,

        [Parameter()]
        [string]$BaseUri
    )

    <#
    .SYNOPSIS
    Create or update (upsert) an entity in Port.

    .DESCRIPTION
    Upserts a Port entity for the specified blueprint. Uses module connection context and authentication helper.

    .EXAMPLE
    Set-PortEntity -BlueprintId 'service' -Identifier 'my-service' -Properties @{ name = 'My Service' }
    #>

    $body = @{
        identifier = $Identifier
        blueprint  = $BlueprintId
        properties = $Properties
    }
    if ($Relations) { $body['relations'] = $Relations }

    $path = 'v1/entities'
    if ($PSCmdlet.ShouldProcess($Identifier, 'Upsert Port entity')) {
        Invoke-PortApi -Method 'POST' -Path $path -Body $body -BaseUri $BaseUri
    }
}

