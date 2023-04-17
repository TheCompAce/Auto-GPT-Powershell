Param(
    [string]$prompt,
    [string]$response
)

if ($Settings.Debug) {
    Write-Host "Debug: 1_SessionLog_Output_Format.ps1 used."
}

# This file takes in the "Prompt" and "Response" and returns the "Response" without changing it.
# It also appends the "Prompt" and "Response" to a "session.txt" file.
Add-Content -Path "session.txt" -Value "Prompt: $prompt`nResponse: $response"

# This file takes in the "Prompt" and returns it without changing it.
return $response