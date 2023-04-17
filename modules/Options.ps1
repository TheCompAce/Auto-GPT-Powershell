# Options.ps1
Param(
    [Parameter(Mandatory=$true)][PSCustomObject]$Settings
)

function ShowOptions {
    Write-Host "1. Change Model ($($Settings.model))"
    Write-Host "2. Toggle Pause ($($Settings.pause))"
    Write-Host "3. Change Seed ($($Settings.seed))"
    Write-Host "4. Change Loop Count ($($Settings.LoopCt))"
    Write-Host "5. Toggle Use ChatGPT ($($Settings.UseChatGPT))"
    Write-Host "6. Set OpenAI Key ($($Settings.OpenAIKey))"
    Write-Host "7. OpenAI Models ($($Settings.OpenAiModel))"
    Write-Host "8. Turn On Debug ($($Settings.Debug))"
    Write-Host "9. Exit"
}

function ShowLocalModels {
    $models = Get-ChildItem -Path ".\" -Filter "*.bin"
    Write-Host "Available local models:"
    $models | ForEach-Object { Write-Host $_.Name }
}

$oaModels = @("text-davinci-003", "gpt-3.5-turbo", "gpt-4")

function ShowOpenAIModels {    
    Write-Host "Available OpenAI models:"
    for ($i = 0; $i -lt $oaModels.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $oaModels[$i])
    }
}

while ($true) {
    ShowOptions
    $option = Read-Host "Choose an option (1-9):"

    switch ($option) {
        1 {
            ShowLocalModels
            $Settings.model = Read-Host "Enter the model filename"
        }
        2 { $Settings.pause = if ($Settings.pause -eq 'y') { 'n' } else { 'y' } }
        3 { $Settings.seed = Read-Host "Enter the seed value (leave empty to use seed created on start, or '0' for random every time)" }
        4 { $Settings.LoopCt = Read-Host "Enter the Loop Count (leave empty for infinite)" }
        5 { $Settings.UseChatGPT = -not $Settings.UseChatGPT }
        6 { $Settings.OpenAIKey = Read-Host "Enter your OpenAI API Key" }
        7 {
            ShowOpenAIModels
            $modelIndex = Read-Host "Enter the number of the model you want to use (1-$(($oaModels.Count)))"
            $Settings.OpenAiModel = $oaModels[$modelIndex - 1]
        }
        8 { $Settings.Debug = -not $Settings.Debug }
        9 { return }
        default { Write-Host "Invalid option" }
    }

    # Save the updated settings
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
}
