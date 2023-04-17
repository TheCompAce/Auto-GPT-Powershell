$StartPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_Start_Format.ps1" | Sort-Object Name
foreach ($Plugin in $StartPlugins) {
    $prompt = . $Plugin.FullName -prompt $prompt
}