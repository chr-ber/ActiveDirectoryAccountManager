Function Reset-App()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $syncHash,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $mode = $Global:tabControl.SelectedItem.Name

    )

    Remove-Variable -Name dbUser -Force -Scope Global
    Remove-Variable -Name dbOffboarding -Force -Scope Global

    # Empty the user databases
    $Global:dbUser = @()
    $Global:dbAdmin = @()    
    $Global:dbOffboarding = @()   

    # Password tab defaults
    $Global:btnSearchAccounts.IsEnabled = $true
    $Global:syncHash.editDB = $false
    $Global:togglePwRnd.IsEnabled = $false
    $Global:togglePwInd.IsEnabled = $false
    $Global:setNewPswdBtn.IsEnabled = $false
    $Global:pwdBoxCur.IsEnabled = $false
    $Global:pwdBoxNew1.IsEnabled = $false
    $Global:pwdBoxNew2.IsEnabled = $false
    $Global:togglePwRnd.IsChecked = $false
    $Global:pwdBoxCur.Password = ""
    $Global:pwdBoxNew1.Password = ""
    $Global:pwdBoxNew2.Password = ""
    $Global:btnCopyToClip.IsEnabled = $false

    # Offboarding tab defaults    
    $Global:syncHash.ticketNumber = ""
    $Global:syncHash.offboardingMessage = ""   
    $Global:userBoxTicket.Text = ""
    $Global:userBoxTicket.IsEnabled = $true
    $Global:userBoxDisable.IsEnabled = $true
    $Global:btnOffboard.IsEnabled = $false
    $Global:btnOffboardToClip.IsEnabled = $false
    $Global:userBoxDisable.Text = ""
    $Global:passwordBoxCurrent.Password = ""
    $Global:passwordBoxCurrent.IsEnabled = $true
    $Global:userBoxTicket.Text = "" 
    
    # Define global random password for session
    $Global:syncHash.randomPassword = Get-RandomPassword -Minimum 12 -Maximum 20

    # Build currentUser boject
    foreach ($domain in $rootConfig)
    {
        for ($i = 0; $i -lt 2; $i ++)
        {
            if ($i -eq 1)
            {
                $Global:dbUser += @([pscustomobject]@{IsEnabled = "true"; IsChecked = "true"; domainName = $domain.domainName; samAccount = ""; displayName = ""; expiresIn = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set current password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; pswdSetBtnText = "Set new password"; pswdSetBtnVisible = "Hidden"; pswdSetBtnEnabled = $true; clipBoardBtnVisible = "Hidden"; pswdNew = ""; dc = $domain.dc; domainBase = $domain.domainBase; officeDomain = $domain.officeDomain; adObject = ""})

            }
            else
            {
                $Global:dbUser += @([pscustomobject]@{IsVisible = "Hidden"; IsEnabled = ""; IsChecked = ""; domainName = ""; samAccount = ""; displayName = ""; expiresIn = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set current password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; pswdSetBtnText = "Set new password"; pswdSetBtnVisible = "Hidden"; pswdSetBtnEnabled = $true; clipBoardBtnVisible = "Hidden"; pswdNew = ""; dc = ""; domainBase = ""; officeDomain = ""; adObject = ""})
            }
        }
    }

    $Global:dbUser = $Global:dbUser | Sort-Object -Property DomainName -Descending

    # Build offboarding object
    foreach ($domain in $rootConfig)
    {

        # For each domain we create an prepared object selectable in the gui and and invisible stock item
        # This is needed since powershell can not modify pscustomobjects asynchronously in PoSh V3 and
        # Is unable to add additional objects from a runspace 
        for ($i = 0; $i -lt 2; $i ++)
        {
            $grpArray = @()

            $offboardingResults = @([PSCustomObject]@{disabled = ""; moved = ""; removeGrps = ""; grpsRemoved = $grpArray })

            if ($i -eq 1)
            {
                $Global:dbOffboarding += @([pscustomobject]@{IsEnabled = "true"; IsChecked = "true"; domainName = $domain.domainName; samAccount = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; dc = $domain.dc; domainBase = $domain.domainBase; officeDomain = $domain.officeDomain; adObject = ""; userAccount = ""; userStatus = ""; userDisplayName = ""; userOu = ""; userMemberOf = ""; userDistName = ""; offboardingResults = $offboardingResults; })

            }
            else
            {
                $Global:dbOffboarding += @([pscustomobject]@{IsVisible = "Hidden"; IsEnabled = ""; IsChecked = ""; domainName = ""; samAccount = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; dc = ""; domainBase = ""; officeDomain = ""; adObject = ""; userAccount = ""; userStatus = ""; userDisplayName = ""; userOu = ""; userMemberOf = ""; userDistName = ""; offboardingText = ""; offboardingResults = $offboardingResults; })
            }
        }
    }

    $Global:dbOffboarding = $Global:dbOffboarding | Sort-Object -Property DomainName -Descending

    
    foreach ($domain in $rootConfig)
    {
        $Global:dbAdmin += @([pscustomobject]@{IsEnabled = "true"; IsChecked = "true"; domainName = $domain.domainName; samAccountAdmin = ""; statusAdmin = ""; samAccountUser = ""; statusUser = ""; pswdVerAdmin = ""; pswdSetUser = ""; pswdVerifyBtnVisible = "Hidden"; dc = $domain.dc; domainBase = $domain.domainBase; officeDomain = $domain.officeDomain; adObjectAdmin = ""; adObjectUser = ""})
    }

    $Global:dbAdmin = $Script:dbAdmin | Sort-Object -Property DomainName -Descending

    # Add pscustomojbect to each listview and refresh the gui
    $Global:userListView.ItemsSource = $Global:dbUser
    $Global:userListView.Items.Refresh()

    $Global:adminListView.ItemsSource = $Global:dbAdmin
    $Global:adminListView.Items.Refresh()

    $Global:offboardingListView.ItemsSource = $Global:dbOffboarding 
    $Global:offboardingListView.Items.Refresh()

}