# Dot-source private and public functions, then export public ones

$moduleRoot = Split-Path -Path $PSCommandPath -Parent

# Load Private functions first
Get-ChildItem -Path (Join-Path $moduleRoot 'Private') -Filter *.ps1 -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }

# Load Public functions and track names for export
$publicFunctions = @()
Get-ChildItem -Path (Join-Path $moduleRoot 'Public') -Filter *.ps1 -ErrorAction SilentlyContinue |
    ForEach-Object {
        . $_.FullName
        $fn = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $publicFunctions += $fn
    }

if ($publicFunctions.Count -gt 0) {
    Export-ModuleMember -Function $publicFunctions
}

