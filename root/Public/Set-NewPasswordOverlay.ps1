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
    While ((Set-Credentials $dialogManager.SecurePassword $dataContext $false) -eq $false)
    {
        Set-MessageOverlay -msgHeader "Password was not accepted." -msgText "Either caused by password complexity or history."
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