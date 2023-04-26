# RunChatGPTAPI.ps1

function Invoke-ChatGPTAPI {
    param(
        [string]$prompt,
        [string]$system
    )

    if ($settings.UseOpenAIGPTAuthentication) {
        $openAIDencyData = Decrypt-String-Auto -InputString $settings.OnlineAPIKey
        
        $headers = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $($openAIDencyData)"
        }
    } else {
        $headers = @{
            "Content-Type"  = "application/json"
        }
    }

    $uri = $Settings.GPTPath

    $body = PrepareRequestBody -scheme $settings.GPTPromptScheme -system $system -user $prompt -seed $settings.seed

    try {
        $oaResponse = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $headers -Body $body
        if ($oaResponse.choices -ne $null) {
            # Change to check for nulls and end on just returning the whole $oaResponse
            if ($oaResponse.choices.Count -gt 0) {
                if ($oaResponse.choices[0] -ne $null) {
                    if ($oaResponse.choices[0].text -ne $null) {
                        return $oaResponse.choices[0].text
                    } elseif ($oaResponse.choices[0].message -ne $null) {
                        return $oaResponse.choices[0].message.content;
                    } else {
                        return $oaResponse.choices[0]
                    }
                } else {
                    Write-Host "Invoke-ChatGPTAPI Error: Choices[0] on found." -ForegroundColor Red
                }
            } else {
                Write-Host "Invoke-ChatGPTAPI Error: Choices are empty." -ForegroundColor Red
            }
        } else {
            Write-Host "Invoke-ChatGPTAPI Error: Choices not found." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Invoke-ChatGPTAPI Error: $($_.Exception.Message)" -ForegroundColor Red
        return ""
    }
}
