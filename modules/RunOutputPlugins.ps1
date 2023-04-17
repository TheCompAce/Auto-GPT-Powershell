$OutputPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_Output_Format.ps1" | Sort-Object Name
foreach ($Plugin in $OutputPlugins) {
    $prompt = . $Plugin.FullName -prompt $prompt -response $response
}
