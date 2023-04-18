$StartPlugins = GetPluginsOfType -PluginType "0"

for ($i = 0; $i -lt $StartPlugins.Count; $i++) {
    $properties = & $StartPlugins[$i].FullName -FunctionName "GetProperties"
    $enabled = GetProperty -properties $properties -propertyName "Enabled"

    if ($enabled) {
        $prompt = & $StartPlugins[$i].FullName -FunctionName "Run" -ArgumentList $prompt
    }
}