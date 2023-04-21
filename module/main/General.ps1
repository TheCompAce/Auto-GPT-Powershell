function Get-UniqueFilename {
    param (
        [string]$filename,
        [string]$folder
    )

    $fileInfo = Get-Item -Path (Join-Path $folder $filename) -ErrorAction SilentlyContinue
    if ($null -eq $fileInfo) {
        return Join-Path $folder $filename
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $extension = [System.IO.Path]::GetExtension($filename)

    $number = 1
    while ($true) {
        Start-Sleep -Milliseconds 10
        $newFilename = "{0}({1}){2}" -f $baseName, $number, $extension
        if (-not (Test-Path $newFilename)) {
            return Join-Path $folder $newFilename
        }
        $number++
    }
}

function PrepareRequestBody($scheme, $system, $user, $seed) {
    $systemJsonSafe = ($system | ConvertTo-Json).Trim('"')
    $userJsonSafe = ($user | ConvertTo-Json).Trim('"')
    $seedJsonSafe = ($seed | ConvertTo-Json).Trim('"')

    $tempFolderPath = ".\temp"

    if (-not (Test-Path $tempFolderPath)) {
        New-Item -ItemType Directory -Path $tempFolderPath | Out-Null
    }

    if ($scheme.Contains("[systemFile]") -or $scheme.Contains("[userFile]")) {
        if ($scheme.Contains("[systemFile]")) {
            $tempSystemFile = Join-Path $tempFolderPath ([System.IO.Path]::GetRandomFileName())
            Set-Content -Path $tempSystemFile -Value $system
            $tempSystemFileJsonSafe = ($tempSystemFile | ConvertTo-Json).Trim('"')
            $scheme = $scheme.Replace("[systemFile]", $tempSystemFile)
        }

        if ($scheme.Contains("[userFile]")) {
            $tempUserFile = Join-Path $tempFolderPath ([System.IO.Path]::GetRandomFileName())
            Set-Content -Path $tempUserFile -Value $user
            $tempUserFileJsonSafe = ($tempUserFile | ConvertTo-Json).Trim('"')
            $scheme = $scheme.Replace("[userFile]", $tempUserFile)
        }
    }

    $result = $scheme.Replace("[system]", $systemJsonSafe).Replace("[user]", $userJsonSafe).Replace("[seed]", $seedJsonSafe)

    return $result
}

function ClearTempFolder {
    $tempFolderPath = ".\temp"

    if (Test-Path $tempFolderPath) {
        Remove-Item -Path $tempFolderPath\* -Recurse -Force
    }
}



function RunPluginsByType {
    Param(
        [string]$pluginType,
        [string]$prompt,
        [string]$response,
        [string]$system
    )


    $plugins = GetPluginsOfType -PluginType $pluginType | Sort-Object { (GetProperty -properties (& $_.FullName -FunctionName "GetProperties") -propertyName "Order") }
    
    if ($pluginType -eq 1) {
        $retValue = $system
    } elseif ($pluginType -eq 3) {
        $retValue = $response
    } else {
        $retValue = $prompt
    }
    
    for ($i = 0; $i -lt $plugins.Count; $i++) {
        $properties = & $plugins[$i].FullName -FunctionName "GetProperties"
        $enabled = GetProperty -properties $properties -propertyName "Enabled"
        
        if ($enabled) {
            if ($pluginType -eq 1) {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($prompt, $response, $retValue)
            } elseif ($pluginType -eq 3) {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($prompt, $retValue, $system)
            } else {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($retValue, $response, $system)
            }
        }
    }

    return $retValue
}

function GetAllPlugins {
    $allPlugins = @()
    $pluginFiles = Get-ChildItem -Path ".\plugins" -Filter "*.ps1" | Sort-Object Name

    for ($i = 0; $i -lt $pluginFiles.Count; $i++) {
        $allPlugins += $pluginFiles[$i]
    }

    return $allPlugins
}

function GetProperty {
    Param(
        [array]$properties,
        [string]$propertyName
    )

    foreach ($prop in $properties) {
        if ($prop.Name -eq $propertyName) {
            if ($prop.Type -eq "Array") {
                $linkedProperty = $prop["Link"]
                $selectedIndex = (GetProperty -properties $properties -propertyName $linkedProperty)
                return $prop.Value[$selectedIndex]
            } else {
                return $prop.Value
            }
        }
    }

    return $null
}

function SetProperty {
    Param(
        [array]$properties,
        [string]$propertyName,
        $propertyValue
    )

    for ($i = 0; $i -lt $properties.Count; $i++) {
        if ($properties[$i].Name -eq $propertyName) {
            $properties[$i].Value = $propertyValue
            return $properties
        }
    }

    $newProperty = @{
        Name  = $propertyName
        Value = $propertyValue
        Type  = 'String'
    }
    $properties += $newProperty

    return $properties
}

function GetPluginsOfType {
    Param(
        [string]$PluginType
    )

    $allPlugins = GetAllPlugins
    $retPlugins = @()
    for ($i = 0; $i -lt $allPlugins.Count; $i++) {
        $chkPluginType = & $allPlugins[$i].FullName -FunctionName "GetPluginType"
        
        if ($chkPluginType -eq $PluginType) {
            $retPlugins += $allPlugins[$i]
        }
    }

    return $retPlugins
}

function GetPluginByName {
    Param(
        [string]$pluginName
    )

    $allPlugins = GetAllPlugins
    $retPlugins = @()
    for ($i = 0; $i -lt $allPlugins.Count; $i++) {
        # Call the GetFullName function from the plugin file
        $currentPluginName = & $allPlugins[$i].FullName -FunctionName "GetFullName"
        
        if ($pluginName -eq $currentPluginName) {
            return $allPlugins[$i]
        }
    }

    return $null
}


function GetPluginNameFromType {
    Param(
        [string]$PluginType
    )
    $pluginStr = ""
    switch ($PluginType) {
        "0" { $pluginStr = "Start" }
        "1" { $pluginStr = "System" }
        "2" { $pluginStr = "Input" }
        "3" { $pluginStr = "Output" }
        Default { $pluginStr = "Unkown" }
    }

    return $pluginStr
}

function GetPluginPropertiesFromFile {
    Param(
        [string]$pluginName
    )
    
    $pluginFullName = $pluginName
    $pluginsJsonPath = ".\plugins.json"

    if (Test-Path $pluginsJsonPath) {
        $pluginsJson = Get-Content $pluginsJsonPath | ConvertFrom-Json

        foreach ($plugin in $pluginsJson.Plugins) {
            if ($plugin.FullName -eq $pluginFullName) {
                $properties = @()

                foreach ($prop in $plugin.Properties) {
                    $addProp = @{
                        Name  = $prop.Name
                        Value = $prop.Value
                        Type  = $prop.Type
                    }

                    if ($prop.PSObject.Properties.Name -contains 'Link') {
                        $addProp.Link = $prop.Link
                    }

                    $properties += $addProp
                }

                return $properties
            }
        }
    }

    return $null
}


function SavePluginPropertiesToFile {
    Param(
        [string]$pluginName,
        [array]$properties
    )
    
    $pluginsJsonPath = ".\plugins.json"

    $pluginsJson = if (Test-Path $pluginsJsonPath) {
        Get-Content $pluginsJsonPath | ConvertFrom-Json
    } else {
        @{
            Plugins = @()
        }
    }

    $pluginFound = $false

    for ($i = 0; $i -lt $pluginsJson.Plugins.Count; $i++) {
        if ($pluginsJson.Plugins[$i].FullName -eq $pluginName) {
            $pluginsJson.Plugins[$i].Properties = $properties
            $pluginFound = $true
            break
        }
    }

    if (-not $pluginFound) {
        $pluginsJson.Plugins += @{
            FullName = $pluginName
            Properties = $properties
        }
    }

    $pluginsJson | ConvertTo-Json -Depth 10  | Set-Content $pluginsJsonPath
}

function MergeAndSaveProperties {
    Param(
        [string]$pluginName,
        [array]$defaultProperties,
        [array]$loadedProperties
    )

    $updatedProperties = @()
    $propertyNames = $loadedProperties | ForEach-Object { $_.Name }

    # Check for changes and update properties if necessary
    foreach ($defaultProperty in $defaultProperties) {
        if ($defaultProperty.Type -eq "Temp") { continue }
        $foundProperty = $loadedProperties | Where-Object { $_.Name -eq $defaultProperty.Name }
        if ($foundProperty) {
            $updatedProperties += $foundProperty
        } else {
            $updatedProperties += $defaultProperty
        }
    }

    SavePluginPropertiesToFile -pluginName $pluginName -properties $updatedProperties
    return $updatedProperties
}

function UpdateSettingsWithDefaults {
    Param (
        $Settings
    )

    $properties = @{
        Version                   = "0.1.0"
        LocalGPTPath              = ".\gpt4all-lora-quantized-win64.exe -m gpt4all-lora-quantized.bin -n 1000 -c 4000 -s [seed] -f [userFile]"
        OnlineGPTPath             = ""
        UseOnlineGPT              = $false
        SendOnlyPromptToGPT       = $true
        GPTPromptScheme           = ""
        UseOpenAIGPTAuth          = $false
        LocalTextToImagePath      = ""
        OnlineTextToImagePath     = ""
        UseOnlineTextToImage      = $false
        SendOnlyPromptToTextToImage = $false
        TextToImagePromptScheme   = ""
        UseOpenAIDalleAuth        = $false
        OnlineAPIKey              = ""
        pause                     = "y"
        seed                      = ""
        LoopCount                 = "10"
        Debug                     = $false
        UseOpenAIDALLEAuthentication = $False
        UseOpenAIGPTAuthentication = $false
    }

    if (-not (Test-Path "settings.json")) {
        $properties | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
        return $properties
    }

    if ($Settings -ne $null) {
        # Create a new object to store the updated settings
        $updatedSettings = New-Object -TypeName PSCustomObject

        foreach ($key in $properties.Keys) {
            if ($Settings.PSObject.Properties.Name.Contains($key)) {
                # If the key exists in the loaded settings, use its value
                $updatedSettings | Add-Member -MemberType NoteProperty -Name $key -Value $Settings.$key
            } else {
                # If the key doesn't exist in the loaded settings, use the default value
                $updatedSettings | Add-Member -MemberType NoteProperty -Name $key -Value $properties[$key]
            }
        }

        return $updatedSettings
    }

    return $properties
}



function SaveCodeToFile {
    param (
        [string]$filename,
        [string]$content
    )

    Set-Content -Path $filename -Value $content
}

function Debug {
    Param(
        [string]$debugText
    )

    if ($Settings.Debug) {
        Write-Host "Debug: $($debugText)" -ForegroundColor Yellow
    }
}


function Generate-RandomString {
    param (
        [int]$length = 5
    )

    return (-join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object { [char]$_ }))
}


