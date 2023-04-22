function Invoke-StableDiff {
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
