# Port.Api PowerShell Module

[![CI](https://github.com/v1vhm/pwsh-module-port/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/v1vhm/pwsh-module-port/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/v1vhm/pwsh-module-port?display_name=tag&sort=semver)](https://github.com/v1vhm/pwsh-module-port/releases)

A PowerShell module for interacting with the Port API. Initial focus is authenticating with Port and upserting entities.

This repository follows PowerShell module best practices for structure, naming, and help.

## Status

- Core features implemented
  - Public cmdlets: `Set-PortConnection`, `New-PortAccessToken`, `Set-PortEntity`
  - Private helper: `Invoke-PortApi`
- CI: tests run on Windows/Linux; artifacts uploaded per build
 - Releases: see https://github.com/v1vhm/pwsh-module-port/releases

## Requirements

- PowerShell 7.2 (Core)
- Pester 5+ (install via `Install-Module Pester -Scope CurrentUser -MinimumVersion 5.5.0`)
  - Note: The inbox Pester 3.x in Windows PowerShell 5.1 is not supported.

## Quick Start

```powershell
# Import the module from source
Import-Module (Join-Path $PSScriptRoot 'src/Port.Api/Port.Api.psd1') -Force

# Configure connection (client ID/secret from Port)
Set-PortConnection -ClientId 'your_client_id' -ClientSecret 'your_client_secret' -BaseUri 'https://api.getport.io'

# Get a new access token (uses connection details above)
$token = New-PortAccessToken

# Upsert an entity (non-destructive merge by default)
Set-PortEntity -BlueprintId 'service' -Identifier 'my-service' -Properties @{ name = 'My Service'; tier = 'gold' }

# Preview without making changes
Set-PortEntity -BlueprintId 'service' -Identifier 'my-preview' -Properties @{ name = 'Preview' } -WhatIf
```

## Module Layout

- `src/Port.Api/Port.Api.psd1` – Module manifest
- `src/Port.Api/Port.Api.psm1` – Module root, loads public/private functions
- `src/Port.Api/Public/*` – Public cmdlets (exported)
- `src/Port.Api/Private/*` – Internal helpers (not exported)
- `tests/*` – Pester tests

## Development

```powershell
# Install Pester 5 if needed
Install-Module Pester -Scope CurrentUser -MinimumVersion 5.5.0

# Run tests (requires PS 7.2+)
./scripts/Invoke-Tests.ps1

# Import locally
Import-Module ./src/Port.Api/Port.Api.psd1 -Force
```

If you prefer a one-liner without the script:

```powershell
$v=(Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select -First 1).Version.Major; if($v -ge 5){ Invoke-Pester -Path tests -CI } else { Invoke-Pester -Path tests -EnableExit }
```

## Notes

- Endpoints and request payloads are implemented with conservative defaults and are easy to adjust. Validate against the latest Port API documentation.
- Client secret handling: provided as a string for HTTP exchange; avoid persisting secrets.

**Release Process**

- Bump Version: Update `ModuleVersion` and `ReleaseNotes` in `src/Port.Api/Port.Api.psd1`.
- Create Tag/Release: Tag the repo (e.g., `v0.1.1`) or publish a GitHub Release.
- Automation: The workflow in `.github/workflows/release.yml` runs on tag/release, validates with Pester + PSScriptAnalyzer, packages the module, and attaches artifacts to the Release.
- Artifacts: Zips per OS matrix (e.g., `port-api-ubuntu-latest.zip`, `port-api-windows-latest.zip`) containing `Port.Api.psd1`, `Port.Api.psm1`, and the `Public/` and `Private/` folders.
- Consumption: Download the zip from the Release, extract, then `Import-Module ./Port.Api/Port.Api.psd1 -Force` from the extracted path.
- Pre-release: If using prerelease labels, adjust `PrivateData.PSData.Prerelease` in the manifest as needed.
