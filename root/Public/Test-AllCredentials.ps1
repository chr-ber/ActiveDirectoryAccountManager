﻿Function Test-AllCredentials()
{
    # Set the current database to modify depending on the active tab
    Switch ($Global:tabControl.SelectedItem.Name)
    {
        "tabUser"
        {
            $dbCurrent = $Global:dbUser
            $Global:pwdBoxCur.IsEnabled = $false
            $Global:pwdVerBtn.IsEnabled = $false 
        }
        "tabAdmin"
        {}
        "tabOffboarding"
        {
            $dbCurrent = $Global:dbOffboarding
            $Global:passwordBoxCurrent.IsEnabled = $false
            $Global:btnAdminPswd.IsEnabled = $false
        }
    }

    foreach ($userObject in $dbCurrent)
    {
        # Skip empty objects
        if (!($userObject.domainDisplayName))
        {
            continue
        }
        # Skipps loop if the account is in a bad state, pswd has already been set or the account is not checked
        if ((!($userObject.accountStatus -eq "Healthy" -or $userObject.accountStatus -eq "Verification required")) -or $userObject.IsChecked -eq $false -or ($userObject.pswdVer -ne ""))
        {
            Write-Host "Test-Credentials: Skipped "$userObject.samAccount" in "$userObject.domainDisplayName
            continue
        }
        else
        {
            # Test Credentials of current user, creates button depending on outcome and saves the button reference
            If ((Test-Credentials $global:pswdCurrent $userObject) -eq $true)
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
        $Global:offboardingListView.Items.Refresh()
    }    
}