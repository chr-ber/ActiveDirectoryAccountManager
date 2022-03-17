Function Set-PasswordOverlay
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $dataContext
    )

    $dialogSettings = New-Object MahApps.Metro.Controls.Dialogs.LoginDialogSettings
    $dialogSettings.ShouldHideUsername = $true
    $dialogSettings.EnablePasswordPreview = $true
    $dialogSettings.AffirmativeButtonText = "Validate Password"
    $dialogSettings.NegativeButtonVisibility = "Visible"
    $dialogSettings.PasswordWatermark = "domain password"

    $domainUser = $dataContext.domainName + "\" + $dataContext.samAccount
    $message = "Enter your credentials for " + $dataContext.domainDisplayName
    
	$Global:dialogManager = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($syncHash.Window,$message,"$domainUser",$dialogSettings)
    If($dialogManager.SecurePassword.Length -eq 0)
    {
        return
    }
    elseif($dialogManager.SecurePassword.Length -lt 8)
    {
        Set-MessageOverlay -msgHeader "Password not long enough." -msgText "Password needs to be at least 8 characters long"
        Set-PasswordOverlay $dataContext
        return
    }

    # If valid password has been entered
    While((Test-Credentials $dialogManager.SecurePassword $dataContext $false) -eq $false)
    {
        Set-MessageOverlay -msgHeader "Password was not accepted." -msgText "Please make sure you are using the correct password for this account."
        Set-PasswordOverlay $dataContext
        return       
    }

    $dataContext.pswdVerifyBtnText = "Password accepted"
    $dataContext.pswdVerifyBtnEnabled = $false
    # Enable the checkbox and activate it
    $dataContext.IsEnabled = $true
    $dataContext.IsChecked = $true
    # Set password for specific user object
    $dataContext.pswdVer = $dialogManager.SecurePassword
    # Refresh listview
    $Global:userListView.Items.Refresh()
    $Global:offboardingListView.Items.Refresh()
}