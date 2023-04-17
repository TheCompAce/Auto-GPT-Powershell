$SystemPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_System_Format.ps1" | Sort-Object { [int]($_.Name -replace '\D+(\d+).*', '$1') }
foreach ($Plugin in $SystemPlugins) {
    $startSystem = . $Plugin.FullName -system $startSystem
}
