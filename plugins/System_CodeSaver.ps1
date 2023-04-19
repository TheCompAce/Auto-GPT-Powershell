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

    Debug -debugText "Debug: $(GetFullName)"

    $props = GetProperties
    $propVal = GetProperty -properties $props -propertyName "Add To System Prompt"
    $system = "$($system). The following '[codeSaver]' section should handle the formating of responses with source code in it. [codeSaver]$($propVal)[/codeSaver]"

    return $system
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
            Name  = "Add To System Prompt"
            Value = "Ensure that your explanation is clear, concise, and uses markdown/text safe formatting. Provide detailed instructions, including code examples if necessary. For every code example provided, include a comment at the top of the code with the filename (and path if needed) referencing the code. We will work on this project in Steps. At the Start of each Response include a line for what we are about to do in this step. At the end of each Response include a line for the next step to take."
            Type  = "String"
        }
    )
    return $properties
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

