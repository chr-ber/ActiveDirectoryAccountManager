Function Test-AllCredentials()
{
    foreach($userObject in $Global:dbUser)
    {
        # Skipps loop if the account is in a bad state, pswd has already been set or the account is not checked
        if($userObject.accountStatus -ne "Healthy" -and $userObject.accountStatus -ne "Verification required" -and $userObject.IsChecked -eq $false -and ($userObject.pswdVer))
        {
            continue
        }
        else
        {
            # Test Credentials of current user, creates button depending on outcome and saves the button reference
            If((Test-Credentials $global:pswdCurrent $userObject $true) -eq $true)
            {
                $userObject.pswdVerifyBtnText = "Password accepted"
                $userObject.pswdVerifyBtnEnabled = $false
                $userObject.pswdVer = $global:pswdCurrent
            }
            else
            {
                #$userObject.pswdVerifyBtnText = "Password accepted"
                #$userObject.pswdVerifyBtnEnabled = $false
                $userObject.IsEnabled = $false
                $userObject.IsChecked = $false
            }
        }

        $Global:userListView.Items.Refresh() 
    }    
}