Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Start Code Saver Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"
    Write-Host "Code Saver: Creating Project JSON with GPT" -ForegroundColor Green

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

        $myProps = GetProperties
        $dataSystem = GetProperty -properties $myProps -propertyName "Build Project Data System"

        $dataSystem = "$($system) $($dataSystem)"

        $projectName = Read-Host "Enter the name for this project"
        $currentDate = (Get-Date).ToString("yyyy-MM-dd")

        
        $data = @{
            Name        = $projectName
            Description = ""
            StartDate   = $currentDate
            EndDate     = ""
            Completed   = $false
            System      = @{
                "CurrentDate" = $currentDate
                "Prompt" = $prompt
                "System" = $system
                "Language" = ""
                "CurrentStep" = 0
            }
            Phases      = @(
                @{
                    Name        = "Design"
                    Description = "Design the application structure and user interface."
                    StartDate   = $currentDate
                    EndDate     = ""
                    Completed   = $false
                },
                @{
                    Name        = "Development"
                    Description = "Implement the application functionality and features."
                    CurrentStep = 1
                    StartDate   = $currentDate
                    EndDate     = ""
                    Completed   = $false
                },
                @{
                    Name        = "Testing"
                    Description = "Test the application for bugs and performance issues."
                    StartDate   = $currentDate
                    EndDate     = ""
                    Completed   = $false
                },
                @{
                    Name        = "Publishing"
                    Description = "Deploy the application to the production environment."
                    StartDate   = $currentDate
                    EndDate     = ""
                    Completed   = $false
                }
            )
        }

        $workSpace = ($data | ConvertTo-Json -Depth 10).Trim('"')


        if ($useOffline) {
            $workSpacePrompt = " $($workSpace)"
            $workSpaceJson = Invoke-GPT4ALL -prompt $workSpacePrompt -response $response -system $dataSystem

            try {
                $jsonObject = $workSpaceJson | ConvertFrom-Json
            } catch {
                $jsonObject = $null
            }

        } else {
            $workSpaceJson = Invoke-ChatGPTAPI -prompt $($workSpace) -system $dataSystem
            
            try {
                $jsonObject = $workSpaceJson | ConvertFrom-Json
            } catch {
                $jsonObject = $null
            }
        }

        if ($jsonObject -ne $null) {
            if ($jsonObject.System -ne $null) {
                if ($jsonObject.System.CurrentStep -eq 1) {
                    if ($jsonObject.Phases -ne $null) {
                        $designFound = $false
                        $developmentFound = $false
                        foreach ($phase in $jsonObject.Phases) {
                            if ($phase.Name -eq "Design") {
                                $designFound = $true
                            } elseif ($phase.Name -eq "Development") {
                                $developmentFound = $true
                            }
                        }

                        if ($designFound -and $developmentFound) {
                            $global:globalCodeSaverWorkspace = $workSpaceJson
                            
                            $SetName = & $plugin.FullName -FunctionName "GetFullName"

                            $global:globalCodeSaverFolder = Join-Path $sessionFolder "CodeSaver"
                            if (-not (Test-Path $global:globalCodeSaverFolder)) {
                                New-Item -ItemType Directory -Path $global:globalCodeSaverFolder | Out-Null
                            }

                            $projectFile = Join-Path $global:globalCodeSaverFolder "codesaver.json"
                            Set-Content -Path $projectFile -Value $workSpaceJson

                            Debug -debugText "Code Saver: Project JSON : $($workSpaceJson)"
                            Write-Host "Code Saver: Created Project JSON with GPT" -ForegroundColor Green
                            return $prompt
                        } else {
                            SetProperty -properties $properties -propertyName "WorkerSpace" -propertyValue ""
                            Write-Host "Code Saver Error: Json failed to have Design or Development (try again) : $($workSpaceJson)" -ForegroundColor Red
                            $global:taskComplete = $true
                        }
                    } else {
                        SetProperty -properties $properties -propertyName "WorkerSpace" -propertyValue ""
                        Write-Host "Code Saver Error: Json failed to have Phases (try again) : $($workSpaceJson)" -ForegroundColor Red
                        $global:taskComplete = $true
                    }
                } else {
                    SetProperty -properties $properties -propertyName "WorkerSpace" -propertyValue ""
                    Write-Host "Code Saver Error: Json failed to update CurrentStep properly (try again) : $($workSpaceJson)" -ForegroundColor Red
                    $global:taskComplete = $true
                }
            } else {
                SetProperty -properties $properties -propertyName "WorkerSpace" -propertyValue ""
                Write-Host "Code Saver Error: Json failed to have System property (try again) : $($workSpaceJson)" -ForegroundColor Red
                $global:taskComplete = $true
            }
        } else {
            SetProperty -properties $properties -propertyName "WorkerSpace" -propertyValue ""
            Write-Host "Code Saver Error: Failed to parse JSON for Project Design (try again) : $($workSpaceJson)" -ForegroundColor Red
            $global:taskComplete = $true
        }
        
        
        # SavePluginPropertiesToFile -pluginName $SetName -properties $properties
    } else {
        return $prompt
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
            Name  = "Build Project Data System"
            Value = "Update the Data object with the programming language in 'System.Prompt' and 'System.System'. Add a brief 'Description' combining their values, and set 'System.CurrentStep' to '1'. Add a 'Steps' property to 'Phases.Testing', 'Phases.Publishing', with a list containing 'Description', 'Answer', and 'Completed' set to false. In the 'Phases.Development' section, change 'Description' with the project description of what needs to be made, also  include a 'Files' property with required files (each item should have a property for 'Filename', and make a list of 'Steps' with the properties of 'Description' and 'Completed' set to false. Under 'Phases.Design', add a 'Steps' property with a list of required steps and sub-items with 'Description', Answers (use the '[DALLE dest='filename.png']...[/DALLE]' tag with a detailed description and filename), and 'Completed' set to true. Return a single JSON object with the original and updated properties merged."
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
    return 0 # Start Plugin
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
