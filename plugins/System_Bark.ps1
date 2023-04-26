Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "System Bark Prompts Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    $props = GetProperties
    $propVal = GetProperty -properties $props -propertyName "Bark System Prompt"
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
            Name  = "Bark System Prompt"
            Value = "Please generate dialog or voice statements using Bark Tags in this format: `"<BARK dest='filename.wav' sex='MALE/FEMALE' voice='0-9'>text</BARK>`". Include 'filename.wav' as a unique wav filename, 'sex' as 'MALE' or 'FEMALE' (optional), 'voice' as a constant voice type (0-9), and 'text' for speech content. Incorporate options like [laughter], [laughs], [sighs], [music], [gasps], [clears throat], '—' or '...' for hesitations, '♪' for song lyrics, and capitalization for emphasis in the speech content."
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

