function Is-LikelyCode {
    param (
        [string]$code,
        [double]$thresholdPct = 4.0
    )

    $languages = @{
        'common' = @(
            "=", ";", "{", "}", "(", ")", ",", "\"", "&#39;", "/*", "*/", "//", "#", "!", "@", "%", "&", "*", "-", "+",
            ".", "?", "|", "^", "~", ">", "<", "/", ":", "§", "£", "€", "¥", "©", "®", "™", "¶", "•", "†", "‡", "°", "·"
        )
        'html' = @(
            "<", ">", "</", "/>", "<!--", "-->", "<![CDATA[", "]]>", "<!DOCTYPE", "<?xml", "xmlns"
        )
        'css' = @(
            "margin", "padding", "border", "background", "font", "color", "width", "height", "display", "position"
        )
        'javascript' = @(
            "function", "class", "if", "else", "for", "while", "return", "var", "let", "const", "import", "export", "extends", "implements"
        )
        'java' = @(
            "public", "private", "protected", "static", "final", "class", "interface", "extends", "implements", "new", "try", "catch", "throw"
        )
        'csharp' = @(
            "using", "namespace", "public", "private", "protected", "static", "class", "interface", "abstract", "sealed", "override", "virtual", "new", "try", "catch", "throw"
        )
        'cplusplus' = @(
            "#include", "int", "float", "double", "char", "bool", "void", "public", "private", "protected", "static", "class", "namespace", "new", "delete", "try", "catch", "throw"
        )
        'json' = @(
            "{", "}", "[", "]", ":", ","
        )
        'asm' = @(
            "mov", "jmp", "call", "ret", "push", "pop", "add", "sub", "mul", "div", "cmp", "jz", "jnz", "ja", "jb"
        )
        'ruby' = @(
            "def\s+\w+\s*\(", "class\s+\w+", "module\s+\w+", "if\s+\w+", "else", "elsif\s+\w+", "for\s+\w+\s+in\s+\w+", "while\s+\w+", "until\s+\w+", "case\s+\w+", "when\s+\w+", "return", "begin", "rescue", "ensure", "end"
        )
        'go' = @(
            "package\s+\w+", "import\s+\(.*\)", "func\s+\w+\s*\(", "type\s+\w+\s+struct", "const\s+\w+", "var\s+\w+", "interface\s+\w+", "if\s+\w+", "else", "for\s+\w+", "range\s+\w+", "switch\s+\w+", "case\s+\w+", "return", "defer", "go\s+\w+", "select\s+\w+", "default"
        )

        'swift' = @(
            "import\s+\w+", "func\s+\w+\s*\(", "class\s+\w+", "struct\s+\w+", "enum\s+\w+", "protocol\s+\w+", "extension\s+\w+", "if\s+\w+", "else", "for\s+\w+\s+in\s+\w+", "while\s+\w+", "switch\s+\w+", "case\s+\w+", "return", "try", "catch", "throw", "guard\s+\w+", "let\s+\w+", "var\s+\w+", "print\s*\("
        )

        'kotlin' = @(
            "import\s+\w+", "fun\s+\w+\s*\(", "class\s+\w+", "interface\s+\w+", "data\s+class\s+\w+", "val\s+\w+", "var\s+\w+", "if\s+\w+", "else", "for\s+\w+\s+in\s+\w+", "while\s+\w+", "return", "try", "catch", "throw", "when\s*\(", "is\s+\w+", "as\s+\w+"
        )

        'rust' = @(
            "use\s+\w+", "fn\s+\w+\s*\(", "pub\s+\w+", "struct\s+\w+", "enum\s+\w+", "impl\s+\w+", "trait\s+\w+", "const\s+\w+", "let\s+\w+", "mut\s+\w+", "if\s+\w+", "else", "for\s+\w+\s+in\s+\w+", "while\s+\w+", "loop", "match\s+\w+", "return", "unsafe\s+\w+", "mod\s+\w+", "extern\s+\w+", "dyn\s+\w+"
        )

        'lua' = @(
            "local\s+\w+", "function\s+\w+\s*\(", "if\s+\w+", "else", "elseif\s+\w+", "for\s+\w+\s+in\s+\w+", "while\s+\w+", "repeat\s+\w+", "until\s+\w+", "return", "end", "and", "or", "not\s+\w+", "require\s*\(", "module\s*\("
        )
    }

    $languageCounts = @{}

    foreach ($language in $languages.Keys) {
        if ($language -eq "html") {
            # Write-Host $language
        }
        $languageCounts[$language] = 0
        foreach ($keyword in $languages[$language]) {
            $languageCounts[$language] += ([regex]::Matches($code, [regex]::Escape($keyword))).Count
        }
    }


    $totalOccurrences = [double]($languageCounts.Values | Measure-Object -Sum).Sum
    if ($totalOccurrences -eq 0) {
        return $false
    }

    $highestCount = ($languageCounts.Values | Measure-Object -Max).Maximum
    $highestPct = ($highestCount / $totalOccurrences) * 10    

    return $highestPct
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
        if (Is-LikelyCode $line -ge 4.0) {
            $codeLinesCount++
        } else {
            $matches = [regex]::Matches($line, $pattern)
            $matchedTextLength = ($matches | Measure-Object { $_.Length } -Sum).Sum
            $totalTextLength = $line.Length

            if ($totalTextLength -eq 0) {
                continue
            }

            $naturalLanguagePct = ($matchedTextLength / $totalTextLength) * 100

            if ($naturalLanguagePct -ge $thresholdPct) {
                $nlpLinesCount++
            }
        }
    }

    if ($totalLinesCount -eq 0) {
        return $false
    }

    $overallNlpPercentage = ($nlpLinesCount / $totalLinesCount) * 100

    return $overallNlpPercentage
}
