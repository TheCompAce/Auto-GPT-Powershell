function Invoke-StableDiff {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    $exeStr = PrepareRequestBody -scheme $settings.LocalGPTPath -system $system -user $prompt -seed $settings.seed
    Write-Host $exeStr
    $currentFolder = Get-Location
    Write-Host "Current folder: $currentFolder"

    $argArray = @( )

    $argRegex = '(?<=\s|^)[^"\s]+(?=\s|$)|"(?:\\"|[^"])+?(?<!\\)"'
    $matches = [regex]::Matches($exeStr, $argRegex)

    foreach ($match in $matches) {
        $argArray += $match.Value
    }

    $exePath = $argArray[0]
    $argArray = $argArray | Select-Object -Skip 1

    $argString = [string]::Join(' ', $argArray)

    $tempOutputFile = New-TemporaryFile
    # Run the executable with the arguments string and redirect output to the temporary file
    Start-Process -FilePath "`"$exePath`"" -ArgumentList $argString -RedirectStandardOutput $tempOutputFile -NoNewWindow -Wait

    $response = Get-Content -Path $tempOutputFile -Raw
    Remove-Item -Path $tempOutputFile.FullName -Force -ErrorAction SilentlyContinue

    return $response
}
