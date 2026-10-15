[CmdletBinding()]
param(
    [string]$CharacterImage = 'Wallpaper/roland-character-sheet.png',
    [string]$LookImage = 'Wallpaper/reference-look-04.jpg',
    [string]$LookId = '04',
    [long]$Seed = 381065053504,
    [int]$Width = 1344,
    [int]$Height = 768
)

$ErrorActionPreference = 'Stop'
$api = 'http://127.0.0.1:8188/prompt'

$promptText = @'
Create a new cinematic desktop wallpaper. Image 1 is the only identity reference: preserve the same adult character Roland, age 22, short layered black hair with distinctive pale silver-white nape streaks, delicate oval face, dark almond eyes, slim build, and natural realistic facial proportions. Image 2 is the outfit, pose, framing, and environment reference: reproduce its clothing design, colors, fabric layers, accessories, footwear, body pose, camera angle, and dark elegant interior composition as faithfully as possible, but replace the person completely with Roland from Image 1. Adult character. Full body placed on the right side, generous clean dark negative space on the left for desktop icons, 16:9 composition, refined cinematic realism, soft warm practical lighting, highly detailed fabric, anatomically correct hands, no text, no logo, no watermark.
'@

$workflow = [ordered]@{
    '1' = @{ class_type = 'LoadImage'; inputs = @{ image = $CharacterImage } }
    '2' = @{ class_type = 'LoadImage'; inputs = @{ image = $LookImage } }
    '13' = @{ class_type = 'ImageScale'; inputs = @{ image = @('1', 0); upscale_method = 'lanczos'; width = 1024; height = 1024; crop = 'center' } }
    '14' = @{ class_type = 'ImageScale'; inputs = @{ image = @('2', 0); upscale_method = 'lanczos'; width = $Width; height = $Height; crop = 'center' } }
    '3' = @{ class_type = 'UNETLoader'; inputs = @{ unet_name = 'z_image_turbo_int8_convrot.safetensors'; weight_dtype = 'default' } }
    '4' = @{ class_type = 'ModelSamplingAuraFlow'; inputs = @{ model = @('3', 0); shift = 3.0 } }
    '5' = @{ class_type = 'CLIPLoader'; inputs = @{ clip_name = 'qwen_3_4b.safetensors'; type = 'lumina2'; device = 'default' } }
    '6' = @{ class_type = 'VAELoader'; inputs = @{ vae_name = 'ae.safetensors' } }
    '7' = @{ class_type = 'TextEncodeZImageOmni'; inputs = @{
        clip = @('5', 0)
        prompt = $promptText
        auto_resize_images = $false
        vae = @('6', 0)
        image1 = @('13', 0)
        image2 = @('14', 0)
    } }
    '8' = @{ class_type = 'ConditioningZeroOut'; inputs = @{ conditioning = @('7', 0) } }
    '9' = @{ class_type = 'EmptySD3LatentImage'; inputs = @{ width = $Width; height = $Height; batch_size = 1 } }
    '10' = @{ class_type = 'KSampler'; inputs = @{
        model = @('4', 0)
        seed = $Seed
        steps = 12
        cfg = 1.0
        sampler_name = 'res_multistep'
        scheduler = 'simple'
        positive = @('7', 0)
        negative = @('8', 0)
        latent_image = @('9', 0)
        denoise = 1.0
    } }
    '11' = @{ class_type = 'VAEDecode'; inputs = @{ samples = @('10', 0); vae = @('6', 0) } }
    '12' = @{ class_type = 'SaveImage'; inputs = @{ images = @('11', 0); filename_prefix = "Wallpaper/look-$LookId-local-preview" } }
}

$body = @{
    client_id = [guid]::NewGuid().ToString()
    prompt = $workflow
}

$json = $body | ConvertTo-Json -Depth 30 -Compress
$result = Invoke-RestMethod -Method Post -Uri $api -ContentType 'application/json' -Body $json
$result | ConvertTo-Json -Depth 5
