# Port.Api PowerShell Module

A PowerShell module for interacting with the Port API. Initial focus is authenticating with Port and upserting entities.

This repository follows PowerShell module best practices for structure, naming, and help.

## Status

- Core features implemented
  - Public cmdlets: `Set-PortConnection`, `New-PortAccessToken`, `Set-PortEntity`
  - Private helper: `Invoke-PortApi`
- CI: tests run on Windows/Linux; artifacts uploaded per build

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
