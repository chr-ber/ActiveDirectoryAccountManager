Function Set-AllCredentials() {
    # Set the current database to modify depending on the active tab
    Switch ($Global:tabControl.SelectedItem.Name) {
        "tabUser" {
            $dbCurrent = $Global:dbUser
        }
        "tabAdmin" {

        }
    }

    foreach ($userObject in $dbCurrent) {
        # Skip empty objects
        if (!($userObject.domainName)) {
            continue
        }
        # Skipps loop if the account is in a bad state, pswd has already been set or the account is not checked
        if ((!($userObject.accountStatus -eq "Healthy" -or $userObject.accountStatus -eq "Verification required")) -or $userObject.IsChecked -eq $false -or ($userObject.pswdVer -eq "")) {
            Write-Host "Set-Credentials: Skipped "$userObject.samAccount" in "$userObject.domainName
            continue
        }
        else {
            # Test Credentials of current user, creates button depending on outcome and saves the button reference
            If ((Set-Credentials $global:pswdCurrent $userObject) -eq $true) {
                $userObject.pswdSetBtnText = "Password set"
                $userObject.pswdSetBtnEnabled = $false
                $userObject.pswdVer = $global:pswdCurrent

                Switch ($Global:tabControl.SelectedItem.Name) {
                    "tabUser" {
                        #$userObject.pswdSetBtnVisible = "Visible"
                    }
                    "tabAdmin"
                    {}
                    "tabOffboarding" {
                    }
                }
            }
            else {
                $userObject.IsEnabled = $false
                $userObject.IsChecked = $false
            }
        }
        $Global:userListView.Items.Refresh()
        $Global:offboardingListView.Items.Refresh()
    }    
}