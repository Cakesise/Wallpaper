[CmdletBinding()]
param(
    [string]$CharacterImage = 'Wallpaper/roland-character-sheet.png',
    [string]$CharacterSheetImage = '',
    [string]$LookImage = 'Wallpaper/reference-look-04.jpg',
    [string]$LookId = '04',
    [long]$Seed = 381065053504,
    [int]$Steps = 4,
    [int]$DurationSeconds = 2,
    [double]$Megapixels = 0.2,
    [string]$FilenamePrefix = '',
    [ValidateSet('video/h264-mp4','video/webm')]
    [string]$OutputFormat = 'video/h264-mp4'
)

$ErrorActionPreference = 'Stop'
$api = 'http://127.0.0.1:8188/prompt'

$promptText = @'
integrated_multimodal_description:
[Reference 1] is the only character identity guide. Preserve Roland as the same fictional adult age 22: delicate oval face, dark almond eyes, short layered black hair, and the distinctive pale silver-white hair streaks only at the nape.
[Reference 2], when supplied, is a second identity guide showing Roland's exact short layered haircut, slim proportions, and pale silver-white nape streaks. Never borrow clothing from this identity guide.
[Reference 3] is the strict costume, pose, staging, camera, and environment guide. Its head region was deliberately blanked to remove the old identity. You must completely fill that blank region with Roland's natural head, face, ears, neck, short hair, and silver-white nape streaks from Reference 1. Replace its person with Roland while keeping every garment layer, color, bow, accessory, hosiery, shoe, pose, furniture, lighting, and right-side placement faithful to Reference 3.
[Shot 1] A locked-off 16:9 desktop-wallpaper composition. Roland remains full-body on the right, leaving generous clean dark negative space on the left for desktop icons. She makes only subtle natural motions: breathing, one blink, a tiny shift of gaze, slight hair and fabric movement. Camera must not pan, zoom, crop, or cut.
overall_soundscape:
Very quiet indoor room tone with faint fabric rustle. No speech.
non_diegetic_music:
None.
constraints:
One adult only. Exact identity and short black haircut with conspicuous silver-white nape streaks from the identity references. Exact outfit and pose from Reference 3. The final frame must contain a complete, naturally integrated head and neck; never leave a black void over the head. Reference images are conditioning only and must never appear as a character sheet, inset picture, poster, screen, wallpaper, collage, or miniature person. Do not give her long hair or blunt bangs. No duplicate person, no split screen, no mosaic, no pixel squares, no desktop icons, no taskbar, no dock, no screenshot UI, no costume redesign, no text, no logo, no watermark, no camera movement.
'@

$integrationInputs = @{
    main_mode = 'all_reference'
    clip_name = 'qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors'
    video_vae_name = 'minimax_h3_video_vae_fp16.safetensors'
    audio_vae_name = 'minimax_h3_audio_vae_fp32.safetensors'
    aspect = '16:9'
    megapixels = $Megapixels
    duration_seconds = $DurationSeconds
    prompt = $promptText
    task_type = 'ref2va'
    audio_mode = 'native'
    audio_denoise_strength = 0.0
    drive_audio_ordinal = 1
    strict_prompt_tags = $true
    ref_image_size = 'match'
    ref_image_1 = $CharacterImage
    ref_image_2 = $CharacterSheetImage
    ref_image_3 = $LookImage
    first_frame = ''
    last_frame = ''
    hybrid_audio = ''
    ref_image_4 = ''
    ref_image_5 = ''
    ref_image_6 = ''
    ref_image_7 = ''
    ref_image_8 = ''
    ref_image_9 = ''
    ref_video_1 = ''
    ref_video_2 = ''
    ref_video_3 = ''
    ref_audio_1 = ''
    ref_audio_2 = ''
    ref_audio_3 = ''
}

$workflow = [ordered]@{
    '1' = @{ class_type = 'UNETLoader'; inputs = @{ unet_name = 'minimax_h3_ref2va_pruned_int8_convrot.safetensors'; weight_dtype = 'default' } }
    '2' = @{ class_type = 'MiniMaxH3MemoryEfficientSageAttentionPatch'; inputs = @{ model = @('1', 0) } }
    '3' = @{ class_type = 'MiniMaxH3IntegrationGH'; inputs = $integrationInputs }
    '4' = @{ class_type = 'MiniMaxH3IntegrationAdapterGH'; inputs = @{ integration = @('3', 0) } }
    '5' = @{ class_type = 'MiniMaxH3DualClockT8GH'; inputs = @{
        model = @('2', 0)
        av_latent = @('4', 1)
        steps = $Steps
        shift_video = 12.0
        shift_audio = 3.0
        sampler_name = 'dual_clock_euler'
        scheduler = 'native_flow'
    } }
    '6' = @{ class_type = 'BasicGuider'; inputs = @{ model = @('5', 0); conditioning = @('4', 0) } }
    '7' = @{ class_type = 'RandomNoise'; inputs = @{ noise_seed = $Seed } }
    '8' = @{ class_type = 'SamplerCustomAdvanced'; inputs = @{
        noise = @('7', 0)
        guider = @('6', 0)
        sampler = @('5', 1)
        sigmas = @('5', 2)
        latent_image = @('4', 1)
    } }
    '9' = @{ class_type = 'MiniMaxH3AVDecodeT8GH'; inputs = @{
        av_latent = @('8', 0)
        video_vae = @('4', 2)
        audio_vae = @('4', 3)
    } }
    '10' = @{ class_type = 'VHS_VideoCombine'; inputs = @{
        images = @('9', 0)
        audio = @('9', 1)
        frame_rate = 24
        loop_count = 0
        filename_prefix = $(if ($FilenamePrefix) { $FilenamePrefix } else { "Wallpaper/look-$LookId-h3-preview" })
        format = $OutputFormat
        pix_fmt = 'yuv420p'
        crf = 19
        save_metadata = $false
        trim_to_audio = $false
        pingpong = $false
        save_output = $true
    } }
}

$body = @{ client_id = [guid]::NewGuid().ToString(); prompt = $workflow }
$json = $body | ConvertTo-Json -Depth 40 -Compress
$result = Invoke-RestMethod -Method Post -Uri $api -ContentType 'application/json' -Body $json
$result | ConvertTo-Json -Depth 5
