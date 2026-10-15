[CmdletBinding()]
param(
    [string]$Repository = 'Cakesise/Wallpaper',
    [string]$Branch = 'main',
    [string]$Message = 'Publish Roland interactive wallpaper source'
)

$ErrorActionPreference = 'Stop'

function Invoke-GhJson {
    param([string]$Endpoint, [string]$Method = 'GET', $Body = $null)
    if ($null -eq $Body) {
        $raw = & gh api $Endpoint --method $Method
    } else {
        $json = $Body | ConvertTo-Json -Depth 20 -Compress
        $raw = $json | & gh api $Endpoint --method $Method --input -
    }
    if ($LASTEXITCODE -ne 0) { throw "GitHub API failed: $Method $Endpoint" }
    $raw | ConvertFrom-Json
}

$ref = Invoke-GhJson "repos/$Repository/git/ref/heads/$Branch"
$parentSha = $ref.object.sha
$parent = Invoke-GhJson "repos/$Repository/git/commits/$parentSha"
$entries = @()

foreach ($relative in (& git ls-files)) {
    $absolute = Join-Path (Get-Location) $relative
    $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($absolute))
    $blob = Invoke-GhJson "repos/$Repository/git/blobs" 'POST' @{ content = $content; encoding = 'base64' }
    $entries += @{ path = $relative.Replace('\', '/'); mode = '100644'; type = 'blob'; sha = $blob.sha }
}

$tree = Invoke-GhJson "repos/$Repository/git/trees" 'POST' @{ base_tree = $parent.tree.sha; tree = $entries }
$commit = Invoke-GhJson "repos/$Repository/git/commits" 'POST' @{ message = $Message; tree = $tree.sha; parents = @($parentSha) }
$updated = Invoke-GhJson "repos/$Repository/git/refs/heads/$Branch" 'PATCH' @{ sha = $commit.sha; force = $false }

[pscustomobject]@{ repository = $Repository; branch = $Branch; commit = $updated.object.sha }
