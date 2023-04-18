function Get-Seed {
    param ([string]$Output)
    $SeedRegex = "main: seed = (\d+)"
    if ($Output -match $SeedRegex) {
        return $Matches[1]
    }
    return $null
}

$Settings.seed = Get-Seed -Output $Output

function Get-Response {
    param ([string]$Output)
    $ResponseRegex1 = "repeat_penalty\s*=\s*\d+\.\d+\s*\n\n(.+?)(?=\n\[end of text\])"
    $ResponseRegex2 = "main:    total time.*\n(.+)"

    $response = ""

    if ($Output -match $ResponseRegex1) {
        $response += $Matches[1]
    }

    if ($Output -match $ResponseRegex2) {
        if ($response -ne "") {
            $response += "`n"
        }
        $response += $Matches[1]
    }

    return $response
}

$response = Get-Response -Output $Output


