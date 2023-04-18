$InputPlugins = GetPluginsOfType -PluginType "2"

for ($i = 0; $i -lt $InputPlugins.Count; $i++) {
    $properties = & $InputPlugins[$i].FullName -FunctionName "GetProperties"
    $enabled = GetProperty -properties $properties -propertyName "Enabled"
    
    if ($enabled) {
        $prompt = & $InputPlugins[$i].FullName -FunctionName "Run" -ArgumentList $prompt
    }
}