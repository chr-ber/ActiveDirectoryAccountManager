Function Get-AllDomainAccounts()
{
    $jobCount = 0
    $Script:usersLoaded = @()
    $syncHash.statusBarText.Text = "Searching domain accounts."
    $syncHash.statusBarProgress.IsIndeterminate = $true
    $syncHash.statusBarProgress.Value = 50

    foreach($domain in $Global:dbUser)
    {
        If($domain.isChecked -eq $true){
            #Start-Job -Name "Get-UserDomainAccounts" -ScriptBlock {param($samAccountName, $dc, $dcCount, $domainName, $officeDomain,  $returnAdmin, $pswdHistory, $whatIf) Get-UsersDomainAccounts $samAccountName $dc $dcCount $domainName $officeDomain $returnAdmin $pswdHistory $whatIf } -InitializationScript $func -ArgumentList($env:USERNAME, $domain.dc, 2, $domain.domainName, $domain.officeDomain, $false, 24, $true)			
            Write-Host $domain.domainName
            RunspacePing -totalJobs $dbUser.Count -userListView $Global:userListView -dbUser $Global:dbUser -syncHash $syncHash -samAccountNAme "cberg" -dc $domain.dc -domainName $domain.domainName -whatIf $true      
            #Set-ProgressBarMain "Loading domain accounts:" $jobCount 100
        }

    }
}