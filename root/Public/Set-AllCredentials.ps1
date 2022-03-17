Function Set-AllCredentials($togglePwRnd, $togglePwInd)
{
    $uniqueRandom = $false

    # Set the current database to modify depending on the active tab
    Switch ($Global:tabControl.SelectedItem.Name)
    {
        "tabUser"
        {
            $dbCurrent = $Global:dbUser
            $Global:setNewPswdBtn.IsEnabled = $false
            $Global:pwdBoxNew1.IsEnabled = $false
            $Global:pwdBoxNew2.IsEnabled = $false
            $Global:togglePwRnd.IsEnabled = $false
            
            # If manual password will be set
            If ($togglePwRnd.IsChecked -eq $false)
            {
                # Take the value from the first passwordbox
                $password = $pwdBoxNew1.SecurePassword
            }
            # If random password will be set
            else
            {
                # Check if for each account a different value will be set
                If ($togglePwInd.IsChecked -eq $true)
                {
                    $uniqueRandom = $true
                }
                $password = $Global:syncHash.randomPassword 
            }
        }
        "tabAdmin"
        {

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
        if ((!($userObject.accountStatus -eq "Healthy" -or $userObject.accountStatus -eq "Verification required")) -or $userObject.IsChecked -eq $false -or ($userObject.pswdVer -eq "") -or $userObject.pswdNew -ne "")
        {
            Write-Host "Set-Credentials: Skipped "$userObject.samAccount" in "$userObject.domainDisplayName
            continue
        }
        else
        {
            # Test Credentials of current user, creates button depending on outcome and saves the button reference
            If ((Set-Credentials -Password $password -Random $uniqueRandom -userObject $userObject -WhatIf $true) -eq $true)
            {
                $userObject.pswdSetBtnText = "Password set"
                $userObject.pswdSetBtnEnabled = $false
                $Global:btnCopyToClip.IsEnabled = $true

                Switch ($Global:tabControl.SelectedItem.Name)
                {
                    "tabUser"
                    {
                        #$userObject.pswdSetBtnVisible = "Visible"
                    }
                    "tabAdmin"
                    {}
                    "tabOffboarding"
                    {
                    }
                }
            }
            else
            {
                $userObject.IsEnabled = $false
                $userObject.IsChecked = $false
            }
        }
        $Global:userListView.Items.Refresh()
    }    
}