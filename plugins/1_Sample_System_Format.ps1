Param(
    [string]$system
)

if ($Settings.Debug) {
    Write-Host "Debug: 1_Sample_System_Format.ps1 used."
} 


# This file takes in the "Prompt" and returns it without changing it.
return $system