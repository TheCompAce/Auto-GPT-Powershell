Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "System Sample Plugin"
}

function Run {
    Param(
        [string]$prompt
    )

    Debug -debugText "Debug: $(GetFullName)"
    # This file takes in the "Prompt" and returns it without changing it.
    return $prompt
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
        }
    )
    return $properties
}

function GetConfigurable {
    return "True"
}

function GetPluginType {
    return "1" # System Plugin
}

# ////////////////////////////////////////////////////////////
# Common Code do not change unles you want to break something.
# ////////////////////////////////////////////////////////////


switch ($FunctionName) {
    "GetFullName" { return GetFullName }
    "GetConfigurable" { return GetConfigurable }
    "Run" { return Run -prompt $ArgumentList[0] }
    "GetPluginType" { return GetPluginType }
    "GetProperties" { return GetProperties }
    default { Write-Host "Invalid function name" }
}
