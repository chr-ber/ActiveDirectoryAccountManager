Function Set-Credentials
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$Random = $false,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $userObject,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$WhatIf = $false
    )

    # Check if at least one of the values has been provided
    If (!($Password) -and !($Random))
    {
        Write-Error "Provide either a value for -Password as secure string or set -Random to true."
        return
    }

    if ($Whatif)
    {
        Write-Host "Running WhatIf on Set-Credentials for domain account: " $userObject.samAccount " | domain server: " $userObject.domainDisplayName

        If ($Random -eq $true)
        {
            $newPassword = Get-RandomPassword -Minimum 12 -Maximum 20
            $userObject.pswdNew = $newPassword
            $userObject.clipBoardBtnVisible = "Visible";
            return $true            
        }
        
        If ((Get-Random -Maximum 10) -gt 4)
        {
            $userObject.pswdNew = $Password            
            return $true
        }
        else
        {
            return $false
        }
    }

    try
    {
        Write-Host "Running Set-Credentials: " $userObject.samAccount " | doomain server: " $userObject.domainDisplayName

        $credentials = new-object -typename System.Management.Automation.PSCredential(($userObject.domainName + "\" + $userObject.samAccount), $userObject.pswdVer)
    
        If ($Random -eq $true)
        {
            $loopCount = 0
            do
            {
                try
                {
                    Write-Host "`t Setting unique random password."
                    $newPassword = Get-RandomPassword -Minimum 12 -Maximum 20
                    Set-AdAccountPassword -Identity $userObject.samAccount -OldPassword $userObject.pswdVer -NewPassword $newPassword -Server $userObject.dc -Credential $credentials
                    $userObject.clipBoardBtnVisible = "Visible";
                    
                }

                catch
                {
                    $exception = $_.Exception.Message
                    # Increase node number on domainController
                    $loopCount++
                }
            }While ($exception -match "The password does not meet the length, complexity, or history requirement of the domain" -and $loopCount -le 4)
        }
        else
        {
            $newPassword = $Password
            Set-AdAccountPassword -Identity $userObject.samAccount -OldPassword $userObject.pswdVer -NewPassword $newPassword -Server $userObject.dc -Credential $credentials
        }


        Write-Host "Change-Password: Successfully changed password for "$userObject.domainName"\"$userObject.samAccount

        $userObject.pswdNew = $newPassword

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