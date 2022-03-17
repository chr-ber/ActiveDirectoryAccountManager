function RunspacePing {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $syncHash,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $samAccountName = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $dc,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $dcCount = 2,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $domainDisplayName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $returnAdmin = $false,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]$pswdHistory = 24,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $dbUser,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $userListView,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $pswd,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$credentials,
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [bool]$whatIf = $false    
    )

    $syncHash.Host = $host
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open()
    $syncHash.activeRunspaces++
    $Runspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
    $Runspace.SessionStateProxy.SetVariable("samAccountName", $samAccountName)
    $Runspace.SessionStateProxy.SetVariable("dc", $dc)
    $Runspace.SessionStateProxy.SetVariable("domainDisplayName", $domainDisplayName)
    $Runspace.SessionStateProxy.SetVariable("whatIf", $whatIf)
    $Runspace.SessionStateProxy.SetVariable("userListView", $userListView)
    $Runspace.SessionStateProxy.SetVariable("dbUser", $dbUser)
    $Runspace.SessionStateProxy.SetVariable("pswd", $pswd)
    $Runspace.SessionStateProxy.SetVariable("predictAccounts", $true)
    $Runspace.SessionStateProxy.SetVariable("credentials", $credentials)
    $Runspace.SessionStateProxy.SetVariable("pswdHistory", $pswdHistory)
    $Runspace.SessionStateProxy.SetVariable("Runspace", $Runspace) 


    $code = {

        Function Set-CurrentUserDatabase($userTable, $syncHash, $userListView, $dbUser) {
            # Check if runspace is editing database and sleep until call can take turn
            While ($syncHash.editDB -eq $true) {
                Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 500)
            }
            # Set flag that this call will now edit the db
            $syncHash.editDB = $true
            [integer]$index
            

            foreach ($user in $userTable) {    
                # Skip blank returns from Get-Job
                If (!$user) { continue; }

                $entryFound = $false
                $dbLink

                # Search for a matching entry in our current database
                foreach ($dbEntry in $dbUser) {
                    If ($dbEntry.domainDisplayName -eq $user.domainDisplayName) {
                        If (($dbEntry.SamAccount -like "" ) -or ($user.SamAccountName -eq $dbEntry.SamAccount)) {
                            $entryFound = $true
                            $dbLink = $dbEntry
                            $index = $dbUser.IndexOf($dbEntry)
                            break
                        }
                    }
                }

                # If no entry has been found create one
                If ($entryFound -eq $false) {
                    foreach ($dbEntry in $dbUser) {
                        If ($dbEntry.domainDisplayName -eq "") {
                            $dbLink = $dbEntry
                            $dbLink.domainName = $dbUser[$index].domainName
                            $dbLink.dc = $dbUser[$index].dc
                            break
                        }
                    }
                }

                # Set minimal information in case entry requires search with credentials
                $dbLink.accountStatus = $user.status
                $dbLink.domainDisplayName = $user.domainDisplayName

                # If user entry has been passed
                If ($user.SamAccountName) {
                    $dbLink.adObject = $user
                    $dbLink.samAccount = $user.SamAccountName
                    $dbLink.displayName = $user.displayName
                    $daysLeft = [math]::Round((90 - ((Get-Date).Ticks - $user.PasswordLastSet).TotalDays), 0)
                    If ($daysLeft -gt 0 -and $user.PasswordExpired -eq $false) {
                        $dbLink.expiresIn = $daysLeft
                    }
                }

                If ($user.healthy -eq $true) {
                    $dbLink.pswdVerifyBtnVisible = "Visible"
                    $dbLink.IsChecked = $true
                    $dbLink.IsEnabled = $true
                    If ($dbLink.pswdVer) {
                        $dbLink.pswdSetBtnVisible = "Visible"
                    }
                }
                else {
                    $dbLink.pswdVerifyBtnVisible = "Hidden"
                    $dbLink.pswdSetBtnVisible = "Hidden"                    
                    $dbLink.IsChecked = $false
                    $dbLink.IsEnabled = $false
                }
                $dbLink.IsVisible = "Visible"
            }
            # Set flag that this call is done with editing the db
            $syncHash.editDB = $false
        } # End Function Set-CurrentDatabase
      
        # Can be used to simulate results
        if ($whatIf -eq $true) {
            Write-Verbose -Message "Get-UsersDomainAccounts is running in WhatIf" -Verbose
            # Simulate pause fore testing render of progressbar
            Start-Sleep (Get-Random -Minimum 1 -Maximum 2)

            # Return one of the account cases
            switch (Get-Random -Minimum 1 -Maximum 9)
            {
                "1" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "a-jdoe"; Enabled = $true; LockedOut = $true; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-jdoe"; PasswordExpired = $false })
                }
                "2" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "a-jdoe"; Enabled = $false; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-jdoe"; PasswordExpired = $false })
                }
                "3" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = (Get-Date); DisplayName = "John Doe"; PasswordExpired = $false })
                }
                "4" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "a-jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-jdoe"; PasswordExpired = $false })
                }
                "5" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "John Doe"; PasswordExpired = $false }),
                    ([pscustomobject]@{SamAccountName = "a-jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-jdoe"; PasswordExpired = $false })
                }
                "6" { $exception = "The Server has rejected the client credentials."; $normalAccount = "jdoe"; $adminAccount = "a-jdoe" }
                "7" { $exception = "The Server has rejected the client credentials."; $normalAccount = "jdoe"; $adminAccount = "a-jdoe" }
                "8" {
                    $adAccounts = @([pscustomobject]@{SamAccountName = "jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date)); DisplayName = "John Doe"; PasswordExpired = $false }),
                    ([pscustomobject]@{SamAccountName = "a-jdoe"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-jdoe"; PasswordExpired = $false })
                }
                "9" { $loopCount = $dcCount }
            }
        }
        else {
            # If password is set and credentials is null build credentials
            if ($pswd.GetType().Name -eq "SecureString" -and (!($credentials))) {
                $credentials = new-object -typename System.Management.Automation.PSCredential($samAccountName, $pswd)
            }
            # Create variable for normal and admin user account
            if (($samAccountName.substring(0, 2) -eq 'a-') -or ($samAccountName.substring(0, 2) -eq 'A-')) {
                $adminAccount = $samAccountName
                $normalAccount = $samAccountName.Split("a-")[2]
            }
            else {
                $adminAccount = "a-$samAccountName"
                $normalAccount = $samAccountName
            }
            # Variables to keep exception message for do while loop and a counter    
            $exception = $null
            $loopCount = 0
            # Get accounts from AD, try multiple domain controllers in case it cant reach it
            do {
                $loopCount++
                try {
                    # If credentials is set
                    if ($credentials) {
                        $adAccounts = Get-ADUser -Server $dc -Filter { (SamAccountName -like $normalAccount) -Or (SamAccountName -like $adminAccount) } -Properties Enabled, SamAccountName, PasswordExpired, LockedOut , DisplayName, PasswordLastSet -Credential $credentials
                    }
                    else {
                        $adAccounts = Get-ADUser -Server $dc -Filter { (SamAccountName -like $normalAccount) -Or (SamAccountName -like $adminAccount) } -Properties Enabled, SamAccountName, PasswordExpired, LockedOut , DisplayName, PasswordLastSet                           
                    }
                }
                catch {
                    $exception = $_.Exception.Message
                    # Increase node number on domainController
                    $dc = $dc.Replace("$loopCount", ($loopCount + 1))
                }
            }While ($exception -match "Unable to contact the server" -and $loopCount -le $dcCount)
        }

        # Error handling
        If ($null -ne $exception) {
            # Predict account names, will be tested with real credentials
            If ($exception -match "The Server has rejected the client credentials." -or $exception -match "A call to SSPI failed, see inner exception.") {
                If ($predictAccounts -eq $true) {
                    $adAccounts = @([pscustomobject]@{samAccountName = $normalAccount; })           
                }
                $accountStatus = "Verification required"     
            }
            # If we tried to contact all domain controllers without success
            elseif ($exception -match "Unable to contact the server" -and $dcCount -eq $loopCount) {
                $accountStatus = "domain controllers not reachable"
                $adAccounts = @([pscustomobject]@{samAccountName = "ERROR"; })
            }
            else {
                $accountStatus = "not able to find user due to unknown error"
                $adAccounts = @([pscustomobject]@{samAccountName = "ERROR"; })
            }
        }

        # If no account was found
        if ($null -eq $adAccounts -and ($exception)) {
            $adAccounts = @([pscustomobject]@{accountStatus = $accountStatus; })
        }
        elseif ($null -eq $adAccounts) {
            $accountStatus = "there were no accounts found in this domain"
            $adAccounts = @([pscustomobject]@{accountStatus = $accountStatus; })
        }

        # Set account status for each user
        foreach ($adAccount in $adAccounts) {
            # If password field is not existing accounts were not found
            If ($null -ne $adAccount.PasswordLastSet) {
                # Check when password has been set to recent
                $pswdChangeTime = ((Get-Date).Ticks - $adAccount.PasswordLastSet).TotalHours
                if ($adAccount.Enabled -eq $false ) {
                    $accountStatus = "Account is disabled"
                }
                elseif ($adAccount.LockedOut -eq $true) {
                    $accountStatus = "Account is locked out"
                }
                elseif ($adAccount.PasswordExpired -eq $true) {
                    $accountStatus = "Password has already expired"
                }
                elseif ($pswdChangeTime -le $pswdHistory) {
                    $accountStatus = "Password change possible in " + [math]::Round(($pswdHistory - $pswdChangeTime), 2) + " hours"
                }
                else {
                    $accountStatus = "Healthy"
                }
            }

            # Set flag if user account is in an ok state
            If ($accountStatus -eq "Healthy" -or $accountStatus -eq "Verification required") {
                $adAccount | Add-Member -NotePropertyName healthy -NotePropertyValue $true -Force            
            }
            else {
                $adAccount | Add-Member -NotePropertyName healthy -NotePropertyValue $false -Force            
            }

            # Add status field
            $adAccount | Add-Member -NotePropertyName status -NotePropertyValue $accountStatus -Force
        }
        # Add domain part
        $adAccounts | Add-Member -NotePropertyName domainDisplayName -NotePropertyValue $domainDisplayName -Force

        # If only admin account has been requested
        If ($returnAdmin -eq $true -and $adAccounts.Count -gt 1) {
            $adAccounts = $adAccounts | ? { $_.SamAccountName -eq $adminAccount }
        } 

        Set-CurrentUserDatabase $adAccounts $syncHash $userListView $dbUser
        $syncHash.activeRunspaces--
        Set-ProgressBar

        If ($syncHash.activeRunspaces -eq 0) {
            $syncHash.Window.Dispatcher.invoke([action] {
                    $Global:dbUser = $Global:dbUser | Sort-Object -Property domainDisplayName -Descending
                    $userListView.ItemsSource = $Global:dbUser
                    $userListView.Items.Refresh()
                    $syncHash.statusBarProgress.IsIndeterminate = $false
                    $syncHash.statusBarProgress.Value = 0
                    $syncHash.statusBarText.Text = ""
                })
        }
        $Runspace.EndInvoke($Runspace)
        $Runspace.Dispose()
    }
    $PSinstance = [powershell]::Create().AddScript($Code)
    $PSinstance.Runspace = $Runspace
    $PSinstance.BeginInvoke()
}