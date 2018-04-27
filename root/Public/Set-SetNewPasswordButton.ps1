Function Set-SetNewPasswordButton
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $button,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password1,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password2
    )

    If ((Get-PasswordComplexity $password1) -eq $true -and (Get-PasswordIdentical $password1 $password2) -eq $true)
    {
        $button.IsEnabled = $true
    }
    else
    {
        $button.IsEnabled = $false
    }

}