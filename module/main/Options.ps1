# Options.ps1
Param(
    [Parameter(Mandatory=$true)][PSCustomObject]$Settings
)


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
            if ($properties[$i]["Type"] -eq "Temp") { continue }
            if ($properties[$i]["Type"] -eq "Array") {
                $linkedProperty = $properties[$i]["Link"]
                $selectedIndex = GetProperty -properties $properties -propertyName $linkedProperty
                if ($selectedIndex -ne $null) {
                    $displayValue = $properties[$i]["Value"][$selectedIndex]
                } else {
                    $displayValue = "Not set"
                }
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

            # Exclude "Temp" properties
            $pluginProps = $pluginProps | Where-Object { $_.Type -ne "Temp" }

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

function ShowAdvancedOptions {
    Write-Host "Advanced Settings:" -ForegroundColor Green
    Write-Host "1. Local GPT Path ($($Settings.LocalGPTPath))"
    Write-Host "2. Online GPT Path ($($Settings.OnlineGPTPath))"
    Write-Host "3. Use Online GPT ($($Settings.UseOnlineGPT))"
    Write-Host "4. Send only Prompt to GPT ($($Settings.SendOnlyPromptToGPT))"
    Write-Host "5. Set GPT Prompt Scheme (Import File Data)"
    Write-Host "6. Show GPT Prompt Scheme"
    Write-Host "7. Use OpenAI GPT Authentication ($($Settings.UseOpenAIGPTAuthentication))"
    Write-Host "8. Local Text To Image Path ($($Settings.LocalTextToImagePath))"
    Write-Host "9. Online Text To Image Path ($($Settings.OnlineTextToImagePath))"
    Write-Host "10. Use Online Text To Image ($($Settings.UseOnlineTextToImage))"
    Write-Host "11. Send only Prompt to Text To Image ($($Settings.SendOnlyPromptToTextToImage))"
    Write-Host "12. Set Text To Image Prompt Scheme (Import File Data)"
    Write-Host "13. Show Text To Image Prompt Scheme"
    Write-Host "14. Use OpenAI DALLE Authentication ($($Settings.UseOpenAIDALLEAuthentication))"
    Write-Host "15. Set OpenAI API Key"
    Write-Host "16. Exit"
    Write-Host "Note: [system] for System Prompt, [user] for User Prompt, [systemFile] to save System Prompt to a file, [userFile] to save User Prompt to a file, [seed] for sending a seed value, can be used in Paths, and Schemes"
}

function ConfigureAdvancedOptions {
    while ($true) {
        ShowAdvancedOptions
        $option = Read-Host "Choose an option (1-16):"

        switch ($option) {
            1 { $Settings.LocalGPTPath = Read-Host "Enter the Local GPT Path" }
            2 { $Settings.OnlineGPTPath = Read-Host "Enter the Online GPT Path" }
            3 { $Settings.UseOnlineGPT = -not $Settings.UseOnlineGPT }
            4 { $Settings.SendOnlyPromptToGPT = -not $Settings.SendOnlyPromptToGPT }
            5 {
                $GPTPromptSchemeFile = Read-Host "Enter the GPT Prompt Scheme file path"
                try {
                    $Settings.GPTPromptScheme = Get-Content -Path $GPTPromptSchemeFile -Raw
                } catch {
                    Write-Host "Error: Unable to set GPT Prompt Scheme file path." -ForegroundColor Red
                }
            }
            6 { Write-Host "GPT Prompt Scheme:" -ForegroundColor Green; Write-Host $Settings.GPTPromptScheme }
            7 { $Settings.UseOpenAIGPTAuthentication = -not $Settings.UseOpenAIGPTAuthentication }
            8 { $Settings.LocalTextToImagePath = Read-Host "Enter the Local Text To Image Path" }
            9 { $Settings.OnlineTextToImagePath = Read-Host "Enter the Online Text To Image Path" }
            10 { $Settings.UseOnlineTextToImage = -not $Settings.UseOnlineTextToImage }
            11 { $Settings.SendOnlyPromptToTextToImage = -not $Settings.SendOnlyPromptToTextToImage }
            12 {
                $TextToImagePromptSchemeFile = Read-Host "Enter the Text To Image Prompt Scheme file path"
                try {
                    $Settings.TextToImagePromptScheme = Get-Content -Path $TextToImagePromptSchemeFile -Raw
                } catch {
                    Write-Host "Error: Unable to set Image Prompt Scheme file path." -ForegroundColor Red
                }
            }
            13 { Write-Host "Text To Image Prompt Scheme:" -ForegroundColor Green; Write-Host $Settings.TextToImagePromptScheme }
            14 { $Settings.UseOpenAIDALLEAuthentication = -not $Settings.UseOpenAIDALLEAuthentication }
            15 { 
                    $optData = Read-Host "Enter the Online API Key" 
                    $encData = Encrypt-String-Auto -InputString $optData
                    $Settings.OnlineAPIKey = $encData
                }
            16 { return }
            default { Write-Host "Invalid option" }
        }

        # Save the updated settings
        $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
    }
}



function ConfigureStableLMIntegration {
    $useOpenAI = Read-Host "Do you want to use StableLM (Uses 'StableLM/run.bat' and please follow the setup.bat for setup of StableLM.) ? (y/n)"
    if ($useOpenAI -eq "y") {
        Write-Host "StableLM Model List:" -ForegroundColor Green
        $slmModels = @("stablelm-base-alpha-3b", "stablelm-tuned-alpha-3b", "stablelm-base-alpha-7b", "stablelm-tuned-alpha-7b")
        $slmType = @(0, 0, 1, 1)

        for ($i = 0; $i -lt $slmModels.Count; $i++) {
            Write-Host "$($i + 1). $($slmModels[$i])"
        }

        $selectedIndex = Read-Host "Select a model from the list (1-$($oaModels.Count))"
        $selectedModel = $oaModels[$selectedIndex - 1]
        $selectedType = $slmType;


        $selectedChunkSize = Read-Host "How many Chunks for the Prompt? (64)"
        $selectedMaxTokens = Read-Host "How many Max Tokens for Output? (64)"

        $Settings.UseOnlineGPT = $false

        if ($slmType -eq 0) {
            $comdStr = ".\StableLM\run.bat -c $($selectedChunkSize) -t $($selectedMaxTokens) -m $($slmModels) -clear -p [user]"
            $Settings.SendOnlyPromptToGPT = $true;
        } else {
            $comdStr = ".\StableLM\run.bat -c $($selectedChunkSize) -t $($selectedMaxTokens) -m $($slmModels) -clear -s [system] -u [user]"
            $Settings.SendOnlyPromptToGPT = $false;
            $Settings.GPTPromptScheme = "<|SYSTEM|>[system]<|USER|>[user]<|ASSISTANT|>"
        }

        $Settings.LocalGPTPath = $comdStr;
    }
}

function ConfigureDallEIntegration {
    $useDALLE = Read-Host "Do you want to use DALLE? (y/n)"
    if ($useDALLE -eq "y") {
        $Settings.UseOpenAIDALLEAuthentication = $true
        $Settings.UseOnlineTextToImage = $true
        $Settings.OnlineTextToImagePath = "https://api.openai.com/v1/images/generations"

        $sizeOptions = @("256x256", "512x512", "1024x1024")

        for ($i = 0; $i -lt $sizeOptions.Count; $i++) {
            Write-Host "$($i + 1). $($sizeOptions[$i])"
        }

        $sizeIndex = Read-Host "Select a size from the list (1-$($sizeOptions.Count))"
        $selectedSize = $sizeOptions[$sizeIndex - 1]

        $data = @{
            "prompt" = "[user]"
            "n"      = 1
            "size"   = $selectedSize
        }

        $settings.TextToImagePromptScheme = $data | ConvertTo-Json -Depth 10
    }
}

function ConfigureOpenAIIntegration {
    $useOpenAI = Read-Host "Do you want to use OnlineAI ChatGPT? (y/n)"
    if ($useOpenAI -eq "y") {
        $changeKey = Read-Host "Do you want to change your OpenAI Key? (y/n)"
        if ($changeKey -eq "y") {
            $optData = Read-Host "Enter your OpenAI Key"
            $encData = Encrypt-String-Auto -InputString $optData
            $Settings.OnlineAPIKey = $encData
        }

        Write-Host "OpenAI Model List:" -ForegroundColor Green

        for ($i = 0; $i -lt $oaModels.Count; $i++) {
            Write-Host "$($i + 1). $($oaModels[$i])"
        }

        $selectedIndex = Read-Host "Select a model from the list (1-$($oaModels.Count))"
        $selectedModel = $oaModels[$selectedIndex - 1]

        $Settings.UseOpenAIGPTAuthentication = $true
        $Settings.UseOnlineGPT = $true
        $Settings.SendOnlyPromptToGPT = $false

        if ($selectedModel -eq "text-davinci-003") {
            $Settings.OnlineGPTPath = "https://api.openai.com/v1/completions"
            $data = @{
                "model"        = "text-davinci-003"
                "prompt"       = "[system] [user]"
                "max_tokens"   = 50
                "n"            = 1
                "stop"         = "\n"
                "temperature"  = 0.7
            }

            $Settings.GPTPromptScheme = $data | ConvertTo-Json -Depth 10
        } else {
            $Settings.OnlineGPTPath = "https://api.openai.com/v1/chat/completions"
            $data = @{
                "model"    = $selectedModel
                "messages" = @(
                    @{
                        "role"    = "system"
                        "content" = "[system]"
                    },
                    @{
                        "role"    = "user"
                        "content" = "[user]"
                    }
                )
            }

            $Settings.GPTPromptScheme = $data | ConvertTo-Json -Depth 10
        }


        ConfigureDallEIntegration

        # Save the updated settings
        $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
    }
}

function ShowOptions {
    Write-Host "Basic Settings:" -ForegroundColor Green
    Write-Host "1. Toggle Pause ($($Settings.pause))"
    Write-Host "2. Change Seed ($($Settings.seed))"
    Write-Host "3. Change Loop Count ($($Settings.LoopCount))"
    Write-Host "4. Setup OpenAI"
    Write-Host "5. Setup StableLM"
    Write-Host "6. Setup DallE"
    Write-Host "7. Plugin Settings"
    Write-Host "8. Advanced Settings"
    Write-Host "9. Turn On Debug ($($Settings.Debug))"
    Write-Host "10. Exit"
}


while ($true) {
    ShowOptions
    $option = Read-Host "Choose an option (1-8):"

    switch ($option) {
        1 { $Settings.pause = if ($Settings.pause -eq 'y') { 'n' } else { 'y' } }
        2 { $Settings.seed = Read-Host "Enter the seed value (leave empty to use seed created on start, or '0' for random every time)" }
        3 { $Settings.LoopCount = Read-Host "Enter the Loop Count (leave empty for infinite)" }
        4 { ConfigureOpenAIIntegration }
        5 { ConfigureStableLMIntegration }
        6 { ConfigureDallEIntegration }
        7 {
            $pluginFiles = ShowPluginSettings
            $pluginIndex = 0
            $input = Read-Host "Enter the number of the plugin you want to configure (1-$($pluginFiles.Count))"
            [int]::TryParse($input, [ref]$pluginIndex)

            if ($pluginIndex -and $pluginIndex -ge 1 -and $pluginIndex -le $pluginFiles.Count) {
                ConfigurePlugin -pluginName $pluginFiles[$pluginIndex - 1].FullName
            } else {
                Write-Host "Invalid plugin selection"
            }
        }
        
        8 { ConfigureAdvancedOptions }
        9 { $Settings.Debug = -not $Settings.Debug }
        10 { return }
        default { Write-Host "Invalid option" }
    }

    # Save the updated settings
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path "settings.json"
}

