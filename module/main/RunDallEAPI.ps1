function Invoke-DallEAPI {
    param(
        [string]$prompt
    )

    if ($settings.UseOpenAIDALLEAuthentication) {
        $openAIDalleDecyData = Decrypt-String-Auto -InputString $settings.OnlineAPIKey
        $headers = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $($openAIDalleDecyData)"
        }
    } else {
        $headers = @{
            "Content-Type"  = "application/json"
        }
    }

    if ($settings.UseOnlineTextToImage) {
        $uri = $settings.OnlineTextToImagePath
    } else {
        Write-Host "Please set the OnlineTextToImagePath in the settings." -ForegroundColor Red
        return
    }

    $body = PrepareRequestBody -scheme $settings.TextToImagePromptScheme -system $system -user $prompt -seed $settings.seed

    try {
        $dalleResponse = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $headers -Body $body
        if ($dalleResponse -ne $null) {
            return $dalleResponse
        } else {
            Write-Host "Invoke-DallEAPI Error: Dall-E API response is empty." -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "Invoke-DallEAPI Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Save-DalleImages {
    param(
        [string]$prompt,
        $dalleResponse,
        [string]$overrideSavePath = $null,
        [string]$optionsFilename = $null
    )

    if ($null -eq $overrideSavePath -or [string]::IsNullOrEmpty($overrideSavePath)) {
        if ($null -eq $global:SessionFolder -or [string]::IsNullOrEmpty($global:SessionFolder)) {
            $ttiFolderPath = Join-Path -Path (Get-Location).Path -ChildPath "TTI"
        } else {
            $ttiFolderPath = Join-Path -Path $global:SessionFolder -ChildPath "TTI"
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

    # You may need to modify the following code depending on the actual Dall-E API response format.
    $imageUrls = $dalleResponse.data
    $count = 1

    foreach ($imageUrl in $imageUrls) {
        if ([string]::IsNullOrEmpty($optionsFilename)) {
            $imageFileName = "image_$count.png"
        } else {
            $imageFileName = $optionsFilename
        }
        $uniqueFilename = Get-UniqueFilename -filename  $imageFileName -folder $imageFolderPath

        $imagePath = $uniqueFilename 

        Invoke-WebRequest -Uri $imageUrl.url -OutFile $imagePath | Out-Null
        Write-Host "$($imagePath) has been saved." -ForegroundColor Green

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
            "Filename" = $imageFileName
        }

        $updatedPromptsData = @{
            "images" = $promptsData
        }

        $updatedPromptsData | ConvertTo-Json | Set-Content -Path $promptsPath

        $count++
    }

        # Copy gallery.htm to TTI folder if it doesn't exist
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
