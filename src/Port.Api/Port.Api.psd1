@{
    # Root module (psm1) that imports all functions
    RootModule        = 'Port.Api.psm1'

    # Semantic version
    ModuleVersion     = '0.1.1'

    # Unique module GUID
    GUID              = '6a7d8a1f-8e1d-4a0a-9b0b-8c6c3f2e3a44'

    Author            = 'Your Name or Org'
    CompanyName       = 'Your Org'
    Copyright         = '(c) 2025 Your Org. All rights reserved.'
    Description       = 'PowerShell module for interacting with the Port API (auth + entity upsert).'

    PowerShellVersion = '7.2'
    CompatiblePSEditions = @('Core')

    # Functions are exported via Export-ModuleMember in the psm1
    FunctionsToExport = @('*')
    AliasesToExport   = @()
    VariablesToExport = @()
    CmdletsToExport   = @()

    PrivateData = @{ 
        PSData = @{ 
            Tags = @('Port','API','Entities','Authentication')
            ProjectUri = 'https://example.com/your-repo'
            LicenseUri = ''
            IconUri    = ''
            ReleaseNotes = 'v0.1.1: Added Pester tests (auth, upsert, token refresh); fixed URI construction; CI enforces PS 7.2.'
            Prerelease = 'alpha'
        }
    }
}
