function Set-RunSpaceOffboardingReWork
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $syncHash,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $adminAccount = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $userAccount,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $dc,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $dbOffboarding,

        [Parameter(Mandatory = $true)]
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
        $userDistName,  

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $domainName,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [bool]$whatIf = $false    
    )

    # If password is set and credentials is null build credentials
    if ($pswd.GetType().Name -eq "SecureString" -and (!($credentials)))
    {
        $credentials = new-object -typename System.Management.Automation.PSCredential($adminAccount, $pswd)
    } 

    $syncHash.Host = $host
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "UseNewThread"
    $Runspace.Open()

    $syncHash.activeRunspaces++
    $Runspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
    $Runspace.SessionStateProxy.SetVariable("domainName", $domainName)    
    $Runspace.SessionStateProxy.SetVariable("task", $task)
    $Runspace.SessionStateProxy.SetVariable("adminAccount", $adminAccount)
    $Runspace.SessionStateProxy.SetVariable("userAccount", $userAccount)
    $Runspace.SessionStateProxy.SetVariable("whatIf", $whatIf)
    $Runspace.SessionStateProxy.SetVariable("offboardingListView", $offboardingListView)
    $Runspace.SessionStateProxy.SetVariable("dc", $dc)    
    $Runspace.SessionStateProxy.SetVariable("dbOffboarding", $dbOffboarding)
    $Runspace.SessionStateProxy.SetVariable("credentials", $credentials)
    $Runspace.SessionStateProxy.SetVariable("userDistName", $userDistName)
    

    $code = {

        While ($syncHash.activeRunSpaceDomains -eq $domainName)
        {
            Start-Sleep -Seconds 1
        }
        
        $syncHash.activeRunSpaceDomains.Add($domainName)


        $user = Get-ADUser -Identity $userDistName -Server $dc -Credential $credentials -Properties Enabled

        #Create Searchbase from domainController FQDN
        $searchbase = "DC=" + [regex]::match($dc, "\.(\w*)\.").Groups[1].Value + ",DC=" + [regex]::match($dc, "\.(\w*)$").Groups[1].Value

        #check if "Disabled Users" OU exists in the domain, if not create it
        $disabledFolder = Get-ADOrganizationalUnit -Identity "OU=Disabled Users,$searchbase" -Credential $credentials -Server $dc
        If (!($disabledFolder))
        {
            New-ADOrganizationalUnit -Name "Disabled Users" -Path $searchbase -server $dc -credential $credentials

            $disabledFolder = Get-ADOrganizationalUnit -Identity "OU=Disabled Users,$searchbase" -Credential $credentials -Server $dc
        }


        try
        {
            $userStateEnabled = $user.Enabled
            $temp = Set-ADUser -Identity $userDistName -Server $dc -Credential $credentials -Enabled $false
            Start-Sleep -Milliseconds 250
        }
        catch
        {
            Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
            "`t Error during Disable Account:" + $_.Exception.Message | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
            "`t $userDistName" + $_.Exception.Message | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append

        }



        # Get an array of all the groups the user is memberof except "Domain Users" and "Domänen-Benutzer"
        #. TextHandler "green" "Removed $displayName ($userAccount) from the following groups in $domainPart`:"


        # If groups have been found remove the user from them
        [array]$userGroupMembership = @()
        $userGroupMembership = Get-ADPrincipalGroupMembership $userDistName -server $dc -Credential $credentials
        $userGroupMembership = $userGroupMembership | Where-Object { $_.SamAccountName -ne "Domain Users" -and $_.SamAccountName -ne "Domänen-Benutzer" }
        #$userObject.offboardingText += "Removing the user from following groups:"
        ForEach ($userGroup in $userGroupMembership)
        { 
            try
            {
                $temp = Remove-ADGroupMember -Identity $userGroup.DistinguishedName -Member $userDistName -server $dc -credential $credentials -Confirm:$false 
                Start-Sleep -Milliseconds 500
            }
            catch
            {
                Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
                "`t Error during Remove Group:" + $_.Exception.Message | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
                "`t $userDistName" + $_.Exception.Message | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append                        
            }
    
        }

                        
        try
        {
            # Move user to disabled users organizational unit
            
            If ($userDistName -notmatch $disabledFolder)
            {
                $temp = Move-ADObject -Identity $userDistName -server $dc -TargetPath $disabledFolder -credential $credentials 
                #. TextHandler "green" "Moved $displayName ($userAccount) to $disabledTargetPath in" $domainPart                        
            }
            else
            {
                # User already in the diabled users folder
            }
        }
        catch
        {
            Get-Date -format yy-MM-dd-hh:mm:ss | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
            "`t Error during Move Account:" + $_.Exception.Message | Out-File -FilePath "C:\temp\runspaceErros\error.txt" -Append
        
        }

        $syncHash.activeRunspaces--
        $syncHash.activeRunSpaceDomains.Remove($domainName)

        # Refresh the gui if the last Runspace has finished
        If ($syncHash.activeRunspaces -eq 0)
        {
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