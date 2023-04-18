$SystemPlugins = GetPluginsOfType -PluginType "1"

for ($i = 0; $i -lt $SystemPlugins.Count; $i++) {
    $properties = & $SystemPlugins[$i].FullName -FunctionName "GetProperties"
    $enabled = GetProperty -properties $properties -propertyName "Enabled"
    
    if ($enabled) {
        $prompt = & $SystemPlugins[$i].FullName -FunctionName "Run" -ArgumentList $prompt
    }
}