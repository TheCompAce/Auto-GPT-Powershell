# AutoGPT.ps1
Param(
    [string]$pause,
    [string]$seed,
    [int]$LoopCount,
    [bool]$Debug,
    [string]$StartingPrompt,
    [string]$SystemPrompt,
    [string]$StartPromptFilePath,
    [string]$SystemPromptFilePath,
    [string]$SessionFolder,
    [string]$SessionFile,
    [string]$LocalGPTPath,
    [string]$OnlineGPTPath,
    [bool]$UseOnlineGPT,
    [bool]$SendOnlyPromptToGPT,
    [string]$GPTPromptScheme,
    [bool]$UseOpenAIGPTAuth,
    [string]$LocalTextToImagePath,
    [string]$OnlineTextToImagePath,
    [bool]$UseOnlineTextToImage,
    [bool]$SendOnlyPromptToTextToImage,
    [string]$TextToImagePromptScheme,
    [bool]$UseOpenAIDalleAuth,
    [string]$OnlineAPIKey,
    [bool]$UseOpenAIDALLEAuthentication,
    [bool]$UseOpenAIGPTAuthentication
)

. .\module\main\Crypt.ps1
. .\module\main\General.ps1

# Check if settings.json exists, create it with default settings if it doesn't
if (Test-Path "settings.json") {
    $settings = ConvertFrom-Json (Get-Content -Path "settings.json" -Raw)
}

$settings = UpdateSettingsWithDefaults -Settings $settings

# Apply parameters
if ($pause) { $settings.pause = $pause }
if ($seed) { $settings.seed = $seed }
if ($LoopCount) { $settings.LoopCount = $LoopCount }
if ($Debug) { $settings.Debug = $Debug }

$checkOptions = Read-Host "Do you want to check options? (y)es/(n)o"
if ($checkOptions.ToLower() -eq 'y') {
    . .\module\main\Options.ps1 -Settings $Settings
    # Reload settings
    $Settings = Get-Content -Path "settings.json" | ConvertFrom-Json
}


# . .\modules\main\VectorDB_PS\VectorDB.ps1
# Remove existing log files
Remove-Item -Path "session.txt" -ErrorAction Ignore
Remove-Item -Path "system.log" -ErrorAction Ignore

. .\module\main\RunChatGPTAPI.ps1
. .\module\main\RunGPT4Exe.ps1
. .\module\main\RunDallEAPI.ps1

# Set initial prompt
$prompt = Read-Host "Enter the starting prompt"


if ($Settings.UseOnlineGPT -and -not $Settings.SendOnlyPromptToGPT) {
    $startSystem = Read-Host "Enter the start system"
}

# Create the "sessions" folder if it doesn't exist
$defaultSessionFolder = "sessions"
if (-not (Test-Path $defaultSessionFolder)) {
    New-Item -ItemType Directory -Path $defaultSessionFolder | Out-Null
}

if ([string]::IsNullOrEmpty($SessionFolder)) {
    $timeStamp = Get-Date -Format "yyyyMMddHHmmss"
    $global:sessionFolder = Join-Path $defaultSessionFolder "session_$timestamp"
}

if (-not (Test-Path $global:sessionFolder)) {
    New-Item -ItemType Directory -Path $global:sessionFolder | Out-Null
}
$global:taskComplete = $false

$timeStamp = Get-Date -Format "yyyyMMddHHmmss"
$SessionFile = Join-Path $global:SessionFolder "session_$($timestamp).txt"

Debug -debugText "Starting AutoGPT System"

Debug -debugText "Start Prompt: $($prompt)"
# Run start plugins
# . .\module\main\RunStartPlugins.ps1
$prompt = RunPluginsByType -pluginType 0 -prompt $prompt -response $response -system $startSystem

if ($global:taskComplete -eq $true) {
    exit
}
Debug -debugText "Start Prompt: $($prompt)"



$runCt = 0
$firestLoop = $true;
# Main loop

do {

    if ($Settings.UseOnlineGPT -and $Settings.OpenAiModel -ne "text-davinci-003") {

        $setStart = $startSystem
        Debug -debugText "System : $($startSystem)"
    
        # Run input plugins
        # . .\module\main\RunSystemPlugins.ps1
        $setStart = RunPluginsByType -pluginType 1 -prompt $prompt -response $response -system $setStart

        if ($global:taskComplete -eq $true) {
            exit
        }
    
        Debug -debugText "System: $($setStart)"
    }

    Debug -debugText "Prompt: $($prompt)"

    # Run input plugins
    # . .\module\main\RunInputPlugins.ps1
    $prompt = RunPluginsByType -pluginType 2 -prompt $prompt -response $response -system $setStart

    if ($global:taskComplete -eq $true) {
        exit
    }

    Debug -debugText "Prompt: $($prompt)"


    # Run GPT-4 executable or ChatGPT API
    Write-Host "Asking GPT the prompt: Ct $($runCt)" -ForegroundColor Green
    if ($Settings.UseOnlineGPT) {
        $response = Invoke-ChatGPTAPI -prompt $prompt -system $setStart
    } else {
        $response = Invoke-GPT4ALL -prompt $prompt -response $response -system $setStart
    }

    if ($global:taskComplete -eq $true) {
        exit
    }

    Write-Host "GPT Responded: Ct $($runCt)" -ForegroundColor Green

    Debug -debugText "Response: $($response)"

    # Run output plugins
    # . .\module\main\RunOutputPlugins.ps1
    $response = RunPluginsByType -pluginType 3 -prompt $prompt -response $response -system $setStart

    if ($global:taskComplete -eq $true) {
        exit
    }

    $prompt = $response

    Debug -debugText "Response: $($response)"

    & ClearTempFolder

    # Pause if selected
    if ($settings.pause.ToLower() -eq "y" -and -not $global:taskComplete) {
        $null = Read-Host "Press Enter to continue, or Ctrl+C to exit"
    }

    $runCt++
} while ($runCt -lt $settings.LoopCount -or $global:taskComplete)
