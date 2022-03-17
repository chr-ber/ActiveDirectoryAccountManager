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
                $Global:dbUser += @([pscustomobject]@{IsEnabled = "true"; IsChecked = "true"; domainDisplayName = $domain.domainDisplayName; samAccount = ""; displayName = ""; expiresIn = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set current password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; pswdSetBtnText = "Set new password"; pswdSetBtnVisible = "Hidden"; pswdSetBtnEnabled = $true; clipBoardBtnVisible = "Hidden"; pswdNew = ""; dc = $domain.dc; domainName = $domain.domainName;})
            }
            else
            {
                $Global:dbUser += @([pscustomobject]@{IsVisible = "Hidden"; IsEnabled = ""; IsChecked = ""; domainDisplayName = ""; samAccount = ""; displayName = ""; expiresIn = ""; accountStatus = ""; pswdVer = ""; pswdVerifyBtnText = "Set current password"; pswdVerifyBtnVisible = "Hidden"; pswdVerifyBtnEnabled = $true; pswdSetBtnText = "Set new password"; pswdSetBtnVisible = "Hidden"; pswdSetBtnEnabled = $true; clipBoardBtnVisible = "Hidden"; pswdNew = ""; dc = ""; domainName = ""; adObject = ""})
            }
        }
    }

    $Global:dbUser = $Global:dbUser | Sort-Object -Property DomainDisplayName -Descending

    # Add pscustomojbect to each listview and refresh the gui
    $Global:userListView.ItemsSource = $Global:dbUser
    $Global:userListView.Items.Refresh()
}