function GetPhaseSection {
    param(
        [Array]$Phases,
        [string]$name
    )
    foreach ($phase in $Phases) {
        if ($phase.Name -eq $name) {
            return $phase
        }
    }

    return $null
}

function SavePhaseSection {
    param(
        [Array]$Phases,
        $phase
    )

    for ($i = 0; $i -lt $Phases.Count; $i++) {
        if ($Phases[$i].Name -eq $name) {
            $Phases[$i] = $phase
            return $Phases
        }
    }

    return $null
}