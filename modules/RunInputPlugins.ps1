$InputPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_Input_Format.ps1" | Sort-Object Name
foreach ($Plugin in $InputPlugins) {
    $prompt = . $Plugin.FullName -prompt $prompt
}
