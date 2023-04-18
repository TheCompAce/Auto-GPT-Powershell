function Is-LikelyCode {
    param (
        [string]$code,
        [double]$thresholdPct = 4.0
    )

    $patterns = @{
        'common' = @(
            "=", ";", "{", "}", "(", ")", ",", "\"", "&#39;", "/*", "*/", "//", "#", "!", "@", "%", "&", "*", "-", "+",
            ".", "?", "|", "^", "~", ">", "<", "/", ":", "§", "£", "€", "¥", "©", "®", "™", "¶", "•", "†", "‡", "°", "·"
        )
        'html' = @(
            "<\w+>", "</\w+>", "/>", "<!--", "-->", "<![CDATA[", "]]>", "<!DOCTYPE", "<?xml", "xmlns"
        )
        'css' = @(
            "\w+:\s*[\w\s,#\(\)]+;"
        )
        'javascript' = @(
            "function\s+\w+\s*\(", "class\s+\w+", "if\s*\(.*\)", "else", "for\s*\(.*\)", "while\s*\(.*\)", "return", "var\s+\w+", "let\s+\w+", "const\s+\w+", "import\s+\w+", "export\s+\w+", "extends", "implements"
        )
        'java' = @(
            "public\s+\w+", "private\s+\w+", "protected\s+\w+", "static\s+\w+", "final\s+\w+", "class\s+\w+", "interface\s+\w+", "extends", "implements", "new", "try", "catch", "throw"
        )
        'csharp' = @(
            "using\s+\w+", "namespace\s+\w+", "public\s+\w+", "private\s+\w+", "protected\s+\w+", "static\s+\w+", "class\s+\w+", "interface\s+\w+", "abstract\s+\w+", "sealed\s+\w+", "override\s+\w+", "virtual\s+\w+", "new", "try", "catch", "throw"
        )
        'cplusplus' = @(
            "#include\s+<\w+>", "int\s+\w+", "float\s+\w+", "double\s+\w+", "char\s+\w+", "bool\s+\w+", "void\s+\w+", "public\s+\w+", "private\s+\w+", "protected\s+\w+", "static\s+\w+", "class\s+\w+", "namespace\s+\w+", "new", "delete", "try", "catch", "throw"
        )
        'json' = @(
            "{", "}", "[", "]", ":", ","
        )
        'asm' = @(
            "mov", "jmp", "call", "ret", "push", "pop", "add", "sub", "mul", "div", "cmp", "jz", "jnz", "ja", "jb"
        )
    }

    $patternCounts = @{}

    foreach ($pattern in $patterns.Keys) {
        $patternCounts[$pattern] = 0
        foreach ($regex in $patterns[$pattern]) {
            $patternCounts[$pattern] += ([regex]::Matches($code, $regex)).Count
        }
    }

    $totalOccurrences = [double]($patternCounts.Values | Measure-Object -Sum).Sum
    if ($totalOccurrences -eq 0) {
        return $false
    }

    $highestCount = ($patternCounts.Values | Measure-Object -Max).Maximum
    $highestPct = ($highestCount / $totalOccurrences) * 100

    Debug -debugText "Debug: Is-LikelyCode highest percent $($highestPct)."

    Write-Host $highestPct -ForegroundColor DarkGreen

    return $highestPct -ge $thresholdPct
}



function Is-LikelyNaturalLanguage {
    param (
        [string]$text,
        [double]$thresholdPct = 5.0
    )

    $pattern = "(\b\w+\b[.,;:]?\s*)+"
    $lines = $text -split "\r?\n"
    $nlpLinesCount = 0
    $codeLinesCount = 0
    $totalLinesCount = $lines.Count

    foreach ($line in $lines) {
        if (Is-LikelyCode $line -thresholdPct 4.0) {
            $codeLinesCount++
        } else {
            $matches = [regex]::Matches($line, $pattern)
            $matchedTextLength = ($matches | Measure-Object { $_.Length } -Sum).Sum
            $totalTextLength = $line.Length

            if ($totalTextLength -eq 0) {
                continue
            }

            $naturalLanguagePct = ($matchedTextLength / $totalTextLength) * 100
            Debug -debugText "Debug: Is-LikelyNaturalLanguage percentage for line '$($line)': $($naturalLanguagePct)."

            if ($naturalLanguagePct -ge $thresholdPct) {
                $nlpLinesCount++
            }
        }
    }

    if ($totalLinesCount -eq 0) {
        return $false
    }

    $overallNlpPercentage = ($nlpLinesCount / $totalLinesCount) * 100
    Debug -debugText "Debug: Is-LikelyNaturalLanguage overall percentage: $($overallNlpPercentage)."

    Write-Host $overallNlpPercentage -ForegroundColor Green

    return $overallNlpPercentage -ge $thresholdPct
}
