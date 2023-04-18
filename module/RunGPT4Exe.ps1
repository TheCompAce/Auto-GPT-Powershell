Function Invoke-GPT4ALL {
    param(
        [string]$model,
        [string]$prompt
    )
    
    # Create an array of arguments
    $ExeArgs = @("-m", $model, "-n", "1000", "-c", "4000")
    if (![string]::IsNullOrEmpty($Settings.seed ) -and $Settings.seed -ne "0") {
        $ExeArgs += @("-s", $Settings.seed )
    }

    # Save the prompt to a temporary file
    $tempPromptFile = New-TemporaryFile
    Set-Content -Path $tempPromptFile -Value $prompt

    # Update the -f parameter to use the temporary file
    $ExeArgs += @("-f", "`"$($tempPromptFile.FullName)`"")

    # Run the executable with the arguments array
    # Create a temporary file for the output
    $tempOutputFile = New-TemporaryFile

    # Run the executable with the arguments array and redirect output to the temporary file
    & ".\gpt4all-lora-quantized-win64.exe" $ExeArgs *> $tempOutputFile.FullName

    # Read the content of the temporary file into the $Output variable
    $Output = Get-Content -Path $tempOutputFile.FullName -Raw

    # Add the content of the temporary file to the "system.log"
    Add-Content -Path "system.log" -Value $Output

    # Clean up the temporary output file
    Remove-Item -Path $tempOutputFile.FullName

    # Continue with the rest of the script
    . .\module\ParseOutput.ps1

    # Clean up the temporary file
    Remove-Item -Path $tempPromptFile.FullName

    return $prompt
}