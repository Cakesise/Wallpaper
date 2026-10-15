[CmdletBinding()]
param(
    [string[]]$Looks = @(),
    [string]$Model = 'RealESRGAN_x2plus.pth',
    [int]$FramesPerBatch = 4,
    [int]$Crf = 18
)

$ErrorActionPreference = 'Stop'
$api = 'http://127.0.0.1:8188/prompt'
$projectRoot = Split-Path $PSScriptRoot -Parent
$defaultLooks = @(
    '01','02','03','04','05','06','07','08','09',
    'classic-20','classic-24',
    'sit-01','sit-02','sit-04','sit-05','sit-06','sit-07','sit-12','sit-13','sit-14','sit-16',
    'recline-01','recline-02','recline-03','recline-04','recline-05','recline-06','recline-07'
)
if ($Looks.Count -eq 0) { $Looks = $defaultLooks }

$jobs = foreach ($id in $Looks) {
    $source = Join-Path $projectRoot "assets\media\look-$id.webm"
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Missing source video: $source"
    }

    $workflow = [ordered]@{
        '1' = @{ class_type = 'VHS_LoadVideoPath'; inputs = @{
            video = $source
            force_rate = 0
            custom_width = 0
            custom_height = 0
            frame_load_cap = 0
            skip_first_frames = 0
            select_every_nth = 1
        } }
        '2' = @{ class_type = 'UpscaleModelLoader'; inputs = @{
            model_name = $Model
        } }
        '3' = @{ class_type = 'ImageUpscaleWithModelBatched'; inputs = @{
            upscale_model = @('2', 0)
            images = @('1', 0)
            per_batch = $FramesPerBatch
            downscale_ratio = 1.0
            downscale_method = 'lanczos'
            precision = 'float16'
        } }
        '4' = @{ class_type = 'VHS_VideoCombine'; inputs = @{
            images = @('3', 0)
            frame_rate = 24
            loop_count = 0
            filename_prefix = "Wallpaper/upscaled/look-$id"
            format = 'video/webm'
            pix_fmt = 'yuv420p'
            crf = $Crf
            save_metadata = $false
            trim_to_audio = $false
            pingpong = $false
            save_output = $true
        } }
    }

    $body = @{ client_id = [guid]::NewGuid().ToString(); prompt = $workflow }
    $json = $body | ConvertTo-Json -Depth 30 -Compress
    $result = Invoke-RestMethod -Method Post -Uri $api -ContentType 'application/json' -Body $json
    [pscustomobject]@{ look = $id; prompt_id = $result.prompt_id; queue_number = $result.number }
}

$jobs | ConvertTo-Json
