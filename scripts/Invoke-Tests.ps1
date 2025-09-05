param(
    [Parameter()]
    [string]$Path = 'tests'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Runs Pester tests with required environment.

.DESCRIPTION
Requires PowerShell 7.2+ (Core) and Pester 5+. If Pester 5 is not found,
prints an actionable error with installation instructions.

.PARAMETER Path
Test path to run (defaults to 'tests').

.EXAMPLE
./scripts/Invoke-Tests.ps1

.EXAMPLE
pwsh -NoLogo -NoProfile -File ./scripts/Invoke-Tests.ps1 -Path tests
#>

function Invoke-RequiredPester {
    param(
        [Parameter(Mandatory)] [string]$TestPath
    )

    if (-not $PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [version]'7.2') {
        Write-Error "Please run tests under PowerShell 7.2+ (pwsh, Core edition). Current: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)" -ErrorAction Stop
    }

    $pester5 = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version.Major -ge 5 } | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pester5) {
        Write-Error "Pester 5+ is required. Install with: Install-Module Pester -Scope CurrentUser -MinimumVersion 5.5.0" -ErrorAction Stop
    }

    Import-Module $pester5 -Force
    Write-Host "Running Pester v$($pester5.Version) with -CI" -ForegroundColor Cyan
    Invoke-Pester -Path $TestPath -CI
}

Invoke-RequiredPester -TestPath $Path
