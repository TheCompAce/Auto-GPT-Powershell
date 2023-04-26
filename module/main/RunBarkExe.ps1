function Invoke-Bark {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system,
        [string]$filename,
        [int]$voice,
        [string]$overrideSavePath = $null,
        [string]$optionsFilename = $null
    )

    $escapedPrompt = "`"" + ($prompt -replace '"', '\"') + "`""
    $exeStr = PrepareRequestBody -scheme $Settings.SpeechPath -system $system -user $prompt
    $outPath = $filename
    $exeStr = $exeStr.Replace("[file]", $outPath)
    $exeStr = $exeStr.Replace("[voice]", "en_speaker_$($voice)")

    # Execute the command and save the output to a variable
    $output = Invoke-Expression $exeStr

    Write-Host "$($outPath) has been saved." -ForegroundColor Green
    
    # Call the Write-Log function to log the output
    Write-Log -logText "Execution Output: $output"

    return $response
}


