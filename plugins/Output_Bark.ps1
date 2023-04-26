Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Output Bark Prompts Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    # Check for [Dalle]..[/dalle] tags and process them
    $regexPattern = '(?i)\<bark(.*?)\>(.*?)\</bark\>'
    $regex = [regex]::new($regexPattern)

    $matches = $regex.Matches($response)

    foreach ($match in $matches) {
        $content = $match.Groups[2].Value
        

        $options = $match.Groups[1].Value.Trim()

        # Add this code to extract 'dest' value and save it to $optionsFilename
        $optionsDestRegex = "(?i)dest='(.*?)'"
        $optionsDestMatch = [regex]::Match($options, $optionsDestRegex)
        $optionsFilename = $optionsDestMatch.Groups[1].Value
        
        $optionsRegex = "(?i)voice='(.*?)'"
        $optionsVoice = [regex]::Match($options, $optionsRegex)
        $voiceValue = [int]([regex]::Match($optionsVoice, '\d+')).Value

        if ($null -eq $overrideSavePath -or [string]::IsNullOrEmpty($overrideSavePath)) {
            if ($null -eq $global:SessionFolder -or [string]::IsNullOrEmpty($global:SessionFolder)) {
                $barkFolderPath = Join-Path -Path (Get-Location).Path -ChildPath "Voice"
            } else {
                $barkFolderPath = Join-Path -Path (Get-Location).Path -ChildPath $global:SessionFolder
                $barkFolderPath = Join-Path -Path $barkFolderPath -ChildPath "Voice"
            }
        } else {
            $barkFolderPath = $overrideSavePath
        }
    
        if (!(Test-Path -Path $barkFolderPath)) {
            New-Item -ItemType Directory -Path $barkFolderPath | Out-Null
        }

        $outfile = Get-UniqueFilename -filename  $optionsFilename -folder $barkFolderPath

        if (!$settings.UseOnlineSpeechSynthesis) {
            $barkResponse = Invoke-Bark -prompt $content -filename $outfile -voice $voiceValue
        } else {
            Write-Host "Not Implemented" -ForegroundColor Red
        }

        # $response = $response.Replace($match.Value, "`"$content`"")
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

