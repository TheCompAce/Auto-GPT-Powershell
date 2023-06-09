# Options.ps1
Param(
    [Parameter(Mandatory=$true)][PSCustomObject]$Settings
)

function ShowOptions {
    Write-Host "Basic Settings:" -ForegroundColor Green
    Write-Host "1. Change Model ($($Settings.model))"
    Write-Host "2. Toggle Pause ($($Settings.pause))"
    Write-Host "3. Change Seed ($($Settings.seed))"
    Write-Host "4. Change Loop Count ($($Settings.LoopCount))"
    Write-Host "5. Toggle Use ChatGPT ($($Settings.UseChatGPT))"
    Write-Host "6. Set OpenAI Key ($($Settings.OpenAIKey))"
    Write-Host "7. OpenAI Models ($($Settings.OpenAiModel))"
    Write-Host "8. Turn On Debug ($($Settings.Debug))"
    Write-Host "9. Plugin Settings"
    Write-Host "10. Exit"
}

function ShowLocalModels {
    $models = Get-ChildItem -Path ".\" -Filter "*.bin"
    Write-Host "Available local models:" -ForegroundColor Green
    $models | ForEach-Object { Write-Host $_.Name }
}

$oaModels = @("text-davinci-003", "gpt-3.5-turbo", "gpt-4")

function ShowOpenAIModels {    
    Write-Host "Available OpenAI models:" -ForegroundColor Green
    for ($i = 0; $i -lt $oaModels.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $oaModels[$i])
    }
}

function ConfigurePluginMenu {
    Param(
        [string]$pluginName,
        [array]$properties
    )

    while ($true) {
        Write-Host "Plugin Configuration:" -ForegroundColor Green

        # Build dynamic menu from properties
        for ($i = 0; $i -lt $properties.Count; $i++) {
            if ($properties[$i]["Type"] -eq "Array") {
                $linkedProperty = $properties[$i]["Link"]
                $selectedIndex = GetProperty -properties $properties -propertyName $linkedProperty
                if ($selectedIndex -ne $null) {
                    $displayValue = $properties[$i]["Value"][$selectedIndex]
                } else {
                    $displayValue = "Not set"
                }
            } elseif ($properties[$i]["Type"] -eq "Hidden") {
                continue
            } else {
                $displayValue = $properties[$i]["Value"]
            }
            Write-Host ("{0}. {1} ({2})" -f ($i + 1), $properties[$i]["Name"], $displayValue)
        }

        Write-Host ("{0}. Save and Exit" -f ($properties.Count + 1))

        $input = Read-Host "Choose an option (1-$($properties.Count + 1)):"
        [int]::TryParse($input, [ref]$option)

        if ($option -eq ($properties.Count + 1)) {
            # Save and Exit
            $SetName = & $pluginName -FunctionName "GetFullName"
            SavePluginPropertiesToFile -pluginName $SetName -properties $properties
            return $properties
        } elseif ($option -gt 0 -and $option -le $properties.Count) {
            # Update property value based on its type
            Write-Host $properties[$option - 1]["Type"]
            switch ($properties[$option - 1]["Type"]) {
                "Boolean" { $properties[$option - 1]["Value"] = -not $properties[$option - 1]["Value"] }
                "String" {
                    $newValue = Read-Host "Enter a new value for $($properties[$option - 1]['Name'])"
                    $properties[$option - 1]["Value"] = $newValue
                }
                "Int" {
                    $newValue = Read-Host "Enter a new value for $($properties[$option - 1]['Name'])"
                    $properties[$option - 1]["Value"] = $newValue
                }
                "Array" {
                    $arrayValues = $properties[$option - 1]["Value"]
                    Write-Host "Available options:"
                    for ($i = 0; $i -lt $arrayValues.Count; $i++) {
                        Write-Host ("{0}. {1}" -f ($i + 1), $arrayValues[$i])
                    }
                    $selected = Read-Host "Choose an option (1-$($arrayValues.Count)):"
                    if ($selected -gt 0 -and $selected -le $arrayValues.Count) {
                        $linkedProperty = $properties[$option - 1]["Link"]
                        $properties | Where-Object { $_["Name"] -eq $linkedProperty } | ForEach-Object { $_["Value"] = $selected - 1 }
                    } else {
                        Write-Host "Invalid option"
                    }
                }
            }
        } else {
            Write-Host "Invalid option"
        }
    }
}

function ShowPluginSettings {
    Write-Host "Plugin Settings:" -ForegroundColor Green
    $foundPlugins = @()
    $pluginFiles = Get-ChildItem -Path ".\plugins" -Filter "*.ps1" | Sort-Object Name
    $pluginsByType = @{}

    foreach ($pluginFile in $pluginFiles) {
        # Call the GetConfigurable function from the plugin file
        $pluginConfigurable = & $pluginFile.FullName -FunctionName "GetConfigurable"

        if ($pluginConfigurable -eq "True") {
            # Call the GetFullName function from the plugin file
            $pluginType = & $pluginFile.FullName -FunctionName "GetPluginType"

            if (-not $pluginsByType.ContainsKey($pluginType)) {
                $pluginsByType[$pluginType] = @()
            }

            $pluginsByType[$pluginType] += $pluginFile
        }
    }

    foreach ($pluginType in $pluginsByType.Keys) {
        $pluginName = GetPluginNameFromType -PluginType $pluginType
        Write-Host ("{0} Plugins:" -f $pluginName) -ForegroundColor Yellow
        $plugins = $pluginsByType[$pluginType] | Sort-Object { (GetProperty -properties (& $_.FullName -FunctionName "GetProperties") -propertyName "Order") }

        for ($i = 0; $i -lt $plugins.Count; $i++) {
            $foundPlugins += $plugins[$i]
            $pluginName = & $plugins[$i].FullName -FunctionName "GetFullName"
            $pluginProps = & $plugins[$i].FullName -FunctionName "GetProperties"
            $pluginEnabled = GetProperty -properties $pluginProps -propertyName "Enabled"
            $pluginOrder = GetProperty -properties $pluginProps -propertyName "Order"
            Write-Host ("{0}. {1} ({2}) [Order: {3}]" -f ($foundPlugins.Count), $pluginName, $pluginEnabled, $pluginOrder)
        }
    }

    return $foundPlugins
}


function ConfigurePlugin {
    Param(
        [string]$pluginName
    )

    $pluginProps = & $pluginName -FunctionName "GetProperties"
    $configuredProperties = ConfigurePluginMenu -pluginName $pluginName -properties $pluginProps
}

while ($true) {
    ShowOptions
    $option = Read-Host "Choose an option (1-10):"

    switch ($option) {
        1 {
            ShowLocalModels
            $Settings.model = Read-Host "Enter the model filename"
        }
        2 { $Settings.pause = if ($Settings.pause -eq 'y') { 'n' } else { 'y' } }
        3 { $Settings.seed = Read-Host "Enter the seed value (leave empty to use seed created on start, or '0' for random every time)" }
        4 { $Settings.LoopCount = Read-Host "Enter the Loop Count (leave empty for infinite)" }
        5 { $Settings.UseChatGPT = -not $Settings.UseChatGPT }
        6 { $Settings.OpenAIKey = Read-Host "Enter your OpenAI API Key" }
        7 {
            ShowOpenAIModels
            $modelIndex = Read-Host "Enter the number of the model you want to use (1-$(($oaModels.Count)))"
            $Settings.OpenAiModel = $oaModels[$modelIndex - 1]
        }
        8 { $Settings.Debug = -not $Settings.Debug }
        9 {
            $pluginFiles = ShowPluginSettings
            $pluginIndex = Read-Host "Enter the number of the plugin you want to configure (1-$($pluginFiles.Count))"
            if ($pluginIndex -and $pluginIndex -ge 1 -and $pluginIndex -le $pluginFiles.Count) {
                ConfigurePlugin -pluginName $pluginFiles[$pluginIndex - 1].FullName
            } else {
                Write-Host "Invalid plugin selection"
            }
        }
        10 { return }
        default { Write-Host "Invalid option" }
    }

    # Save the updated settings
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
}
