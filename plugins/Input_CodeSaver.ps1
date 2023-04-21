Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Input Code Saver Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    . .\module\plugins\CodeSaver.ps1

    Debug -debugText "$(GetFullName) Running"

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
                    $devData = GetPhaseSection -phases $workSpaceObject.Phases -name "Development"
                    
                    if ($devData -ne $null) {
                        if (-not $devData.Completed) {
                            $myProps = GetProperties
                            $currentStep = $devData.CurrentStep; 

                            if ($currentStep -eq 1) {
                                $step1Prompt = GetProperty -properties $myProps -propertyName "Step 1 Input Prompt"
                                $stepsCompleted = $true;
                                $stepIndex = -1
                                for ($i = 0; $i -lt $devData.Steps.Count; $i++) {
                                    if ($devData.Steps[$i].Completed -eq $false) {
                                        $currentStepData = $devData.Steps[$i]
                                        $stepIndex = $i
                                        $stepsCompleted = $false
                                        break
                                    }
                                }

                                if (-not $stepsCompleted) {
                                    $data = @{
                                        System      = $workSpaceObject.System.System
                                        Prompt      = $workSpaceObject.System.Prompt
                                        Files       = $devData.Files
                                        CurrentTask = $currentStepData.Description
                                    }

                                    $codePrompt = $data | ConvertTo-Json -Depth 10
                                    return $codePrompt

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

    # This file takes in the "Prompt" and returns it without changing it.
    return $prompt
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
            Name  = "Step 1 Input Prompt"
            Value = ""
            Type  = "String"
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
    return 2 # Input Plugin
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

