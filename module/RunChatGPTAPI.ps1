# RunChatGPTAPI.ps1

function Invoke-ChatGPTAPI {
    param(
        [string]$apiKey,
        [string]$model,
        [string]$prompt,
        [string]$startSystem
    )
    
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $($apiKey)"
    }

    if ($model -eq "text-davinci-003") {
        $uri = "https://api.openai.com/v1/completions"
        $body = @{
            "model" = "text-davinci-003"
            "prompt"   = $prompt
            "max_tokens" = 50
            "n"        = 1
            "stop"     = "\n"
            "temperature" = 0.7
        } | ConvertTo-Json
    } else {
        $uri = "https://api.openai.com/v1/chat/completions"
        $messages = @(
            @{
                "role" = "system"
                "content" = $startSystem
            },
            @{
                "role" = "user"
                "content" = $prompt
            }
        )

        $body = @{
            "model" = $model
            "messages" = $messages
        } | ConvertTo-Json -Depth 10
    }
    try {
        $oaResponse = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $headers -Body $body
        if ($model -eq "text-davinci-003") {
            return $oaResponse.choices[0].text
        } else {
            return $oaResponse.choices[0].message.content;
        }
    }
    catch {
        Write-Host "Error: $($oaResponse)"
        Write-Host "Error: $($_.Exception.Message)"
        return ""
    }
}
