function Set-PortEntity {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BlueprintId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Identifier,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

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

    .PARAMETER BlueprintId
    The target blueprint identifier in Port.

    .PARAMETER Identifier
    The unique identifier of the entity within the blueprint.

    .PARAMETER Title
    Optional display title for the entity.

    .PARAMETER Properties
    Hashtable of properties that conform to the blueprint schema.

    .PARAMETER Relations
    Optional relations hashtable; keys must match blueprint relations.

    .EXAMPLE
    Set-PortEntity -BlueprintId 'service' -Identifier 'my-service' -Properties @{ name = 'My Service' }

    .EXAMPLE
    Set-PortEntity -BlueprintId 'service' -Identifier 'svc-1' -Title 'Service One' -Properties @{ tier = 'gold' } -Relations @{ team = @('platform') }
    
    .NOTES
    Uses non-destructive merge semantics by default (upsert=true&merge=true).
    .LINK
    SPEC.md
    #>

    $body = @{
        identifier = $Identifier
        blueprint  = $BlueprintId
        properties = $Properties
    }
    if ($PSBoundParameters.ContainsKey('Title') -and $Title) { $body['title'] = $Title }
    if ($Relations) { $body['relations'] = $Relations }

    $encodedBlueprint = [System.Uri]::EscapeDataString($BlueprintId)
    $path = "v1/blueprints/$encodedBlueprint/entities?upsert=true&merge=true"
    if ($PSCmdlet.ShouldProcess("$BlueprintId/$Identifier", 'Upsert Port entity')) {
        Invoke-PortApi -Method 'POST' -Path $path -Body $body -BaseUri $BaseUri
    }
}
