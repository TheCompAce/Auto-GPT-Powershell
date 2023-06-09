Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "System Code Saver Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

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
                                $step1System = GetProperty -properties $myProps -propertyName "Step 1 System Prompt"
                                return $step1System
                                
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
            }
        } else {
            Write-Host "Code Saver Error: Work Space is Null." -ForegroundColor Red
            $global:taskComplete = $true
        }   
    }

    return $system
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
            Name  = "Step 1 System Prompt"
            Value = "Create the source files for 'CurrentTask' task. Use 'Prompt' to act as the main prompt for the user, and 'System' for the System data for the users 'Prompt'. Use the list of 'Files' for what to edit (unless the 'Completed' property is true).  Return the Response as a JSON data, create a property 'Completed' (set to true if this code is completed in this 'CompleteTask'), add a list 'Files' (of all the files that we are changing or creating), each item under 'Files' has 'Filename' (set to the filename),'Completed' (set to true if this file is done for this step), 'Source' (add full examples of the source code), 'Type:'Source''. If any images are needed then create a 'Files' item with 'Filename', 'Type:'Image''), 'DALLE' (set to a 'Text to Image' prompt to describe the image the best you can.)"
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
    return 1 # System Plugin
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

