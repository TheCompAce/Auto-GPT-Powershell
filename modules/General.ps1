function Get-UniqueFilename {
    param (
        [string]$filename
    )

    $fileInfo = Get-Item -Path $filename -ErrorAction SilentlyContinue
    if ($null -eq $fileInfo) {
        return $filename
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $extension = [System.IO.Path]::GetExtension($filename)

    $number = 1
    while ($true) {
        $newFilename = "{0}({1}){2}" -f $baseName, $number, $extension
        if (-not (Test-Path $newFilename)) {
            return $newFilename
        }
        $number++
    }
}
