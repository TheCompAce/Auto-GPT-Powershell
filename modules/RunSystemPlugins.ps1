$InputPlugins = Get-ChildItem -Path ".\plugins" -Filter "*_System_Format.ps1" | Sort-Object Name
foreach ($Plugin in $InputPlugins) {
    $startSystem = . $Plugin.FullName -system $startSystem
}
