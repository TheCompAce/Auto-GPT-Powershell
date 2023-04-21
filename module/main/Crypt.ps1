function Encrypt-String {
    Param(
        [string]$InputString,
        [byte[]]$Key,
        [byte[]]$IV
    )

    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = $Key
    $aes.IV = $IV

    $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
    $msEncrypt = New-Object System.IO.MemoryStream
    $csEncrypt = New-Object System.Security.Cryptography.CryptoStream($msEncrypt, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $swEncrypt = New-Object System.IO.StreamWriter($csEncrypt)

    $swEncrypt.Write($InputString)
    $swEncrypt.Dispose()
    $csEncrypt.Dispose()
    $msEncrypt.Dispose()

    $encrypted = $msEncrypt.ToArray()
    return [Convert]::ToBase64String($encrypted)
}

function Decrypt-String {
    Param(
        [string]$InputString,
        [byte[]]$Key,
        [byte[]]$IV
    )

    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = $Key
    $aes.IV = $IV

    $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
    $cipherText = [Convert]::FromBase64String($InputString)

    $msDecrypt = New-Object System.IO.MemoryStream
    $msDecrypt.Write($cipherText, 0, $cipherText.Length)
    $msDecrypt.Position = 0

    $csDecrypt = New-Object System.Security.Cryptography.CryptoStream($msDecrypt, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
    $srDecrypt = New-Object System.IO.StreamReader($csDecrypt)

    $decrypted = $srDecrypt.ReadToEnd()
    $srDecrypt.Dispose()
    $csDecrypt.Dispose()
    $msDecrypt.Dispose()

    return $decrypted
}

function Get-UserSID {
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return $user.User.Value
}

function Get-UserSpecificKey {
    $sid = Get-UserSID
    $sidBytes = [System.Text.Encoding]::UTF8.GetBytes($sid)

    $hashAlgorithm = New-Object System.Security.Cryptography.SHA256Managed
    $key = $hashAlgorithm.ComputeHash($sidBytes)

    return $key
}

function Get-RandomIV {
    $random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $iv = New-Object byte[](16)
    $random.GetBytes($iv)
    return $iv
}


function Encrypt-String-Auto {
    param (
        [Parameter(Mandatory=$true)][string]$InputString
    )

    $key = Get-UserSpecificKey
    $iv = Get-RandomIV

    # Convert any string to Base64
    $inputStringBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputString))

    $encryptedText = Encrypt-String -InputString $inputStringBase64 -Key $key -IV $iv

    # Concatenate the IV with the encrypted text
    $combinedEncryptedText = [Convert]::ToBase64String($iv) + "|" + $encryptedText
    return $combinedEncryptedText
}


function Decrypt-String-Auto {
    param (
        [Parameter(Mandatory=$true)][string]$InputString
    )

    # Separate the IV from the encrypted text
    $parts = $InputString.Split('|')
    $iv = [Convert]::FromBase64String($parts[0])
    $encryptedText = $parts[1]

    $key = Get-UserSpecificKey

    $decryptedTextBase64 = Decrypt-String -InputString $encryptedText -Key $key -IV $iv

    # Convert the decrypted base64 string back to the original string
    $decryptedText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($decryptedTextBase64))
    return $decryptedText
}

