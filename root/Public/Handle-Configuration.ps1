﻿Function Handle-Configuration {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Option
    )

    ###### Domain configuration file
    $configFile = "$Global:scriptLocation\config.csv"
    $config = Import-Csv $configFile
    $Global:rootConfig = @()

    ################# Window configuration file
    $userConfigFolder = "ActiveDirectoryAccountManager_cberg"
    $userConfigPath = "$env:APPDATA\$userConfigFolder"
    $userConfigFile = "$userConfigPath\userConfig.csv"

    If ($Option -eq "load") {

        # Build root configuration from config file
        foreach ($line in $config) {
            $Global:rootConfig += @([pscustomobject]@{domainDisplayName = $line.DomainDisplayName; dc = ($line.DomainController + "." + $line.DomainName); domainName = $line.DomainName;})
        }

        # Load configuration if file exists
        If ((test-path -Path $userConfigFile)) {
            $userConfig = Import-Csv -Delimiter ";" -Path "$userConfigPath\userConfig.csv"
            $syncHash.Window.Height = $userConfig.Height
            $syncHash.Window.Width = $userConfig.Width
            $syncHash.Window.Top = $userConfig.Top
            $syncHash.Window.Left = $userConfig.Left

            # Assign skins and call Theme Manager
            $syncHash.ThemeSkin = $userConfig.ThemeSkin
            $syncHash.ThemeAccent = $userConfig.ThemeAccent
            $syncHash.Window.WindowState = $userConfig.WindowState
            [MahApps.Metro.ThemeManager]::ChangeAppStyle($syncHash.Window, ([MahApps.Metro.ThemeManager]::GetAccent($syncHash.ThemeAccent)), ([MahApps.Metro.ThemeManager]::GetAppTheme($syncHash.ThemeSkin)))

            # Set if window should always stay on top
            $syncHash.Window.Topmost = [System.Convert]::ToBoolean($userConfig.WindowStayTop)
            $toggleIsTop.IsChecked = $syncHash.Window.Topmost

        }
        else {      
            # Set defaults
            $syncHash.Window.Height = 600
            $syncHash.Window.WindowState = "Normal"
            $syncHash.Window.Width = 1200
            $syncHash.ThemeSkin = "BaseDark"
            $syncHash.ThemeAccent = "Cobalt"
            $syncHash.Window.Top = 0
            $syncHash.Window.Left = 0
            $toggleIsTop.IsChecked = $true
        }
    }

    If ($Option -eq "save") {
        # Safe window settings
        $userConfig = @([pscustomobject]@{"Height" = $syncHash.Window.ActualHeight;      
                "Width"                            = $syncHash.Window.ActualWidth;
                "Top"                              = $syncHash.Window.Top;      
                "Left"                             = $syncHash.Window.Left;
                "ThemeSkin"                        = $syncHash.ThemeSkin;
                "ThemeAccent"                      = $syncHash.ThemeAccent;
                "WindowStayTop"                    = $toggleIsTop.IsChecked;
                "WindowState"                      = $syncHash.Window.WindowState
            })
        # Create folder
        If (!(Test-path -path $userConfigPath)) {
            New-Item -ItemType directory -Path $userConfigPath
        }

        $userConfig | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | out-file $userConfigFile
    }
}