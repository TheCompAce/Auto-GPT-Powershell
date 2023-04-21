Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "System DallE Prompts Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    $props = GetProperties
    $propVal = GetProperty -properties $props -propertyName "DALLE System Prompt"
    $system = "$($propVal) $($system)"

    # This file takes in the "Prompt" and returns it without changing it.
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
            Name  = "DALLE System Prompt"
            Value = "If a image is required then create a '<DALLE dest='filename.png'>value</DALLE>' tag (where 'filename.png' is the name the image should be saved as after being made) that has the 'value' that Describes the image in as much detail as you can, and ensure every '<DALLE>' tag has a closing '</DALLE>' tag."
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

