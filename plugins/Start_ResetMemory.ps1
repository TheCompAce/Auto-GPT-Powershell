Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Start Reset Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    $props = GetProperties
    $propVal = GetProperty -properties $props -propertyName "Start Prompt Reset"
    $prompt = "$($propVal) $($prompt)"
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
            Name  = "Start Prompt Reset"
            Value = "Forget any previous Session."
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
