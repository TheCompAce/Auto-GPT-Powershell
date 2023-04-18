Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Output Session Log Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response
    )

    $properties = GetProperties

    if ($properties.Enabled) {
        Debug -debugText "Debug: $(GetFullName)"
        Add-Content -Path $SessionFile -Value "Prompt: $prompt`nResponse: $response"
    }
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
        }
    )

    return $properties
}

function GetConfigurable {
    return "True"
}

function GetPluginType {
    return "3" # Output Plugin
}

# ////////////////////////////////////////////////////////////
# Common Code do not change unles you want to break something.
# ////////////////////////////////////////////////////////////


switch ($FunctionName) {
    "GetFullName" { return GetFullName }
    "GetConfigurable" { return GetConfigurable }
    "Run" { return Run -prompt $ArgumentList[0] -response $ArgumentList[1] }
    "GetPluginType" { return GetPluginType }
    "GetProperties" { return GetProperties }
    default { Write-Host "Invalid function name" }
}
