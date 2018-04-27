Function Get-PasswordIdentical
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password1,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password2
    )

    try
    {
        # Decrpyt password and compare complexity
        If (([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password1))) -eq ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password2))))
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch
    {
        Write-Host "Error comparing passwords to be identical"
    }
}