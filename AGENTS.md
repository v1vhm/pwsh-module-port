# AGENTS.md

## Project overview

**Port.Api** is a PowerShell module that interacts with the Port platform’s REST API. The initial scope focuses on:

* **Authentication** via Port’s client-credentials flow (client ID + client secret → access token).
* **Upserting entities** into Port (create or update by identifier) for a given blueprint.

The module targets **PowerShell 7.2** for broad compatibility and uses **GitHub Actions** for CI/CD.

> Before contributing, **read** `SPEC.md` (API & auth details) and `PLAN.md` (delivery phases & roadmap). Keep both documents up to date as you work.

---

## Goals (v0.x)

* Provide a clean, idiomatic PowerShell interface to Port’s auth and entity upsert endpoints.
* Implement robust error handling and `-WhatIf`/`-Confirm` semantics for safety.
* Ship a repeatable CI/CD pipeline that tests and publishes versioned module artifacts.

Out of scope for the first iteration: broader Port APIs (blueprints, webhooks, scorecards, etc.). These are referenced in `PLAN.md` and will be added incrementally.

---

## Repository structure

```
src/
  Port.Api/
    Port.Api.psd1          # Module manifest
    Port.Api.psm1          # Root module (imports/exports functions)
    Public/                # Exported cmdlets (one .ps1 per cmdlet)
    Private/               # Internal helpers (not exported)
tests/
  ...                      # Pester tests
.github/
  workflows/
    ci.yml                 # Test & static analysis
    release.yml            # Package & attach artifacts on release/tag
docs/                      # (optional) Additional guides/examples
AGENTS.md
SPEC.md
PLAN.md
README.md
```

* **Public** vs **Private**: Public cmdlets live in `Public/` and are exported explicitly. Helpers live in `Private/` and are not exported.
* Keep each public cmdlet in its **own file** with complete comment-based help.

---

## Coding standards

### 1) Cmdlet design & naming

* **Verb-Noun** with **approved verbs** (e.g., `Get`, `Set`, `New`, `Remove`).
* Use a **domain prefix** for nouns to avoid collisions, e.g. `Set-**Port**Entity`, `New-**Port**AccessToken`.
* Singular nouns (`Entity`, not `Entities`) unless the parameter inherently represents multiple items.

### 2) Parameters & types

* PascalCase parameter names (`-BlueprintId`, `-Identifier`, `-Properties`).
* Prefer **strong typing** where sensible (e.g., `[string]`, `[hashtable]`, `[uri]`, `[switch]`).
* Use **parameter sets** to clarify mutually exclusive paths.
* Validate inputs with `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc., where appropriate.

### 3) User experience

* Apply `[CmdletBinding(SupportsShouldProcess = $true)]` on cmdlets that call external systems.
* Wrap changes in `if ($PSCmdlet.ShouldProcess(...)) { ... }` to support **`-WhatIf`/`-Confirm`**.
* Return **objects**, not formatted strings; avoid `Write-Host`. Support `-PassThru` when the cmdlet’s primary purpose is an action.

### 4) Error handling

* Use `try { ... } catch { ... }` around HTTP calls and other failure points.
* Throw **clear, actionable** errors (include HTTP status and concise API message text).
* Internally invoke risky calls with `-ErrorAction Stop` so exceptions are catchable.
* Never include secrets/tokens in errors, logs, or verbose output.

### 5) Style & readability

* Avoid aliases (`?`, `%`, etc.); use full cmdlet names.
* Prefer clear names over clever ones (`$AccessTokenExpiryUtc`, not `$exp`).
* Keep functions small and focused. Push reusable logic to `Private/` helpers.
* Document non-obvious behavior inline with comments.

### 6) Security & secrets

* Store **client secret** and **access token** only **in memory** (module context) for the session.
* Do **not** write secrets to disk, console, transcripts, or logs.
* When adding verbose/debug messages, double-check that no secret material leaks.

### 7) Help & examples

* Every public cmdlet must include **comment-based help**:

  * `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`, `.LINK`
* Provide at least **two realistic examples** that actually work.

### 8) Testing & analysis

* Write **Pester** tests for success and failure paths.
* Use **PSScriptAnalyzer**; fix warnings or document justified suppressions.
* Keep tests fast and deterministic; mock external calls (`Invoke-RestMethod`) where possible.

---

## Public cmdlets (initial)

* `Set-PortConnection`
  Sets base URI, client ID, client secret (session-scoped). Does not persist secrets.

* `New-PortAccessToken`
  Calls Port auth endpoint with client credentials; caches token & expiry in memory.

* `Set-PortEntity`
  Upserts an entity under a blueprint. Defaults to **non-destructive** updates (merge semantics).

> See `SPEC.md` for request/response shapes, headers, and endpoint paths.

---

## Contribution workflow

1. **Read** `SPEC.md` and `PLAN.md`.
2. **Branch** from `main` using a descriptive name (e.g., `feature/upsert-merge-param`).
3. **Develop**:

   * Follow coding standards above.
   * Add/adjust **Pester tests** and **comment-based help**.
   * Run PSScriptAnalyzer locally; address findings.
4. **Commit** with meaningful messages; open a **PR**:

   * Describe the change, risks, and any docs updates.
   * CI must pass (tests + analysis).
5. **Docs**:

   * If behavior/API surface changes, update `SPEC.md`.
   * If plan or priorities shift, update `PLAN.md`.
   * If standards evolve, propose edits to `AGENTS.md` in the PR.

---

## Versioning & releases

* Use **SemVer-ish** progression during 0.x (breaking changes may occur; document them).
* **CI (ci.yml)**:

  * Runs on PRs and pushes.
  * Matrix tests on PowerShell **7.2** (and optionally 5.1/other supported PS versions).
  * Executes Pester and PSScriptAnalyzer.
* **Release (release.yml)**:

  * Triggered by tag or GitHub Release.
  * Packages `src/Port.Api` as a distributable artifact (zip or nupkg as applicable).
  * Attaches artifacts to the release.

> Publishing to PowerShell Gallery may be added later; for now, we publish **release artifacts** within the repository.

---

## Keeping docs in sync

* When you land a feature/fix that affects:

  * **Endpoints/flows** → update `SPEC.md`.
  * **Roadmap/sequence** → update `PLAN.md`.
  * **Standards/process** → propose changes to `AGENTS.md`.
* Treat doc updates as part of the **definition of done**. If it’s not documented, it’s not done.

---

## Communication & decisions

* Capture notable decisions (naming, parameter semantics, behavior changes) in PR descriptions and/or a short **CHANGELOG** entry in the release notes.
* Use GitHub Issues for design discussions; summarize conclusions in the relevant doc (`SPEC.md`, `PLAN.md`, or `AGENTS.md`).

---

**Target runtime:** PowerShell **7.2**
**CI/CD:** GitHub Actions (tests + packaging)
**First deliverables:** Auth helper + entity upsert + working CI

*Last updated: 2025-09-05 (Europe/London).*
