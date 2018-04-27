Function Set-Credentials($pswdNew, $userObject, $whatif)
{
    if ($whatif)
    {
        Write-Host "Running WhatIf on Set-Credentials for domain account: " $userObject.samAccount " | domain server: " $userObject.domainName
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
        Write-Host "Running Set-Credentials: " $userObject.samAccount " | doomain server: " $userObject.domainName

        $credentials = new-object -typename System.Management.Automation.PSCredential(($userObject.domainBase + "\" + $userObject.samAccount), $userObject.pswdVer)
    
        Set-AdAccountPassword -Identity $userObject.samAccount -OldPassword $userObject.pswdVer -NewPassword $pswdNew -Server $userObject.dc -Credential $credentials

        Write-Host "Change-Password: Successfully changed password for "$userObject.domainBase"\"$userObject.samAccount

        $userObject.pswdNew = $pswdNew

        return $true
    }
    catch
    {
        #Password not correct
        Write-Host "Running Set-Credentials: failed for above domain."
        Write-Host $_.Exception.Message
        return $false
    }
    
}