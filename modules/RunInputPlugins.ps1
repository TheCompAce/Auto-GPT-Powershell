$InputPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_Input_Format.ps1" | Sort-Object { [int]($_.Name -replace '\D+(\d+).*', '$1') }
foreach ($Plugin in $InputPlugins) {
    $prompt = . $Plugin.FullName -prompt $prompt
}
