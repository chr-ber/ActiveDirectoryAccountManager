Function Set-NewPasswordOverlay
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $dataContext
    )

    $dialogSettings = New-Object MahApps.Metro.Controls.Dialogs.LoginDialogSettings
    $dialogSettings.ShouldHideUsername = $true
    $dialogSettings.EnablePasswordPreview = $true
    $dialogSettings.AffirmativeButtonText = "Set Password"
    $dialogSettings.NegativeButtonVisibility = "Visible"
    $dialogSettings.PasswordWatermark = "enter new password"

    $domainUser = $dataContext.domainBase + "\" + $dataContext.samAccount
    $message = "Enter new password for " + $dataContext.domainName
    
    $Global:dialogManager = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($syncHash.Window, $message, "$domainUser", $dialogSettings)
    If ($dialogManager.SecurePassword.Length -eq 0)
    {
        return
    }
    elseif ($dialogManager.SecurePassword.Length -lt 8)
    {
        Set-MessageOverlay -msgHeader "Password not long enough." -msgText "Password needs to be at least 8 characters long"
        Set-PasswordOverlay $dataContext
        return
    }

    # If valid password has been entered
    While ((Set-Credentials -Password $dialogManager.SecurePassword -userObject $dataContext) -eq $false)
    {
        Set-MessageOverlay -msgHeader "Password was not accepted." -msgText "This is caused by one of the following reasons:`r`n`r`n`tComplexity - A minimum of 8 characters and at least one special or number characters are required`r`n`tHistory - Password has already been used in the past"
        Set-NewPasswordOverlay $dataContext
        return       
    }

    $dataContext.pswdSetBtnText = "Password set"
    $dataContext.pswdSetBtnEnabled = $false
    # Enable the checkbox and activate it
    $dataContext.IsEnabled = $true
    $dataContext.IsChecked = $true
    # Set password for specific user object
    $dataContext.pswdVer = $dialogManager.SecurePassword
    # Refresh listview
    $Global:userListView.Items.Refresh()
}