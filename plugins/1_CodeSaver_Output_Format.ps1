Param(
    [string]$prompt,
    [string]$response
)

if ($Settings.Debug) {
    Write-Host "Debug: 1_CodeSaver_Output_Format.ps1 used."
}

function SaveCodeToFile {
    param (
        [string]$filename,
        [string]$content
    )

    Set-Content -Path $filename -Value $content
}

$codePattern = "(?s)(?<=```).*?(?=```)"

$codeMatches = [regex]::Matches($response, $codePattern)

foreach ($match in $codeMatches) {
    $code = $match.Value
    if ($code) {
        if ($Settings.Debug) {
            Write-Host "Debug: Code Found $($code)"
        }

        if ($Settings.UseChatGPT -and $Settings.AllowPluginGPTs) {
            if ($Settings.OpenAiModel -eq "gpt-3.5-turbo" -or $Settings.OpenAiModel -eq "gpt-4") {
                $usePrompt = $response
                $useSystem = "Return ONLY the JSON { 'filename': [filename] } Where [filename] is the file name for the code. (If you can not find the filename then make one up based on the code and type.)"
                $filenameJson = Invoke-ChatGPTAPI -apiKey $Settings.OpenAIKey -prompt $usePrompt -startSystem $useSystem
                
                try {
                    $jsonObject = $filenameJson | ConvertFrom-Json
                    $filename = $jsonObject.filename
                } catch {
                    Write-Host "Error: Failed to parse JSON for filename. Using Response: $($response) and System: $($useSystem)"
                    $filename = $null
                }
                
            } else {
                $usePrompt = "$($response) Return ONLY the JSON { 'filename': [filename] } Where [filename] is the file name for the code. (If you can not find the filename then make one up based on the code and type.)"
                $filenameJson = Invoke-ChatGPTAPI -apiKey $Settings.OpenAIKey -prompt $usePrompt
                
                try {
                    $jsonObject = $filenameJson | ConvertFrom-Json
                    $filename = $jsonObject.filename
                } catch {
                    Write-Host "Error: Failed to parse JSON for filename. Using Response: $($response)"
                    $filename = $null
                }
                
            }
            
            if ([string]::IsNullOrEmpty($filename)) {
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $filename = "$($SessionFolder)source_$($timestamp).txt"
            } else {
                $filename = "$($SessionFolder)$($filename)"
            }
            
        } else {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $filename = "$($SessionFolder)source_$($timestamp).txt"
        }

        $uniqueFilename = Get-UniqueFilename -filename $filename

        if ($Settings.Debug) {
            Write-Host "Debug: Filename = $($filename)"
        }
        SaveCodeToFile -filename $uniqueFilename -content $code
    }
}

return $response
