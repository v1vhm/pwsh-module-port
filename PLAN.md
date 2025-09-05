# PLAN: Project Development Roadmap

> **Scope (v0.x)**: PowerShell 7.2-compatible module for **Port** authentication and **entity upsert**. Clean, minimal codebase with CI/CD via GitHub Actions. Future endpoints (blueprints, webhooks, GET/DELETE, etc.) are intentionally deferred.

**Living document** — update this plan as phases complete or scope changes. Each PR that changes behavior should include a corresponding PLAN.md update.

---

## Phase 1 — Review & Foundation

Status: ✅ Completed (2025-09-05)

- Updated manifest to target PowerShell 7.2 (Core).
- Corrected auth endpoint to `/v1/auth/access_token` per SPEC.
- Implemented upsert path `v1/blueprints/<BlueprintId>/entities?upsert=true&merge=true` with URL encoding.
- Added optional `-Title` to `Set-PortEntity` and expanded help stubs for public cmdlets.
- Smoke test passed via Pester (module imports, exports correct cmdlets, context set).

**Goal:** Validate scaffolding, align to best practices, and ensure a clean baseline.

**Tasks**

* Verify module layout and manifest:

  * `src/Port.Api/Port.Api.psd1` (metadata, `ModuleVersion`, `CompatiblePSEditions`, `PowerShellVersion >= 7.2`)
  * `src/Port.Api/Port.Api.psm1` (dot-source functions; explicit `Export-ModuleMember`)
  * `Public/` vs `Private/` separation
* Align cmdlets and parameters to guidelines:

  * Public: `Set-PortConnection`, `New-PortAccessToken`, `Set-PortEntity`
  * Use approved verbs, PascalCase params, `CmdletBinding()`, `SupportsShouldProcess` where applicable
* Confirm endpoint shapes vs SPEC.md:

  * Auth: `POST /v1/auth/access_token`
  * Upsert: `POST /v1/blueprints/{blueprintId}/entities?upsert=true&merge=true`
* Ensure comment-based help stubs exist for each public cmdlet.
* Smoke test import (`Import-Module`) locally.

**Deliverables**

* Fixed scaffolding (if needed) and passing import.
* Updated SPEC.md/AGENTS.md for any deviations discovered.

---

## Phase 2 — Core Features & CI

Status: ✅ Completed (2025-09-05)

**Goal:** Implement working auth + upsert and add CI for tests and packaging.

**Tasks**

* **Authentication**

  * Implement `New-PortAccessToken`:

    * Body: `clientId`, `clientSecret`
    * Parse `accessToken`, `expiresIn` → compute `ExpiresAt`
    * Cache in in-memory context; never log secrets
  * `Invoke-PortApi`:

    * Auto-attach `Authorization: Bearer <token>`
    * Refresh on expiry (buffer \~60s)
* **Entity Upsert**

  * Implement `Set-PortEntity`:

    * URL: `/v1/blueprints/{BlueprintId}/entities?upsert=true&merge=true`
    * Body: `identifier`, optional `title`, `properties`, optional `relations`
    * Respect `-WhatIf` via `ShouldProcess`
    * Return parsed JSON object
* **CI (GitHub Actions)**

  * Workflow `.github/workflows/ci.yml`:

    * Triggers: PRs and pushes to main
    * Matrix: `os: [ubuntu-latest, windows-latest]`, `pwsh: [7.2.x]`
    * Steps: checkout → setup PowerShell → install Pester (if needed) → `Invoke-Pester` → optional PSScriptAnalyzer
  * Packaging job:

    * Build artifact: zip `src/Port.Api` (psd1, psm1, Public/, Private/)
    * Upload artifact on every successful build

**Deliverables**

* Working `New-PortAccessToken` and `Set-PortEntity`
* Passing CI with test results and build artifact

**Notes**

* Unit tests validate auth call + caching, upsert path/body, and `-WhatIf`
* CI packages module and uploads artifacts on all matrix OS

---

## Phase 3 — Compatibility & Quality

Status: ✅ Completed (2025-09-05)

**Goal:** Solidify reliability, compatibility, and code quality.

**Tasks**

* **Compatibility**

  * Verify on PowerShell **7.2** (Linux/Windows runners)
  * (Optional) Spot-check Windows PowerShell 5.1 if supported in manifest
* **Testing**

  * Pester unit tests:

    * Success/failure of auth (mock `Invoke-RestMethod`)
    * Token refresh path
    * Upsert success (201/200), validation error surface (400/422)

**Progress Notes**

* Added tests covering:
  * Auth happy path (POST /v1/auth/access_token) with caching
  * Token refresh triggered when expired; Authorization uses refreshed token
  * `Set-PortEntity` WhatIf behavior and correct upsert path/body
  * Error bubbling for failed HTTP calls
  
**Follow-up Tasks (optional)**

* CI: Pin PowerShell explicitly (e.g., use `actions/setup-pwsh@v1` with `7.2.x`) rather than relying on runner default + version check.
* Tests: Expand error-path assertions for 401/422 to validate surfaced status/message content precisely.
* Help/Docs: Flesh out comment-based help with more concrete, runnable examples; ensure README usage mirrors help examples.
* **Static Analysis**

  * PSScriptAnalyzer (fail on errors; warn on style)
  * Remove aliases; ensure approved verbs; parameter casing; unused vars
* **Docs & Versioning**

  * Flesh out comment-based help with real examples
  * Update README usage snippets
  * Bump `ModuleVersion` appropriately (e.g., `0.1.0`)

**Deliverables**

* Green tests, clean analyzer output, updated docs/examples
* Ready for tagging (pre-release or release candidate)

---

## Phase 4 — Release Automation

Status: 🚧 In progress (2025-09-05)

**Goal:** Ship versioned artifacts tied to GitHub Releases.

**Tasks**

* Workflow `.github/workflows/release.yml`:

  * Trigger: tag `v*` or GitHub Release
  * Validate + package module
  * Attach artifact(s) to Release
  * (Optional) Generate release notes from conventional commits
* Add README badge for CI status and link to Releases

**Deliverables**

* Reproducible, versioned artifacts on each tagged release

---

## Phase 5 — Hardening & UX polish (ongoing)

**Goal:** Improve user experience without expanding API surface yet.

**Tasks**

* Verbose logging (opt-in; scrub secrets)
* Friendlier error surfaces (parse Port error JSON for clear messages)
* More examples (scripts for common tasks)
* Optional: `-FullOverwrite` switch to replace (non-merge) upserts

**Deliverables**

* Nicer ergonomics, clearer troubleshooting, documented behaviors

---

## Future Work (deferred; do not implement yet)

> Track each below item as a separate mini-phase when you choose to start it. Add API details to SPEC.md before implementation.

* **Read/list/delete**

  * `Get-PortEntity`, `Get-PortEntities`, `Remove-PortEntity`
* **Blueprints & metadata**

  * `Get-PortBlueprint`, `Get-PortBlueprints`
* **Actions / Webhooks / Events**

  * `Invoke-PortAction`, webhook registration helpers
* **Config management**

  * Multiple contexts; optional secure storage (CredMan/Keychain)
* **Publishing**

  * PowerShell Gallery publish pipeline (API key secrets; `Publish-Module`)

---

## Governance & Updates

* Every feature PR **must update** SPEC.md (if API usage changes) and this PLAN.md (phase status).
* Keep **AGENTS.md** in sync with any coding-standards decisions.
* Use small, incremental phases; mark completed phases with a ✅ and the date.

---

## Milestone Checklist

* [x] **P1**: Foundation validated; import succeeds; docs aligned
* [x] **P2**: Auth + Upsert implemented; CI green; artifact published
* [x] **P3**: Tests expanded; analyzer clean; docs/examples improved
* [ ] **P4**: Release workflow; tagged builds attach artifacts
* [ ] **P5**: UX polish; logging; nicer errors

---

**Owner:** Platform Engineering / Developer Experience
**Target runtime:** PowerShell **7.2**
**CI/CD:** GitHub Actions (Linux + Windows)
**Last updated:** 2025-09-05 (Europe/London)
