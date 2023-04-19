Param(
    [string]$FunctionName,
    [array]$ArgumentList
)

function GetFullName {
    return "Output Code Saver Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    . .\module\CodeWorker.ps1

    Debug -debugText "Debug: $(GetFullName)"
    # Check For Code in the Response

    $props = GetProperties
    $useGPTFilename = GetProperty -properties $props -propertyName "Use GPT to Get Filenames"
    $promptForFilename = GetProperty -properties $props -propertyName "Filename System Prompt"
    $overideGPT = GetProperty -properties $props -propertyName "Override GPT"

    if ($overideGPT) {
        $openAiModel = GetProperty -properties $props -propertyName "ChatGPT Model"
        $useOffline = GetProperty -properties $props -propertyName "Use Offline GPT"
        $offlineModel = GetProperty -properties $props -propertyName "Offline Model"
    } else {
        $openAiModel = $Settings.OpenAiModel
        $useOffline = -not $Settings.UseChatGPT
        $offlineModel = $Settings.model
    }


    $codePattern = "(?s)(?<=```).*?(?=```)"
    $codeMatches = [regex]::Matches($response, $codePattern)
    
    foreach ($match in $codeMatches) {
        $code = $match.Value.Trim()
        if ($code) {
            $lineCount = ($code -split "`n").Count 
            if ($lineCount -gt 2) {
                Write-Host $lineCount -ForegroundColor Red
                $isCode = Is-LikelyCode -code $code -thresholdPct 4.0
                $isLang = Is-LikelyNaturalLanguage -text $code -thresholdPct 2.0
                # if ($isLang -ne 0) {
                    $lines = $code -split "`n"    # Split the string into an array of lines
                    $lines = $lines[1..($lines.Count - 1)]    # Remove the first line from the array
                    $code = $lines -join "`n"    # Join the remaining lines back into a string
                    Write-Host $code

                    Write-Host $isCode -ForegroundColor Cyan
                    Write-Host $isLang -ForegroundColor Cyan

                    Debug -debugText "Debug: Code Found $($code)"
            
                    $iscode = $true;
                    if ($useGPTFilename) {
                        $usePrompt = "$($code)"
                        
                        if ($useOffline) {
                            $filenameJson = Invoke-GPT4ALL -prompt $usePrompt -model $offlineModel

                            try {
                                $jsonObject = $filenameJson | ConvertFrom-Json
                                $filename = $jsonObject.filename
                            } catch {
                                Write-Host "Error: Failed to parse JSON for filename."
                                $filename = $null
                            }

                        } else {
                            if ($openAiModel -eq "gpt-3.5-turbo" -or $openAiModel -eq "gpt-4") {
                                
                                $filenameJson = Invoke-ChatGPTAPI -apiKey $Settings.OpenAIKey -prompt $usePrompt -startSystem $promptForFilename -model $openAiModel
                                
                                try {
                                    $jsonObject = $filenameJson | ConvertFrom-Json
                                    $filename = $jsonObject.filename
                                    $iscode = $jsonObject.iscode
                                } catch {
                                    Write-Host "Error: Failed to parse JSON for filename."
                                    $filename = $null
                                }
                                
                            } else {
                                $usePrompt = "$($usePrompt) $($promptForFilename)"
                                $filenameJson = Invoke-ChatGPTAPI -apiKey $Settings.OpenAIKey -prompt $usePrompt -model $openAiModel
                                
                                try {
                                    $jsonObject = $filenameJson | ConvertFrom-Json
                                    $filename = $jsonObject.filename
                                    $iscode = $jsonObject.iscode
                                } catch {
                                    Write-Host "Error: Failed to parse JSON for filename."
                                    $filename = $null
                                }
                            }   
                        }

                        if ([string]::IsNullOrEmpty($filename)) {
                            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                            $filename = "source_$($timestamp).txt"
                        } else {
                            $filename = $($filename)
                        }
                        
                    } else {
                        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                        $filename = "source_$($timestamp).txt"
                    }

                    if ($iscode) {
                        $uniqueFilename = Get-UniqueFilename -filename $filename -folder $SessionFolder
                        Write-Host $uniqueFilename -ForegroundColor DarkMagenta

                        Debug -debugText "Debug: Filename = $($filename)"
                        SaveCodeToFile -filename $uniqueFilename -content $code
                    }
                # }
            }
        }
    }


    # Respond with the Prompt so it can be passed on.
    return $response
}

function GetProperties {
    $setName = GetFullName
    $propertiesFromFile = GetPluginPropertiesFromFile -pluginName $setName

    if ($propertiesFromFile -ne $null) {
        return $propertiesFromFile
    }

    $properties = @(
        @{
            Name  = "Enabled"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Order"
            Value = 99
            Type  = "Int"
        },
        @{
            Name  = "Remove Code From Response."
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Override GPT"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Use Offline GPT"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Offline Model"
            Value = "gpt4all-lora-quantized.bin"
            Type  = "String"
        },
        @{
            Name  = "ChatGPT Model"
            Value = @("text-davinci-003", "gpt-3.5-turbo", "gpt-4")
            Type  = "Array"
            Link  = "SelectedChatGPTModelIndex"
        },
        @{
            Name  = "SelectedChatGPTModelIndex"
            Value = 0
            Type  = "Hidden"
        },
        @{
            Name  = "Use GPT to Get Filenames"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Filename System Prompt"
            Value = "Respond with ONLY a JSON [code]{ 'filename': [filename], 'iscode': [iscode] }[/code]. The prompt should have a filename commented out at the type of the code to set to the [filename] value in the response JSON. (If not then create a filename (with extension) from the code itself.) And for the [iscode] set the value to a boolean value of true if the prompt is source code, or false if it is just text."
            Type  = "String"
        },
        @{
            Name  = "Use GPT to edit base files."
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Edit Source System Prompt"
            Value = ""
            Type  = "String"
        }
    )

    return $properties
}

function GetConfigurable {
    return "True"
}

function GetPluginType {
    return 3 # Output Plugin
}

# ////////////////////////////////////////////////////////////
# Common Code do not change unles you want to break something.
# ////////////////////////////////////////////////////////////


switch ($FunctionName) {
    "GetFullName" { return GetFullName }
    "GetConfigurable" { return GetConfigurable }
    "Run" { return Run -prompt $ArgumentList[0] -response $ArgumentList[1] -system $ArgumentList[2]}
    "GetPluginType" { return GetPluginType }
    "GetProperties" { return GetProperties }
    default { Write-Host "Invalid function name" }
}

