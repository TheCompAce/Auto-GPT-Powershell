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

    . .\module\plugins\CodeWorker.ps1

    Debug -debugText "$(GetFullName) Running"
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
        $useOffline = -not $Settings.UseOnlineGPT
        $offlineModel = $Settings.model
    }


    $plugin = GetPluginByName -pluginName "Output Code Saver Plugin"
    
    if ($plugin -ne $null) {
        $properties = & $plugins[$i].FullName -FunctionName "GetProperties"

        $useGPTFilename = GetProperty -properties $props -propertyName "Use GPT to Get Filenames"
        $promptForFilename = GetProperty -properties $props -propertyName "Filename System Prompt"
        $overideGPT = GetProperty -properties $props -propertyName "Override GPT"
    
        if ($overideGPT) {
            $openAiModel = GetProperty -properties $props -propertyName "ChatGPT Model"
            $useOffline = GetProperty -properties $props -propertyName "Use Offline GPT"
            $offlineModel = GetProperty -properties $props -propertyName "Offline Model"
        } else {
            $openAiModel = $Settings.OpenAiModel
            $useOffline = -not $Settings.UseOnlineGPT
            $offlineModel = $Settings.model
        }

        $workSpace = GetProperty -properties $properties -propertyName "WorkerSpace"

        $workSpaceObject = $global:globalCodeSaverWorkspace | ConvertFrom-Json

        if ($workSpaceObject -ne $null) {
            if (-not $workSpaceObject.Completed) {
                if ($workSpaceObject.Phases -ne $null) {
                    $devFound = $false
                    foreach ($phase in $workSpaceObject.Phases) {
                        if ($phase.Name -eq "Development") {
                            $devData = $phase
                            $devFound = $true
                            break
                        }
                    }

                    if ($devFound) {
                        if (-not $devData.Completed) {
                            $myProps = GetProperties
                            $currentStep = $devData.CurrentStep; 

                            if ($currentStep -eq 1) {
                                $step1Prompt = GetProperty -properties $myProps -propertyName "Step 1 Input Prompt"
                                $stepsCompleted = $true;
                                for ($i = 0; $i -lt $devData.Steps.Count; $i++) {
                                    if ($devData.Steps[$i].Completed -eq $false) {
                                        $currentStepData = $devData.Steps[$i]
                                        $stepsCompleted = $false
                                        break
                                    }
                                }
                                if (-not $stepsCompleted) {
                                    try {
                                        $dataChanged = $false
                                        $responseData = $response.Trim() | ConvertFrom-Json

                                        $fileFound = $false
                                        foreach ($file in $responseData.Files) {
                                            foreach ($datFile in $devData.Files) {
                                                if ($datFile.Filename -eq $file) {

                                                }
                                            }
                                        }
                                    
                                    return $codePrompt
                                    } catch {
                                        Write-Host "Code Saver: Unable to get JSON from Response (try again?, yeah retrying.)" -ForegroundColor Yellow
                                    }
                                } else {
                                    Write-Host "Code Saver: Code Completd." -ForegroundColor Yellow
                                }
                            } else {
                                Write-Host "Code Saver Error: Unknown Step." -ForegroundColor Red
                                $global:taskComplete = $true
                            }
                        } else {
                            Write-Host "Code Saver: Code Completd." -ForegroundColor Green
                        }
                    } else {
                        Write-Host "Code Saver Error: Unable to find Development." -ForegroundColor Red
                        $global:taskComplete = $true
                    }
                } else {
                    Write-Host "Code Saver Error: Unable to find Phases." -ForegroundColor Red
                    $global:taskComplete = $true
                }
            } else {
                Write-Host "Code Saver: Project Completd." -ForegroundColor Green
                $global:taskComplete = $true
            }
        } else {
            Write-Host "Code Saver Error: Work Space is Null." -ForegroundColor Red
            $global:taskComplete = $true
        }   
    }


    <# $codePattern = "(?s)(?<=```).*?(?=```)"
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
                        $usePrompt = "[Reference]$($response)[/Reference][Code]$($code)[/Code]"
                        
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
    } #>


    # Respond with the Prompt so it can be passed on.
    return $response
}

function GetProperties {
    $setName = GetFullName
    $propertiesFromFile = GetPluginPropertiesFromFile -pluginName $setName

    $defaultProperties = @(
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
        @{
            Name  = "WorkerSpace"
            Value = ""
            Type  = "Temp"
        }
    )

    if ($propertiesFromFile -ne $null) {
        $updatedProperties = MergeAndSaveProperties -pluginName $setName -defaultProperties $defaultProperties -loadedProperties $propertiesFromFile
        return $updatedProperties
    }

    return $defaultProperties
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

