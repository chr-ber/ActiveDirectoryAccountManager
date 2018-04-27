Clear-Host
# Set manual script location if running in powershell ISE
If (!$PSScriptRoot -or $PSScriptRoot -eq "")
{
    # Replace the location with your location of the root folder
    # If office notebook
    If ($env:COMPUTERNAME -eq "NB0179")
    {
        $Global:scriptLocation = "C:\PowerShell\UCPM"
    }
    # If at home
    else
    {
        $Global:scriptLocation = "C:\PowerShell\UCPM"
    }
}
else
{
    $Global:scriptLocation = $PSScriptRoot
}

#######################################
######## Load all functions and assemblies
##########################

Import-Module "$Global:scriptLocation\root" -Verbose -Force
Set-Assemblies

#######################################
######## Variables
##########################

# Objects that hold user information for each tabItem
$Global:dbUser = @()
$Global:dbAdmin = @()
$Global:dbOffboarding = @()

# Password variables
[SecureString]$Global:pswdCurrent = $null
[SecureString]$Global:pswdNewOne = $null
[SecureString]$Global:pswdNewTwo = $null  

# SyncHash needed to manipulate data out of runspaces
$Global:syncHash = [hashtable]::Synchronized(@{})
$Global:syncHash.activeRunspaces = 0
[System.Collections.ArrayList]$Global:syncHash.activeRunSpaceDomains = @()
# Load xaml and 
$XamlMainWindow = Set-XML("$Global:scriptLocation\resources\main.xaml")
$Reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Global:syncHash.Window = [Windows.Markup.XamlReader]::Load($Reader)

$Global:syncHash.Window.Title = "ADAM - Active Directory Account Manager"

# Grid for displaying results
$Global:userListView = $syncHash.Window.FindName("userListView")
$Global:adminListView = $syncHash.Window.FindName("adminListView")
$Global:offboardingListView = $syncHash.Window.FindName("offboardingListView")

# tab object for switching mode
$syncHash.tabAdmin = $syncHash.Window.FindName("tabAdmin")
$syncHash.statusBarText = $syncHash.Window.FindName("statusBarText")
$syncHash.statusBarProgress = $syncHash.Window.FindName("statusBarProgress")
$syncHash.userBoxDisable = $syncHash.Window.FindName("userBoxDisable")
$syncHash.editDB = $false
$Global:tabControl = $syncHash.Window.FindName("tabControl")
$Global:btnFlyOut = $syncHash.Window.FindName("btnFlyOut")
$syncHash.flyOut = $syncHash.Window.FindName("flyOut")

# Get theme and accent buttons
$btnThemeWhite = $syncHash.Window.FindName("btnThemeBaseLight")
$btnThemeBlack = $syncHash.Window.FindName("btnThemeBaseDark")
$btnAccent = @()
$btnAccent += $syncHash.Window.FindName("btnAccentGreen")
$btnAccent += $syncHash.Window.FindName("btnAccentLime")
$btnAccent += $syncHash.Window.FindName("btnAccentCyan")
$btnAccent += $syncHash.Window.FindName("btnAccentCobalt")
$btnAccent += $syncHash.Window.FindName("btnAccentPurple")
$btnAccent += $syncHash.Window.FindName("btnAccentRed")
$btnAccent += $syncHash.Window.FindName("btnAccentOrange")
$btnAccent += $syncHash.Window.FindName("btnAccentYellow")
$btnAccent += $syncHash.Window.FindName("btnAccentBrown")
$btnAccent += $syncHash.Window.FindName("btnAccentSteel")
$btnAccent += $syncHash.Window.FindName("btnAccentMauve")
$btnAccent += $syncHash.Window.FindName("btnAccentSienna")
# Add color change function to all buttons
$btnAccent | ForEach-Object { $_.Add_Click( {Set-AccentColor $this})}
$btnThemeWhite.Add_Click( {Set-ThemeSkin $this})
$btnThemeBlack.Add_Click( {Set-ThemeSkin $this})

#######################################
######## Password Change tab 
##########################

$searchAccounts = $syncHash.Window.FindName("searchAccounts")
$searchAccounts.Add_Click(
    {
        Get-AllDomainAccounts
    })

$pwdBoxCur = $syncHash.Window.FindName("pwdBoxCur")
$pwdBoxCur.Add_PasswordChanged(
    {	
        TextBoxPasswordHandler $_.KeyCode $pwdBoxCur.SecurePassword $pwdVerBtn
    })

$pwdVerBtn = $syncHash.Window.FindName("pwdVerBtn")
$pwdVerBtn.Add_Click(
    {	
        Test-AllCredentials
    })

$pwdBoxNew1 = $syncHash.Window.FindName("pwdBoxNew1")
$pwdBoxNew2 = $syncHash.Window.FindName("pwdBoxNew2")
$setNewPswdBtn = $syncHash.Window.FindName("setNewPswdBtn")

$pwdBoxNew1.Add_PasswordChanged(
    {	
        Set-SetNewPasswordButton -password1 $pwdBoxNew1.SecurePassword -password2 $pwdBoxNew2.SecurePassword -button $setNewPswdBtn
    })

$pwdBoxNew2.Add_PasswordChanged(
    {	
        Set-SetNewPasswordButton -password1 $pwdBoxNew1.SecurePassword -password2 $pwdBoxNew2.SecurePassword -button $setNewPswdBtn        
    })

$setNewPswdBtn.Add_Click(
    {	
        Set-AllCredentials
    })

$togglePwRnd = $syncHash.Window.FindName("togglePwRnd")
$togglePwInd = $syncHash.Window.FindName("togglePwInd")
$togglePwInd.IsEnabled = $false

$togglePwRnd.Add_Click(
    {	
        # Disable new password boxes
        $pwdBoxNew1.IsEnabled = !$togglePwRnd.IsChecked
        $pwdBoxNew2.IsEnabled = !$togglePwRnd.IsChecked
        # Reset new password box content
        $pwdBoxNew1.Password = ""
        $pwdBoxNew2.Password = ""

        # Enable set password button and option to set password for each account random
        $setNewPswdBtn.IsEnabled = $togglePwRnd.IsChecked
        $togglePwInd.IsEnabled = $togglePwRnd.IsChecked

    })

#######################################
######## Offboarding tab 
##########################

$userBoxDisable = $syncHash.Window.FindName("userBoxDisable")
$userBoxDisable.Add_TextChanged( { Set-BtnEnabledByTextLength -current $userBoxDisable.Text.Length -minimum 5 -maximum 7 -button $btnDisable})
$btnDisable = $syncHash.Window.FindName("btnDisable")
$btnDisable.Add_Click( {Get-OffboardingAccounts})

$passwordBoxCurrent = $syncHash.Window.FindName("passwordBoxCurrent")
$passwordBoxCurrent.Add_PasswordChanged( { TextBoxPasswordHandler $_.KeyCode $passwordBoxCurrent.SecurePassword $btnAdminPswd})
$btnAdminPswd = $syncHash.Window.FindName("btnAdminPswd")

$userBoxTicket = $syncHash.Window.FindName("userBoxTicket")
$userBoxTicket.Add_TextChanged( { Set-BtnEnabledByTicketNumber -text $userBoxTicket.Text -button $btnOffboard})
$btnOffboard = $syncHash.Window.FindName("btnOffboard")

$syncHash.offboToggleDisable = $syncHash.Window.FindName("toggleDisable")
$syncHash.offboToggleRemoveGrps = $syncHash.Window.FindName("toggleRemoveGrps")
$syncHash.offboToggleMoveDis = $syncHash.Window.FindName("toggleMoveDis")

#######################################
######## Fly out
##########################

# toggle switch
$Global:toggleIsTop = $syncHash.Window.FindName("windowStayTop")

#######################################
######## Add_Click
##########################

# Create click event for dynamic button -> set current password
[System.Windows.RoutedEventHandler]$funcTestCredentials = {
    param ($sender, $e)
    Set-PasswordOverlay -dataContext $sender.DataContext
}

# Create click event for dynamic button -> set new password
[System.Windows.RoutedEventHandler]$funcSetCredentials = {
    param ($sender, $e)
    Set-NewPasswordOverlay -dataContext $sender.DataContext
}

$Global:btnFlyOut.Add_Click(
    {
        $syncHash.flyOut.IsOpen = (!($syncHash.flyOut.IsOpen))
    })


$btnAdminPswd.Add_Click(
    {	
        Test-AllCredentials
    })

$btnOffboard.Add_Click(
    {	
        Disable-OffboardingAccounts
    })


$Global:toggleIsTop.Add_Click( {Set-WindowStayTop})

#######################################
######## XML datatemplate and bindings
##########################

##############
# current user tab Datatemp
##############

###### Verify password data template
# Find gridviewcolumn we will attach our datatemplate to
$verifyBtnDataTemp = $syncHash.Window.FindName("verifyBtnDataTemp")

# Create bindings
$bindPwdCurText = New-Object System.Windows.Data.Binding
$bindPwdCurText.path = "pswdVerifyBtnText"
$bindPwdVisibility = New-Object System.Windows.Data.Binding
$bindPwdVisibility.path = "pswdVerifyBtnVisible"
$bindPwdEnabled = New-Object System.Windows.Data.Binding
$bindPwdEnabled.path = "pswdVerifyBtnEnabled"
# Create button factory
$buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent, [System.Windows.RoutedEventHandler]$funcTestCredentials)
# Add bindings
$buttonFactory.SetBinding([System.Windows.Controls.Button]::ContentProperty, $bindPwdCurText)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::VisibilityProperty, $bindPwdVisibility)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::IsEnabledProperty, $bindPwdEnabled)
$verifyBtnDataTemp.CellTemplate.VisualTree = $buttonFactory

###### Set password data template
$setBtnDataTemp = $syncHash.Window.FindName("setBtnDataTemp")

$pswdSetBtnText = New-Object System.Windows.Data.Binding
$pswdSetBtnVisible = New-Object System.Windows.Data.Binding
$pswdSetBtnEnabled = New-Object System.Windows.Data.Binding
$pswdSetBtnText.path = "pswdSetBtnText"
$pswdSetBtnVisible.path = "pswdSetBtnVisible"
$pswdSetBtnEnabled.path = "pswdSetBtnEnabled"

$buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent, [System.Windows.RoutedEventHandler]$funcSetCredentials)
# Add bindings
$buttonFactory.SetBinding([System.Windows.Controls.Button]::ContentProperty, $pswdSetBtnText)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::VisibilityProperty, $pswdSetBtnVisible)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::IsEnabledProperty, $pswdSetBtnEnabled)
$setBtnDataTemp.CellTemplate.VisualTree = $buttonFactory


##############
# offboarding tab Datatemp
##############

# Find gridviewcolumn we will attach our datatemplate to
$adminPswdGrid = $syncHash.Window.FindName("adminPswdGrid")
# Create bindings
$bindPwdCurText.path = "pswdVerifyBtnText"
$bindPwdVisibility.path = "pswdVerifyBtnVisible"
$bindPwdEnabled.path = "pswdVerifyBtnEnabled"
# Create button factory
$buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent, [System.Windows.RoutedEventHandler]$funcTestCredentials)
# Add bindings
$buttonFactory.SetBinding([System.Windows.Controls.Button]::ContentProperty, $bindPwdCurText)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::VisibilityProperty, $bindPwdVisibility)
$buttonFactory.SetBinding([System.Windows.Controls.Button]::IsEnabledProperty, $bindPwdEnabled)
$adminPswdGrid.CellTemplate.VisualTree = $buttonFactory

#######################################
######## Run main functions
##########################

Handle-Configuration -Option load
Reset-App

$async = $syncHash.Window.Dispatcher.InvokeAsync( {
        $syncHash.Window.ShowDialog() | Out-Null
    })
$async.Wait() | Out-Null

Handle-Configuration -Option save