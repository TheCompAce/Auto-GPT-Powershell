$OutputPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_Output_Format.ps1" | Sort-Object { [int]($_.Name -replace '\D+(\d+).*', '$1') }
foreach ($Plugin in $OutputPlugins) {
    $prompt = . $Plugin.FullName -prompt $prompt -response $response
}
