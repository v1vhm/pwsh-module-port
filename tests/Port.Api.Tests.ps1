Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/../src/Port.Api/Port.Api.psd1" -Force

Describe 'Port.Api module scaffolding' {
    It 'exports expected public functions' {
        $cmds = Get-Command -Module 'Port.Api' | Select-Object -ExpandProperty Name
        $cmds | Should -Contain 'Set-PortConnection'
        $cmds | Should -Contain 'New-PortAccessToken'
        $cmds | Should -Contain 'Set-PortEntity'
    }

    It 'sets connection context' {
        $ctx = Set-PortConnection -ClientId 'x' -ClientSecret 'y' -BaseUri 'https://example.test'
        $ctx.ClientId | Should -Be 'x'
        $ctx.ClientSecret | Should -Be 'y'
        $ctx.BaseUri | Should -Be 'https://example.test'
    }
}

