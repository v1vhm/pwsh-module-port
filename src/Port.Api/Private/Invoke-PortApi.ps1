function Invoke-PortApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET','POST','PUT','PATCH','DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [string]$BaseUri
    )

    # Module-scoped context
    if (-not $BaseUri) { $BaseUri = $script:PortContext.BaseUri }
    if (-not $BaseUri) { throw 'BaseUri is not set. Use Set-PortConnection or pass -BaseUri.' }

    # Ensure token is available
    if (-not $script:PortContext.AccessToken -or (Get-Date) -ge $script:PortContext.TokenExpiry) {
        # Acquire a new token via public helper
        $null = New-PortAccessToken -ErrorAction Stop
    }

    # Build full request URI robustly (avoid ambiguous Uri ctor overloads)
    $uri = "$( $BaseUri.TrimEnd('/') )/$( $Path.TrimStart('/') )"

    $defaultHeaders = @{
        'Authorization' = "Bearer $($script:PortContext.AccessToken)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
    if ($Headers) {
        foreach ($k in $Headers.Keys) { $defaultHeaders[$k] = $Headers[$k] }
    }

    $irmParams = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $defaultHeaders
        ErrorAction = 'Stop'
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $irmParams['Body'] = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }

    try {
        Invoke-RestMethod @irmParams
    }
    catch {
        $response = $_.Exception.Response
        if ($response -and $response.ContentLength -gt 0) {
            try {
                $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                $content = $reader.ReadToEnd()
                throw "Port API error: $($response.StatusCode) - $content"
            } catch { throw $_ }
        }
        throw $_
    }
}
