Function Get-AppConfiguration()
{
    ###### Config File
    $configFile = "$scriptLocation\config.csv"
    $config = Import-Csv $configFile
    $Global:rootConfig = @()

    # Build root configuration from config file
    foreach ($line in $config)
    {
        $Global:rootConfig += @([pscustomobject]@{domainName=$line.DomainName;dc=($line.DomainController + "." + $line.DomainBase);domainBase=$line.DomainBase;})
    }

    # Load configuration if file exists
    If((test-path -Path $userConfigFile))
    {
        $userConfig = Import-Csv -Delimiter ";" -Path "$userConfigPath\userConfig.csv"
        $syncHash.Window.Height = $userConfig.Height
        $syncHash.Window.Width = $userConfig.Width
        $syncHash.Window.Top = $userConfig.Top
        $syncHash.Window.Left = $userConfig.Left

        # Assign skins and call Theme Manager
        $syncHash.ThemeSkin = $userConfig.ThemeSkin
        $syncHash.ThemeAccent = $userConfig.ThemeAccent
        [MahApps.Metro.ThemeManager]::ChangeAppStyle($syncHash.Window, ([MahApps.Metro.ThemeManager]::GetAccent($syncHash.ThemeAccent)),  ([MahApps.Metro.ThemeManager]::GetAppTheme($syncHash.ThemeSkin)))

        # Set if window should always stay on top
        $syncHash.Window.Topmost = [System.Convert]::ToBoolean($userConfig.WindowStayTop)
        $toggleIsTop.IsChecked = $syncHash.Window.Topmost

    }

    # Set defaults
    If(!($syncHash.Window.Height))
    {
        $syncHash.Window.Height = 800
    }
    If(!($syncHash.Window.Width))
    {
        $syncHash.Window.Width = 960
    }
    If(!($syncHash.ThemeSkin))
    {
        $syncHash.ThemeSkin = "BaseLight"
    }
    If(!($syncHash.ThemeAccent))
    {
        $syncHash.ThemeAccent = "Cobalt"
    }
    If(($userConfig.WindowStayTop -ne $true -and $userConfig.WindowStayTop -ne $false))
    {
        Write-host "fix shiiit"
        $toggleIsTop.IsChecked = $true
    }
}