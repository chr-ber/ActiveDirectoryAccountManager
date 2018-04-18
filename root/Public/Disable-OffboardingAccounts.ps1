Function Disable-OffboardingAccounts()
{
    $syncHash.statusBarText.Text = "Diabling offboarding accounts."
    $syncHash.statusBarProgress.IsIndeterminate = $true
    $syncHash.statusBarProgress.Value = 50

    foreach ($userObject in $Global:dbOffboarding)
    {
        # Skip domain entries that are not selected
        If ($userObject.isChecked -eq $true -and ($userObject.pswdVer))
        {
            Set-RunSpaceOffboarding -offboardingListView $Global:offboardingListView -dbOffboarding $Global:dbOffboarding -syncHash $syncHash -adminAccount $userObject.samAccount -pswd $userObject.pswdVer -userAccount $userObject.userAccount -dc $userObject.dc -domainName $userObject.domainName -domainBase $userObject.domainBase -officeDomain $userObject.officeDomain -task disable
        }
        else
        {
            Write-Host "Skipped" $userObject.domainBase"\"$userObject.userAccount
        }
    }
}