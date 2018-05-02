Function Get-AllDomainAccounts()
{
    $syncHash.statusBarText.Text = "Searching domain accounts."
    $syncHash.statusBarProgress.IsIndeterminate = $true
    $syncHash.statusBarProgress.Value = 50

    foreach ($domain in $Global:dbUser)
    {
        If ($domain.isChecked -eq $true)
        {
            RunspacePing -userListView $Global:userListView -dbUser $Global:dbUser -syncHash $syncHash -samAccountName $env:USERNAME -dc $domain.dc -domainName $domain.domainName
        }
    }
}