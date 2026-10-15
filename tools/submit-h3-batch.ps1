[CmdletBinding()]
param(
    [int]$Steps = 8,
    [int]$DurationSeconds = 5,
    [double]$Megapixels = 0.5,
    [string[]]$Looks = @()
)

$ErrorActionPreference = 'Stop'
$submitter = Join-Path $PSScriptRoot 'submit-h3-preview.ps1'
$defaultLooks = @(
    '01','02','03','04','05','06','07','08','09',
    'classic-20','classic-24',
    'sit-01','sit-02','sit-04','sit-05','sit-06','sit-07','sit-12','sit-13','sit-14','sit-16',
    'recline-01','recline-02','recline-03','recline-04','recline-05','recline-06','recline-07'
)
if ($Looks.Count -eq 0) { $Looks = $defaultLooks }

$jobs = foreach ($i in 0..($Looks.Count - 1)) {
    $id = $Looks[$i]
    $raw = & $submitter `
        -CharacterImage 'Wallpaper/roland-identity-clean.png' `
        -CharacterSheetImage '' `
        -LookImage "Wallpaper/reference-look-$id-headless.jpg" `
        -LookId $id `
        -Seed (381065053500 + $i) `
        -Steps $Steps `
        -DurationSeconds $DurationSeconds `
        -Megapixels $Megapixels `
        -FilenamePrefix "Wallpaper/final/look-$id" `
        -OutputFormat 'video/webm'
    $response = $raw | ConvertFrom-Json
    [pscustomobject]@{ look = $id; prompt_id = $response.prompt_id; queue_number = $response.number }
}

$jobs | ConvertTo-Json
