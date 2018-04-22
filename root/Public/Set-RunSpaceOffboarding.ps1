function Set-RunSpaceOffboarding
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $syncHash,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Search", "Disable")]
        $task,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $adminAccount = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $userAccount,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $dc,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $dcCount = 2,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $domainName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $officeDomain = $true,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $dbOffboarding,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $offboardingListView,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$pswd,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$credentials,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $domainBase,
  
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $userDistName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $offboardingResults,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [bool]$whatIf = $false    
    )

    # If password is set and credentials is null build credentials
    If ($pswd)
    {
        if ($pswd.GetType().Name -eq "SecureString" -and (!($credentials)))
        {
            $credentials = new-object -typename System.Management.Automation.PSCredential($adminAccount, $pswd)
        }      
    }


    $syncHash.Host = $host
    #$syncHash.editDB = $false    
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "UseNewThread"
    $Runspace.Open()

    $syncHash.activeRunspaces++
    $Runspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
    $Runspace.SessionStateProxy.SetVariable("task", $task)
    $Runspace.SessionStateProxy.SetVariable("adminAccount", $adminAccount)
    $Runspace.SessionStateProxy.SetVariable("userAccount", $userAccount)
    $Runspace.SessionStateProxy.SetVariable("dc", $dc)
    $Runspace.SessionStateProxy.SetVariable("domainName", $domainName)
    $Runspace.SessionStateProxy.SetVariable("officeDomain", $officeDomain)
    $Runspace.SessionStateProxy.SetVariable("whatIf", $whatIf)
    $Runspace.SessionStateProxy.SetVariable("offboardingListView", $offboardingListView)
    $Runspace.SessionStateProxy.SetVariable("domainBase", $domainBase)
    $Runspace.SessionStateProxy.SetVariable("dbOffboarding", $dbOffboarding)
    $Runspace.SessionStateProxy.SetVariable("pswd", $pswd)
    $Runspace.SessionStateProxy.SetVariable("credentials", $credentials)
    $Runspace.SessionStateProxy.SetVariable("userDistName", $userDistName)

    $Runspace.SessionStateProxy.SetVariable("offboardingResults", $offboardingResults)
    
    $Runspace.SessionStateProxy.SetVariable("disableAccount", $syncHash.offboToggleDisable.IsChecked)
    $Runspace.SessionStateProxy.SetVariable("moveToDisabled", $syncHash.offboToggleMoveDis.IsChecked)
    $Runspace.SessionStateProxy.SetVariable("removeGroups", $syncHash.offboToggleRemoveGrps.IsChecked)
    

    $code = {
        
        Function Set-OffboardingDatabase ($adminAd, $userAd, $syncHash, $dbOffboarding, $domainBase)
        {
            <#             [CmdletBinding()]
            Param(
                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                $adminAd,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $userAd = $true,
                
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $syncHash = $true,
                
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $dbOffboarding = $true,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $domainBase = $true
            ) #>
            
            # Check if runspace is editing database and sleep until call can take turn
            While ($syncHash.editDB -eq $true)
            {
                Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 500)
            }
            # Set flag that this call will now edit the db
            $syncHash.editDB = $true

            foreach ($user in $userAd)
            {    
                # Skip blank user entries
                If (!($user)) {continue; }

                $entryFound = $false
                $dbLink

                $index = 0

                # Search for a matching entry in our current database
                foreach ($dbEntry in $dbOffboarding)
                {
                    If ($dbEntry.domainName -eq $user.domainName)
                    {
                        If (($dbEntry.userAccount -like "" ) -or ($user.SamAccountName -eq $dbEntry.userAccount))
                        {
                            $entryFound = $true
                            $dbLink = $dbEntry
                            $index = $dbOffboarding.IndexOf($dbEntry)
                            break;
                        }
                    }
                }

                # If no match found take first empty one
                If ($entryFound -eq $false)
                {
                    foreach ($dbEntry in $dbOffboarding)
                    {
                        If ($dbEntry.domainName -eq "")
                        {
                            $index = $dbOffboarding.domainName.IndexOf($user.domainName)
                            # Create reference so that on all objects with this account the same password field is shown
                            $dbEntry.pswdVerifyBtnText = $dbOffboarding[$index].pswdVerifyBtnText
                            $dbEntry.pswdVerifyBtnEnabled = $dbOffboarding[$index].pswdVerifyBtnEnabled
                            $dbEntry.pswdVer = $dbOffboarding[$index].pswdVer
                            $dbEntry.domainBase = $dbOffboarding[$index].domainBase 
                            $dbEntry.officeDomain = $dbOffboarding[$index].officeDomain                             
                            $dbLink = $dbEntry
                            break;             
                        }
                    }
                }

                # Set minimal information in case entry requires search with credentials
                $dbLink.userStatus = $user.status
                $dbLink.domainName = $user.domainName
                $dbLink.dc = $dbOffboarding[$index].dc

                # If user entry has been passed
                If ($user.SamAccountName)
                {
                    $dbLink.userAccount = $user.SamAccountName
                    $dbLink.userDisplayName = $user.displayName
                    $dbLink.userOu = [regex]::Match($user.DistinguishedName, "CN=.*[OC][UN]=([- _\d\w]*),").Groups[1].Value
                    $dbLink.userMemberOf = $user.MemberOf.Count
                    $dbLink.adObject = $user
                    $dbLink.userDistName = $user.DistinguishedName
                }

                If ($adminAd)
                {
                    # Set admin account infor
                    $dbLink.samAccount = $adminAd.SamAccountName
                    $dbLink.accountStatus = $adminAd.status
                }


                # Take care of checkbox and visibility
                If (!($adminAd) -or $adminAd.healthy -eq $true)
                {
                    $dbLink.pswdVerifyBtnVisible = "Visible"
                    $dbLink.IsChecked = $true
                    $dbLink.IsEnabled = $true
                }
                else
                {
                    $dbLink.pswdVerifyBtnVisible = "Hidden"
                    $dbLink.IsChecked = $false
                    $dbLink.IsEnabled = $false
                }
                $dbLink.IsVisible = "Visible"
            }
            # Set flag that this call is done with editing the db
            $syncHash.editDB = $false
        } # End Function Set-CurrentDatabase    

        Function Get-DomainAccounts
        {
            [CmdletBinding()]
            Param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $samAccountName,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                [boolean]$checkSingleAccount = $false,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $dc,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                $dcCount = 2,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $domainName,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                $officeDomain = $true,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                $returnAdmin = $false,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                [PSCredential]$credentials,

                [Parameter(Mandatory = $false)]
                $predictAccounts = $false,
    
                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                [bool]$whatIf = $false    
            )

            # Simulate results
            if ($whatIf -eq $true)
            {
                Write-Verbose -Message "Get-UsersDomainAccounts is running in WhatIf" -Verbose
                # Simulate pause fore testing render of progressbar
                Start-Sleep (Get-Random -Minimum 1 -Maximum 2)

                # Return one of the account cases
                switch (Get-Random -Minimum 1 -Maximum 9)
                {
                    "1" {$adAccounts = @([pscustomobject]@{SamAccountName = "a-$samAccountName"; Enabled = $true; LockedOut = $true; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-$samAccountName"; PasswordExpired = $false})
                    }
                    "2" {$adAccounts = @([pscustomobject]@{SamAccountName = "a-$samAccountName"; Enabled = $false; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-$samAccountName"; PasswordExpired = $false})
                    }
                    "3" {$adAccounts = @([pscustomobject]@{SamAccountName = "$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = (Get-Date); DisplayName = "Christopher Berger"; PasswordExpired = $false})
                    }
                    "4" {$adAccounts = @([pscustomobject]@{SamAccountName = "a-$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-$samAccountName"; PasswordExpired = $false})
                    }
                    "5" {$adAccounts = @([pscustomobject]@{SamAccountName = "$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "Christopher Berger"; PasswordExpired = $false}),
                        ([pscustomobject]@{SamAccountName = "a-$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-$samAccountName"; PasswordExpired = $false})
                    }
                    "6" {$exception = "The Server has rejected the client credentials."; $officeDomain = $true; $normalAccount = "$samAccountName"; $adminAccount = "a-$samAccountName"}
                    "7" {$exception = "The Server has rejected the client credentials."; $officeDomain = $false; $normalAccount = "$samAccountName"; $adminAccount = "a-$samAccountName"}
                    "8" {$adAccounts = @([pscustomobject]@{SamAccountName = "$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date)); DisplayName = "Christopher Berger"; PasswordExpired = $false}),
                        ([pscustomobject]@{SamAccountName = "a-$samAccountName"; Enabled = $true; LockedOut = $false; PasswordLastSet = ((Get-Date).AddDays(-10)); DisplayName = "a-$samAccountName"; PasswordExpired = $false})
                    }
                    "9" {$loopCount = $dcCount}
                }
            }
            else
            {

                If ($checkSingleAccount -eq $true)
                {
                    $adminAccount = $samAccountName
                    $normalAccount = $samAccountName
                }
                else
                {
                    # Create variable for normal and admin user account
                    if (($samAccountName.substring(0, 2) -eq 'a-') -or ($samAccountName.substring(0, 2) -eq 'A-'))
                    {
                        $adminAccount = $samAccountName
                        $normalAccount = $samAccountName.Split("a-")[2]
                    }
                    else
                    {
                        $adminAccount = "a-$samAccountName"
                        $normalAccount = $samAccountName
                    }
                }

                # Variables to keep exception message for do while loop and a counter    
                $exception = $null
                $loopCount = 0
                # Get accounts from AD, try multiple domain controllers in case it cant reach it
                do
                {
                    $loopCount++
                    try
                    {
                        # If credentials is set
                        if ($credentials)
                        {
                            $adAccounts = Get-ADUser -Server $dc -Filter {(SamAccountName -eq $normalAccount) -Or (SamAccountName -eq $adminAccount)} -Properties Enabled, SamAccountName, PasswordExpired, LockedOut , DisplayName, PasswordLastSet, MemberOf -Credential $credentials -ResultPageSize 5
                        }
                        else
                        {
                            $adAccounts = Get-ADUser -Server $dc -Filter {(SamAccountName -eq $normalAccount) -Or (SamAccountName -eq $adminAccount)} -ResultPageSize 5 -Properties Enabled, SamAccountName, PasswordExpired, LockedOut , DisplayName, PasswordLastSet, MemberOf 
                        }
                    }
                    catch
                    {
                        $exception = $_.Exception.Message
                        # Increase node number on domainController

                        Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                        "`t" + $_.Exception.Message | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                        "`t$domainName\$adminAccount @ $dc" | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append

                        # If unable to connect dc try next one
                        If ($exception -match "Unable to contact the server")
                        {
                            $dc = $dc.Replace("$loopCount", ($loopCount + 1))
                        }
                        else 
                        {
                            Start-Sleep -Milliseconds 333
                        }
                        
                        
                    }
                }While (($exception -match "Unable to contact the server" -and $loopCount -le $dcCount) -or $exception -match "invalid enumeration context")
            }

            # Error handling
            If ($exception -ne $null)
            {
                # Predict account names, will be tested with real credentials
                If ($exception -match "The Server has rejected the client credentials." -or $exception -match "A call to SSPI failed, see inner exception.")
                {
                    If ($predictAccounts -eq $true)
                    {
                        $adAccounts = @([pscustomobject]@{samAccountName = $normalAccount; })           
                        # Predict 2nd account if it is an office domain
                        if ($officeDomain -eq "true")
                        {
                            $adAccounts += @([pscustomobject]@{samAccountName = $adminAccount; })
                        } 
                    }

                    $accountStatus = "Verification required"     
                }
                # If we tried to contact all domain controllers without success
                elseif ($exception -match "Unable to contact the server" -and $dcCount -eq $loopCount)
                {
                    $accountStatus = "domain controllers not reachable"
                    $adAccounts = @([pscustomobject]@{samAccountName = "ERROR"; })
                }
                else
                {
                    $accountStatus = "not able to find user due to unknown error"
                    $adAccounts = @([pscustomobject]@{samAccountName = "ERROR"; })
                }
            }

            # If no account was found
            if ($adAccounts -eq $null -and ($exception))
            {
                $adAccounts = @([pscustomobject]@{accountStatus = $accountStatus; })
            }
            elseif ($adAccounts -eq $null)
            {
                $accountStatus = "there were no accounts found in this domain"
                $adAccounts = @([pscustomobject]@{accountStatus = $accountStatus; })
            }

            # Set account status for each user
            foreach ($adAccount in $adAccounts)
            {
                # If password field is not existing accounts were not found
                If ($adAccount.PasswordLastSet -ne $null)
                {
                    # Check when password has been set to recent
                    $pswdChangeTime = ((Get-Date).Ticks - $adAccount.PasswordLastSet).TotalHours
                    if ($adAccount.Enabled -eq $false )
                    {
                        $accountStatus = "Account is disabled"
                    }
                    elseif ($adAccount.LockedOut -eq $true)
                    {
                        $accountStatus = "Account is locked out"
                    }
                    elseif ($adAccount.PasswordExpired -eq $true)
                    {
                        $accountStatus = "Password has already expired"
                    }
                    elseif ($pswdChangeTime -le $pswdHistory)
                    {
                        $accountStatus = "Password change possible in " + [math]::Round(($pswdHistory - $pswdChangeTime), 2) + " hours"
                    }
                    else
                    {
                        $accountStatus = "Healthy"
                    }
                }

                # Set flag if user account is in an ok state
                If ($accountStatus -eq "Healthy" -or $accountStatus -eq "Verification required")
                {
                    $adAccount | Add-Member -NotePropertyName healthy -NotePropertyValue $true -Force            
                }
                else
                {
                    $adAccount | Add-Member -NotePropertyName healthy -NotePropertyValue $false -Force            
                }

                # Add status field
                $adAccount | Add-Member -NotePropertyName status -NotePropertyValue $accountStatus -Force
            }
            # Add domain part
            $adAccounts | Add-Member -NotePropertyName domainName -NotePropertyValue $domainName -Force

            # If only admin account has been requested
            If ($returnAdmin -eq $true -and $adAccounts.Count -gt 1)
            {
                $adAccounts = $adAccounts| Where-Object {$_.SamAccountName -eq $adminAccount}
            }  
            return $adAccounts
        }

        Function Disable-DomainAccount
        {
            [CmdletBinding()]
            Param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $adminAccount = $env:USERNAME,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $userAccount,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $userDistName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $dc,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $offboardingResults,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $disableAccount,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $moveToDisabled,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                $removeGroups,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [Pscredential]$credentials
            )

            ####### REMOVE
            Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
            $syncHash.offboToggleDisable.IsChecked | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
            $toggleDisable | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
            ############# ME 

            #Create searchbase from domainController FQDN
            $searchbase = "DC=" + [regex]::match($dc, "\.(\w*)\.").Groups[1].Value + ",DC=" + [regex]::match($dc, "\.(\w*)$").Groups[1].Value

            #check if "Disabled Users" OU exists in the domain, if not create it
            $disabledFolder = Get-ADOrganizationalUnit -Identity "OU=Disabled Users,$searchbase" -Credential $credentials -Server $dc
            If (!($disabledFolder))
            {
                New-ADOrganizationalUnit -Name "Disabled Users" -Path $searchbase -server $dc -credential $credentials

                $disabledFolder = Get-ADOrganizationalUnit -Identity "OU=Disabled Users,$searchbase" -Credential $credentials -Server $dc
            }

            # Disable account if setting enabled
            If ($disableAccount -eq $true)
            { 
                try
                {
                    # Get user object
                    $temp = Set-ADUser -Identity $userDistName -Server $dc -Credential $credentials -Enabled $false
                    $offboardingResults.disabled = $true
                }
                catch
                {
                    Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                    "`t Error during Disable Account:" + $_.Exception.Message | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                    "`t $userDistName" | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                }
            }

            # Remove groups if setting is active
            If ($removeGroups -eq $true)
            { 
                $offboardingResults.removeGrps = $true
                
                [array]$userGroupMembership = @()
                $userGroupMembership = Get-ADPrincipalGroupMembership $userDistName -server $dc -Credential $credentials
                $userGroupMembership = $userGroupMembership | Where-Object { $_.SamAccountName -ne "Domain Users" -and $_.SamAccountName -ne "Domänen-Benutzer" }
                ForEach ($userGroup in $userGroupMembership)
                { 
                    try
                    {
                        $temp = Remove-ADGroupMember -Identity $userGroup.DistinguishedName -Member $userDistName -server $dc -credential $credentials -Confirm:$false
                        $offboardingResults.grpsRemoved += $userGroup.SamAccountName
                        
                    }
                    catch
                    {
                        Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                        "`t Error during Remove Group:" + $_.Exception.Message | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                        "`t $userDistName" + $_.Exception.Message | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                    }
                }
            }

            # Move to disabled folder if setting is active
            If ($moveToDisabled -eq $true)
            { 
                try
                {
                    # Check if user is already in disabled folder
                    If ($userDistName -notmatch $disabledFolder)
                    {
                        $temp = Move-ADObject -Identity $userDistName -server $dc -TargetPath $disabledFolder -credential $credentials
                    }
                    $offboardingResults.moved = $true
                }
                catch
                {
                    Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                    "`t Error during Move Account:" + $_.Exception.Message | Out-File -FilePath "C:\coding\ActiveDirectoryAccountManager\logs\runspaceError.txt" -Append
                }
            }
        }

        # Only one runspace can make calls to a domain, otherwise we recieve the following erros:
        # The server has returned the following error: invalid enumeration context.

        # Check if there is another runspace making calls to the same domain
        While ($syncHash.activeRunSpaceDomains -eq $domainName)
        {
            # Wait until other runspace finished
            Start-Sleep -Seconds 1
        }
        # Add the domain name to the active runspace list
        $syncHash.activeRunSpaceDomains.Add($domainName)

        Switch ($task)
        {
            "search"
            {
                If ($credentials)
                {
                    $adminAd = Get-DomainAccounts -samAccountName $adminAccount -dc $dc -domainName $domainName -returnAdmin $true -officeDomain $officeDomain -credentials $credentials #-whatIf $true
                    $userAd = Get-DomainAccounts -samAccountName $userAccount -dc $dc -domainName $domainName -officeDomain $officeDomain -credentials $credentials #-whatIf $true
                }
                else
                {
                    $adminAd = Get-DomainAccounts -samAccountName $adminAccount -dc $dc -domainName $domainName -predictAccounts $true -returnAdmin $true -officeDomain $officeDomain #-whatIf $true
                    $userAd = Get-DomainAccounts -samAccountName $userAccount -dc $dc -domainName $domainName -officeDomain $officeDomain #-whatIf $true
                }
                Set-OffboardingDatabase $adminAd $userAd $syncHash $dbOffboarding $domainBase
        
            }
            "disable"
            {
                Disable-DomainAccount -adminAccount $adminAccount -credentials $credentials -userAccount $userAccount -dc $dc -userDistName $userDistName -moveToDisabled $moveToDisabled -disableAccount $disableAccount -removeGroups $removeGroups -offboardingResults $offboardingResults

                $userAd = Get-DomainAccounts -samAccountName $userAccount -dc $dc -domainName $domainName -officeDomain $officeDomain -credentials $credentials -checkSingleAccount $true #-whatIf $true

                Set-OffboardingDatabase $null $userAd $syncHash $dbOffboarding $domainBase
            }
        }

        $syncHash.activeRunspaces--
        $syncHash.activeRunSpaceDomains.Remove($domainName)

        # Refresh the gui if the last Runspace has finished
        If ($syncHash.activeRunspaces -eq 0)
        {

            If ($task -eq "disable")
            {
               
            } 
            
            $syncHash.Window.Dispatcher.invoke([action] {
                    $Global:dbOffboarding = $Global:dbOffboarding | Sort-Object -Property domainName -Descending
                    Start-Sleep -Seconds 1
                    $Global:offboardingListView.ItemsSource = $Global:dbOffboarding
                    $Global:offboardingListView.Items.Refresh()
                    $syncHash.statusBarProgress.IsIndeterminate = $false
                    $syncHash.statusBarProgress.Value = 0
                })
        }
    }

    $PSinstance = [powershell]::Create().AddScript($code)
    $PSinstance.Runspace = $Runspace
    $PSinstance.BeginInvoke()

}