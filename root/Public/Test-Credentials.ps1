Function Test-Credentials($pswd, $userObject, $whatif)
{
    if ($whatif)
    {
        Write-Host "Running WhatIf on Test-Credentials for domain account: " $userObject.samAccount " | doomain server: " $userObject.domainName
        If ((Get-Random -Maximum 10) -gt 4)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    try
    {
        Write-Host "Running Test-Credentials: " $userObject.samAccount " | doomain server: " $userObject.domainName
        
        if ($pswd.GetType().Name -eq "SecureString")
        {
            $credentials = new-object -typename System.Management.Automation.PSCredential($userObject.SamAccount, $pswd)
        }
        else
        {
            $credentials = $pswd
        }

        # Try disable account in WhatIf to validate if the credentials are correct
        Disable-ADAccount -identity $userObject.samAccount -server $userObject.dc -credential $credentials -WhatIf #-ErrorAction SilentlyContinue -ErrorVariable ProcessError
        
        # Safe password in variable of user
        $userObject.pswdVer = $credentials
        

        # If domain needed credentials to scan for user, use runspaceping to update the entries
        if ($userObject.accountStatus -match "Verifictaion required")
        {
            Switch ($Global:tabControl.SelectedItem.Name)
            {
                "tabUser"
                {
                    RunspacePing -totalJobs 1 -userListView $Global:userListView -dbUser $Global:dbUser -syncHash $syncHash -samAccountNAme $env:USERNAME -dc $userObject.dc -domainName $userObject.domainName -whatIf $true -credentials $credentials
                }
                "tabAdmin"
                {}
                "tabOffboarding"
                {
                    Set-RunSpaceOffboarding -offboardingListView $Global:offboardingListView -dbOffboarding $Global:dbOffboarding -syncHash $syncHash -adminAccount $env:USERNAME -userAccount $syncHash.userBoxDisable.Text -dc $userObject.dc -domainName $userObject.domainName -domainBase $userObject.domainBase -credentials $credentials -task search
                }
            }
        }
        return $true
    }
    catch
    {
        #Password not correct
        Write-Host "Running Test-Credentials: failed for above domain."
        Write-Host $_.Exception.Message
        return $false
    }
    
}