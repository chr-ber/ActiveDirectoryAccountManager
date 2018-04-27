Function Get-PasswordComplexity
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password
    )
    # Password length must be 8 or more
    if ($password.Length -lt 8)
    {
        #Write-Host "Password complexity test failed - password is not long enough"
        return $false
    }
    # Checks if password has at least one word character
    if (([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) -NotMatch '\w')
    {
        #Write-Host "Password complexity test failed - no word character in password"
        return $false
    }
    # Checks if password has at least one number or special character
    if (([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) -match '\d'  )
    {
        #Write-Host "Password complexity test succeeded"
        return $true
    }
    elseif (([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) -match '[-!$²³%^&§*()_[!#*$%^&*@()_+|~=`{}[\]:";<>?,.\/]'  )
    {
        #Write-Host "Password complexity test succeeded"
        return $true
    }
    #Write-Host "Password complexity test failed - no number or special character in password"
    return $false
}