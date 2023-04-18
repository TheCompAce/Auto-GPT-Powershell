function New-VectorDB {
    param (
        [string]$path
    )

    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path
    }
}

function Save-Vector {
    param (
        [string]$vectorDBPath,
        [string]$vectorId,
        [string]$vectorName,
        [double[]]$vectorData
    )

    $vector = @{
        id   = $vectorId
        name = $vectorName
        data = $vectorData
    }

    $vectorJson = $vector | ConvertTo-Json
    $filename = Join-Path $vectorDBPath "$vectorId.json"
    Set-Content -Path $filename -Value $vectorJson
}

function Get-Vector {
    param (
        [string]$vectorDBPath,
        [string]$vectorId
    )

    $filename = Join-Path $vectorDBPath "$vectorId.json"
    if (Test-Path $filename) {
        $vectorJson = Get-Content $filename
        $vector = $vectorJson | ConvertFrom-Json
        return $vector
    }
    return $null
}

function Update-Vector {
    param (
        [string]$vectorDBPath,
        [string]$vectorId,
        [string]$vectorName,
        [double[]]$vectorData
    )

    $vector = Get-Vector -vectorDBPath $vectorDBPath -vectorId $vectorId
    if ($null -ne $vector) {
        $vector.name = $vectorName
        $vector.data = $vectorData
        $vectorJson = $vector | ConvertTo-Json
        $filename = Join-Path $vectorDBPath "$vectorId.json"
        Set-Content -Path $filename -Value $vectorJson
    }
}

function Remove-Vector {
    param (
        [string]$vectorDBPath,
        [string]$vectorId
    )

    $filename = Join-Path $vectorDBPath "$vectorId.json"
    if (Test-Path $filename) {
        Remove-Item $filename
    }
}
