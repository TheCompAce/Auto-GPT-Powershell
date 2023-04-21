Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Output DallE Prompts Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    # Check for [Dalle]..[/dalle] tags and process them
    $regexPattern = '(?i)\<Dalle(.*?)\>(.*?)\</dalle\>'
    $regex = [regex]::new($regexPattern)
    $matches = $regex.Matches($response)

    foreach ($match in $matches) {
        $content = $match.Groups[2].Value
        if ($settings.UseOnlineTextToImage) {
            $dalleResponse = Invoke-DallEAPI -prompt $content
        } else {
            Write-Host "Not Implemented" -ForegroundColor Red
        }

        if ($dalleResponse -ne $null) {
            $options = $match.Groups[1].Value.Trim()
            $optionsRegex = "(?i)dest='(.*?)'"
            $optionsMatch = [regex]::Match($options, $optionsRegex)
            if ($optionsMatch.Success) {
                $dest = $optionsMatch.Groups[1].Value
                
                Save-DalleImages -prompt $content -dalleResponse $dalleResponse -optionsFilename $dest
            } else {
                Save-DalleImages -prompt $content -dalleResponse $dalleResponse
            }
        }

        $response = $response.Replace($match.Value, "")
    }

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

