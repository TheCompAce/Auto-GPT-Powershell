# AutoGPT.ps1
Param(
    [string]$model,
    [string]$pause,
    [string]$seed,
    [bool]$UseChatGPT,
    [string]$OpenAIKey,
    [string]$OpenAiModel,
    [int]$LoopCount,
    [bool]$Debug,
    [string]$StartingPrompt,
    [string]$SystemPrompt,
    [string]$StartPromptFilePath,
    [string]$SystemPromptFilePath,
    [bool]$AllowPluginGPTs,
    [string]$SessionFolder,
    [string]$SessionFile
)

. .\module\General.ps1

# Check if settings.json exists, create it with default settings if it doesn't
if (-not (Test-Path "settings.json")) {
    @{
        model = "gpt4all-lora-quantized.bin"
        pause = "y"
        seed = ""
        LoopCount = "10"
        UseChatGPT = $false
        OpenAIKey = ""
        OpenAiModel = "gpt-3.5-turbo"
        Debug = $false
        AllowPluginGPTs = $false
    } | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
}

# Load settings from the settings file
$settings = ConvertFrom-Json (Get-Content -Path "settings.json" -Raw)

# Apply parameters
if ($model) { $settings.model = $model }
if ($pause) { $settings.pause = $pause }
if ($seed) { $settings.seed = $seed }
if ($UseChatGPT) { $settings.UseChatGPT = $UseChatGPT }
if ($OpenAIKey) { $settings.OpenAIKey = $OpenAIKey }
if ($OpenAiModel) { $settings.OpenAiModel = $OpenAiModel }
if ($LoopCount) { $settings.LoopCount = $LoopCount }
if ($Debug) { $settings.Debug = $Debug }

# Ask user if they want to check options, only if no options were passed as parameters
if (-not ($model -or $pause -or $seed -or $UseChatGPT -or $OpenAIKey -or $OpenAiModel -or $LoopCount -or $Debug)) {
    $checkOptions = Read-Host "Do you want to check options? (y)es/(n)o"
    if ($checkOptions.ToLower() -eq 'y') {
        . .\module\Options.ps1 -Settings $Settings
        # Reload settings
        $Settings = Get-Content -Path "settings.json" | ConvertFrom-Json
    }
}


# . .\modules\VectorDB_PS\VectorDB.ps1
# Remove existing log files
Remove-Item -Path "session.txt" -ErrorAction Ignore
Remove-Item -Path "system.log" -ErrorAction Ignore

# Set initial prompt
if (-not $StartingPrompt -and (-not $StartPromptFilePath) -and (($Settings.UseChatGPT -and ($Settings.OpenAiModel -eq "gpt-3.5-turbo" -or $Settings.OpenAiModel -eq "gpt-4")))) {
    $prompt = Read-Host "Enter the starting prompt"
} elseif ($StartPromptFilePath) {
    $prompt = Get-Content -Path $StartPromptFilePath -Raw
} else {
    $prompt = $StartingPrompt
}

Debug -debugText "Start Prompt: $($prompt)"

if ($Settings.UseChatGPT -and ($Settings.OpenAiModel -eq "gpt-3.5-turbo" -or $Settings.OpenAiModel -eq "gpt-4")) {
    if (-not $SystemPrompt -and (-not $SystemPromptFilePath)) {
        $startSystem = Read-Host "Enter the start system"
    } elseif ($SystemPromptFilePath) {
        $startSystem = Get-Content -Path $SystemPromptFilePath -Raw
    } else {
        $startSystem = $SystemPrompt
    }
}

# Create the "sessions" folder if it doesn't exist
$defaultSessionFolder = "sessions"
if (-not (Test-Path $defaultSessionFolder)) {
    New-Item -ItemType Directory -Path $defaultSessionFolder
}

if ([string]::IsNullOrEmpty($SessionFolder)) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $sessionFolder = Join-Path $defaultSessionFolder "session_$timestamp"
}

if (-not (Test-Path $sessionFolder)) {
    New-Item -ItemType Directory -Path $sessionFolder
}

if ([string]::IsNullOrEmpty($SessionFile)) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $SessionFile = Join-Path $SessionFolder "session_$($timestamp).txt"
}

Debug -debugText "Starting AutoGPT System"



# Run start plugins
. .\module\RunStartPlugins.ps1


$runCt = 0
# Main loop
do {

    if ($Settings.UseChatGPT -and $Settings.OpenAiModel -ne "text-davinci-003") {

        Debug -debugText "System : $($startSystem)"
    
        # Run input plugins
        . .\module\RunSystemPlugins.ps1
    
        Debug -debugText "System: $($startSystem)"
    }

    Debug -debugText "Prompt: $($prompt)"

    # Run input plugins
    . .\module\RunInputPlugins.ps1

    Debug -debugText "Prompt: $($prompt)"

    # Run GPT-4 executable or ChatGPT API
    if ($Settings.UseChatGPT) {
        . .\module\RunChatGPTAPI.ps1
        $response = Invoke-ChatGPTAPI -apiKey $Settings.OpenAIKey -prompt $prompt -startSystem $startSystem

    } else {
        . .\module\RunGPT4Exe.ps1
    }

    Debug -debugText "Response: $($response)"

    # Run output plugins
    . .\module\RunOutputPlugins.ps1

    $prompt = $response

    Debug -debugText "Response: $($response)"

    # Pause if selected
    if ($settings.pause.ToLower() -eq "y") {
        $null = Read-Host "Press Enter to continue, or Ctrl+C to exit"
    }

    $runCt++
} while ($true -and $runCt -lt $settings.LoopCount)
