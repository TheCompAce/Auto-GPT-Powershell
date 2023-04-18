function Get-UniqueFilename {
    param (
        [string]$filename,
        [string]$folder
    )

    $fileInfo = Get-Item -Path $filename -ErrorAction SilentlyContinue
    if ($null -eq $fileInfo) {
        return $filename
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
            return $prop.Value
        }
    }

    return $null
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

function ConfigurePluginMenu {
    Param(
        [string]$pluginName,
        [array]$properties
    )

    while ($true) {
        Write-Host "Plugin Configuration:" -ForegroundColor Green

        # Build dynamic menu from properties
        for ($i = 0; $i -lt $properties.Count; $i++) {
            Write-Host ("{0}. {1} ({2})" -f ($i + 1), $properties[$i]["Name"], $properties[$i]["Value"])
        }

        Write-Host ("{0}. Save and Exit" -f ($properties.Count + 1))

        $option = Read-Host "Choose an option (1-$($properties.Count + 1)):"
        
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
            }
        } else {
            Write-Host "Invalid option"
        }
    }
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

function Is-LikelyCode {
    param (
        [string]$code,
        [double]$thresholdPct = 4.0
    )

    $languages = @{
        'common' = @(
            "=", ";", "{", "}", "(", ")", ",", "\"", "&#39;", "/*", "*/", "//", "#", "!", "@", "%", "&", "*", "-", "+",
            ".", "?", "|", "^", "~", ">", "<", "/", ":", "§", "£", "€", "¥", "©", "®", "™", "¶", "•", "†", "‡", "°", "·"
        )
        'html' = @(
            "<", ">", "</", "/>", "<!--", "-->", "<![CDATA[", "]]>", "<!DOCTYPE", "<?xml", "xmlns"
        )
        'css' = @(
            "margin", "padding", "border", "background", "font", "color", "width", "height", "display", "position"
        )
        'javascript' = @(
            "function", "class", "if", "else", "for", "while", "return", "var", "let", "const", "import", "export", "extends", "implements"
        )
        'java' = @(
            "public", "private", "protected", "static", "final", "class", "interface", "extends", "implements", "new", "try", "catch", "throw"
        )
        'csharp' = @(
            "using", "namespace", "public", "private", "protected", "static", "class", "interface", "abstract", "sealed", "override", "virtual", "new", "try", "catch", "throw"
        )
        'cplusplus' = @(
            "#include", "int", "float", "double", "char", "bool", "void", "public", "private", "protected", "static", "class", "namespace", "new", "delete", "try", "catch", "throw"
        )
        'json' = @(
            "{", "}", "[", "]", ":", ","
        )
        'asm' = @(
            "mov", "jmp", "call", "ret", "push", "pop", "add", "sub", "mul", "div", "cmp", "jz", "jnz", "ja", "jb"
        )
    }

    $languageCounts = @{}

    foreach ($language in $languages.Keys) {
        $languageCounts[$language] = 0
        foreach ($keyword in $languages[$language]) {
            $languageCounts[$language] += ([regex]::Matches($code, [regex]::Escape($keyword))).Count
        }
    }

    $totalOccurrences = [double]($languageCounts.Values | Measure-Object -Sum).Sum
    if ($totalOccurrences -eq 0) {
        return $false
    }

    $highestCount = ($languageCounts.Values | Measure-Object -Max).Maximum
    $highestPct = ($highestCount / $totalOccurrences) * 10

    Debug -debugText "Debug: Is-LikelyCode highest percent $($highestPct)."

    return $highestPct -ge $thresholdPct
}

function Is-LikelyNaturalLanguage {
    param (
        [string]$text,
        [double]$thresholdPct = 5.0
    )

    $commonWords = @(
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "I", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "no", "just", "him", "know", "take", "people", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us"
    )

    $wordCounts = 0
    foreach ($word in $commonWords) {
        $wordCounts += ([regex]::Matches($text, "\b$word\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    }

    $totalWords = ([regex]::Matches($text, '\b\w+\b')).Count
    if ($totalWords -eq 0) {
        return $false
    }

    $commonWordsPct = ($wordCounts / $totalWords) * 10

    Debug -debugText "Debug: Is-LikelyNaturalLanguage highest percent $($commonWordsPct)."

    return $commonWordsPct -ge $thresholdPct
}
