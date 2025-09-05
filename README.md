# Port.Api PowerShell Module

A PowerShell module for interacting with the Port API. Initial focus is authenticating with Port and upserting entities.

This repository follows PowerShell module best practices for structure, naming, and help.

## Status

- Scaffolding in place
- Public cmdlets (stubs): `Set-PortConnection`, `New-PortAccessToken`, `Set-PortEntity`
- Private helper: `Invoke-PortApi`

## Requirements

- PowerShell 5.1 or later (PowerShell 7+ recommended)

## Quick Start

```powershell
# Import the module from source
Import-Module (Join-Path $PSScriptRoot 'src/Port.Api/Port.Api.psd1') -Force

# Configure connection (client ID/secret from Port)
Set-PortConnection -ClientId 'your_client_id' -ClientSecret 'your_client_secret' -BaseUri 'https://api.getport.io'

# Get a new access token
$token = New-PortAccessToken

# Upsert an entity (example shape, verify with Port API docs)
Set-PortEntity -BlueprintId 'service' -Identifier 'my-service' -Properties @{ name = 'My Service'; tier = 'gold' }
```

## Module Layout

- `src/Port.Api/Port.Api.psd1` – Module manifest
- `src/Port.Api/Port.Api.psm1` – Module root, loads public/private functions
- `src/Port.Api/Public/*` – Public cmdlets (exported)
- `src/Port.Api/Private/*` – Internal helpers (not exported)
- `tests/*` – Pester tests

## Development

```powershell
# Run tests
Invoke-Pester -Path tests

# Import locally
Import-Module ./src/Port.Api/Port.Api.psd1 -Force
```

## Notes

- Endpoints and request payloads are implemented with conservative defaults and are easy to adjust. Validate against the latest Port API documentation.
- Client secret handling: provided as a string for HTTP exchange; avoid persisting secrets.

