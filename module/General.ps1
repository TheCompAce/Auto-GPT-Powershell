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
    } elseif ($pluginType -eq 2) {
        $retValue = $prompt
    } else {
        $retValue = $response
    }
    
    for ($i = 0; $i -lt $plugins.Count; $i++) {
        $properties = & $plugins[$i].FullName -FunctionName "GetProperties"
        $enabled = GetProperty -properties $properties -propertyName "Enabled"
        
        if ($enabled) {
            if ($pluginType -eq 1) {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($prompt, $response, $retValue)
            } elseif ($pluginType -eq 2) {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($retValue, $response, $System)
            } else {
                $retValue = & $plugins[$i].FullName -FunctionName "Run" -ArgumentList @($prompt, $retValue, $system)
            }
        }
    }

    return $retValue
}

function GetPluginPropertiesFromFile {
    Param(
        [string]$pluginName
    )
    
    $pluginFullName = $pluginName
    $pluginsJsonPath = ".\plugins.json"

    if (Test-Path $pluginsJsonPath) {
        $pluginsJson = Get-Content $pluginsJsonPath | ConvertFrom-Json -Depth 10

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
        Get-Content $pluginsJsonPath | ConvertFrom-Json -Depth 10
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

function SaveCodeToFile {
    param (
        [string]$filename,
        [string]$content
    )

    Set-Content -Path $filename -Value $content
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

function Debug {
    Param(
        [string]$debugText
    )

    if ($Settings.Debug) {
        Write-Host "Debug: $($debugText)" -ForegroundColor Yellow
    }
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


function Generate-RandomString {
    param (
        [int]$length = 5
    )

    return (-join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object { [char]$_ }))
}


