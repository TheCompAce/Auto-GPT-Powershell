Add-Type -TypeDefinition @"
    public class PngChunkText {
        public string Key;
        public string Value;
        public PngChunkText(string key, string value) {
            Key = key;
            Value = value;
        }
    }
"@

function Invoke-StableDiff {
    param(
        [string]$prompt,
        [string]$filename = "output.png",
        [string] $pngUri = "http://127.0.0.1:7860/sdapi/v1/png-info",
        [int]$steps = 50,
        $enable_hr = $false,
        [int]$denoising_strength = 0,
        [int]$firstphase_width = 0,
        [int]$firstphase_height = 0,
        [int]$hr_scale = 2,
        [string]$hr_upscaler = "",
        [int]$hr_second_pass_steps = 0,
        [int]$hr_resize_x = 0,
        [int]$hr_resize_y = 0,
        [string[]]$styles = "",
        [int]$seed = -1,
        [int]$subseed = -1,
        [float]$subseed_strength = 0,
        [int]$seed_resize_from_h = -1,
        [int]$seed_resize_from_w = -1,
        [string]$sampler_name = "",
        [int]$batch_size = 1,
        [int]$n_iter = 1,
        [int]$cfg_scale = 7,
        [int]$width = 512,
        [int]$height = 512,
        $restore_faces = $false,
        $tiling = $false,
        [string]$negative_prompt = "",
        [float]$eta = 0,
        [float]$s_churn = 0,
        [float]$s_tmax = 0,
        [float]$s_tmin = 0,
        [float]$s_noise = 1,
        [string]$override_settings = "",
        $override_settings_restore_afterwards = $true,
        [string[]]$script_args = @(),
        [string]$sampler_index = 0,
        [string]$script_name = "",
        [string]$overrideSavePath = $null,
        [string]$optionsFilename = $null
    )

    if ($null -eq $overrideSavePath -or [string]::IsNullOrEmpty($overrideSavePath)) {
        if ($null -eq $global:SessionFolder -or [string]::IsNullOrEmpty($global:SessionFolder)) {
            $ttiFolderPath = Join-Path -Path (Get-Location).Path -ChildPath "TTI"
        } else {
            $ttiFolderPath = Join-Path -Path (Get-Location).Path -ChildPath $global:SessionFolder
            $ttiFolderPath = Join-Path -Path $ttiFolderPath -ChildPath "TTI"
        }
    } else {
        $ttiFolderPath = $overrideSavePath
    }

    if (!(Test-Path -Path $ttiFolderPath)) {
        New-Item -ItemType Directory -Path $ttiFolderPath | Out-Null
    }



    $timeStamp = Get-Date -Format "yyyyMMddHHmmss"
    $imageFolderPath = Join-Path -Path $ttiFolderPath -ChildPath "img_$timeStamp"
    New-Item -ItemType Directory -Path $imageFolderPath | Out-Null

    $payload = @{
        "prompt"                                = $prompt
        "steps"                                 = $steps
        "enable_hr"                             = $enable_hr
        "denoising_strength"                    = $denoising_strength
        "firstphase_width"                      = $firstphase_width
        "firstphase_height"                     = $firstphase_height
        "hr_scale"                              = $hr_scale
        "hr_second_pass_steps"                  = $hr_second_pass_steps
        "hr_resize_x"                           = $hr_resize_x
        "hr_resize_y"                           = $hr_resize_y
        "styles"                                = $styles
        "seed"                                  = $seed
        "subseed"                               = $subseed
        "subseed_strength"                      = $subseed_strength
        "seed_resize_from_h"                    = $seed_resize_from_h
        "seed_resize_from_w"                    = $seed_resize_from_w
        "sampler_name"                          = $sampler_name
        "batch_size"                            = $batch_size
        "n_iter"                                = $n_iter
        "cfg_scale"                             = $cfg_scale
        "width"                                 = $width
        "height"                                = $height
        "restore_faces"                         = $restore_faces
        "tiling"                                = $tiling
        "negative_prompt"                       = $negative_prompt
        "eta"                                   = $eta
        "s_churn"                               = $s_churn
        "s_tmax"                                = $s_tmax
        "s_tmin"                                = $s_tmin
        "s_noise"                               = $s_noise
        "override_settings_restore_afterwards"  = $override_settings_restore_afterwards
        "sampler_index"                         = $sampler_index
    }

    if ($script_name -ne "") {
        $payload["script_name"] = $script_name
    }

    if ($override_settings -ne "") {
        $payload["override_settings"] = $override_settings
    }

    if ($script_args.Count -gt 0) {
        $payload["script_args"] = $script_args
    }

    if ($hr_upscaler -ne "") {
        $payload["hr_upscaler"] = $hr_upscaler
    }

    if ($settings.UseStableDiffTextToImage) {
        $response = Invoke-WebRequest -Uri $Settings.TextToImagePath -Method POST -ContentType "application/json" -Body (ConvertTo-Json -InputObject $payload)
    } else {
        Write-Host "Please set the UseStableDiffTextToImage in the settings." -ForegroundColor Red
        return
    }

    $r = $response | ConvertFrom-Json

    foreach ($i in $r.images) {
        $imageBytes = [Convert]::FromBase64String($i)
        $ms = New-Object System.IO.MemoryStream -ArgumentList @(,$imageBytes)
        $image = [System.Drawing.Image]::FromStream($ms)

        $imageFileName = Join-Path $imageFolderPath $filename
        # Save the image as PNG without adding any extra data
        $image.Save($imageFileName, [System.Drawing.Imaging.ImageFormat]::Png)

        # Dispose the image
        $image.Dispose()

        Write-Host "$($imageFileName) has been saved." -ForegroundColor Green

        $promptsPath = Join-Path -Path $ttiFolderPath -ChildPath "prompts.json"
        if (Test-Path -Path $promptsPath) {
            $jsonData = Get-Content -Path $promptsPath | ConvertFrom-Json
            if ($jsonData.images -is [array]) {
                $promptsData = $jsonData.images
            } else {
                $promptsData = @($jsonData.images)
            }
        } else {
            $promptsData = @()
        }

        $promptsData += @{
            "Prompt"  = $prompt
            "Folder"  = "img_$timeStamp"
            "Filename" = $filename
        }

        $updatedPromptsData = @{
            "images" = $promptsData
        }

        $updatedPromptsData | ConvertTo-Json | Set-Content -Path $promptsPath
    }

    $galleryFilePath = Join-Path -Path $ttiFolderPath -ChildPath "gallery.htm"
    
    $sourceGalleryFilePath = Join-Path -Path (Get-Location).Path -ChildPath "resources\DallE_Prompts\gallery.htm"
    Copy-Item -Path $sourceGalleryFilePath -Destination $galleryFilePath
    
    # Insert prompts.json data into gallery.htm
    $galleryContent = Get-Content -Path $galleryFilePath -Raw
    $jsonDataContent = Get-Content -Path $promptsPath -Raw
    $jsonDataContent = "var jsonData = $($jsonDataContent);"
    
    $galleryContent = $galleryContent -replace '// Paste the content of prompts.json here', $jsonDataContent
    Set-Content -Path $galleryFilePath -Value $galleryContent
}
