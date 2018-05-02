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
$syncHash.statusBarBorder = $syncHash.Window.FindName("statusBarBorder")
# Put statusbar content in the right Z order
[System.Windows.Controls.Canvas]::SetZIndex($syncHash.statusBarBorder, 1)
[System.Windows.Controls.Canvas]::SetZIndex($syncHash.statusBarProgress, 2)

# Reset current active tab results
$btnResetSearch = $syncHash.Window.FindName("btnResetSearch")
$btnResetSearch.Add_Click(
    {
        Reset-App
    })

$syncHash.userBoxDisable = $syncHash.Window.FindName("userBoxDisable")
$syncHash.editDB = $false
$syncHash.clipBoardRunspace = 0
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

$Global:btnSearchAccounts = $syncHash.Window.FindName("btnSearchAccounts")
$btnSearchAccounts.Add_Click(
    {
        Get-AllDomainAccounts
        $btnSearchAccounts.IsEnabled = $false
        $pwdBoxCur.IsEnabled = $true
        $pwdBoxNew1.IsEnabled = $true
        $pwdBoxNew2.IsEnabled = $true
        $togglePwRnd.IsEnabled = $true
    })

$Global:pwdBoxCur = $syncHash.Window.FindName("pwdBoxCur")
$pwdBoxCur.Add_PasswordChanged(
    {	
        TextBoxPasswordHandler $_.KeyCode $pwdBoxCur.SecurePassword $pwdVerBtn
    })

$pwdBoxCur.Add_KeyDown( {
        param ($sender, $e)
        if ($e.Key -eq 'Return' -or $e.Key -eq 'Enter')
        {
            Test-AllCredentials
        }
    })

$Global:pwdVerBtn = $syncHash.Window.FindName("pwdVerBtn")
$pwdVerBtn.Add_Click(
    {	
        Test-AllCredentials
    })

$Global:pwdBoxNew1 = $syncHash.Window.FindName("pwdBoxNew1")
$Global:pwdBoxNew2 = $syncHash.Window.FindName("pwdBoxNew2")
$Global:setNewPswdBtn = $syncHash.Window.FindName("setNewPswdBtn")
$Global:btnCopyToClip = $syncHash.Window.FindName("btnCopyToClip")

$pwdBoxNew1.Add_PasswordChanged(
    {	
        Set-SetNewPasswordButton -password1 $pwdBoxNew1.SecurePassword -password2 $pwdBoxNew2.SecurePassword -button $setNewPswdBtn
    })

$pwdBoxNew2.Add_PasswordChanged(
    {	
        Set-SetNewPasswordButton -password1 $pwdBoxNew1.SecurePassword -password2 $pwdBoxNew2.SecurePassword -button $setNewPswdBtn        
    })

$pwdBoxNew1.Add_KeyDown( {	
        param ($sender, $e)
        if ($setNewPswdBtn.IsEnabled -eq $true -and ($e.Key -eq 'Return' -or $e.Key -eq 'Enter'))
        {
            Set-AllCredentials $togglePwRnd $togglePwInd
        }
    })

$pwdBoxNew2.Add_KeyDown( {	
        param ($sender, $e)
        if ($setNewPswdBtn.IsEnabled -eq $true -and ($e.Key -eq 'Return' -or $e.Key -eq 'Enter'))
        {
            Set-AllCredentials $togglePwRnd $togglePwInd
        }
    })

$setNewPswdBtn.Add_Click(
    {	
        Set-AllCredentials $togglePwRnd $togglePwInd
    })

$btnCopyToClip.Add_Click(
    {	
        Set-RunSpaceContentToClipBoard -password $Global:pwdBoxNew1.SecurePassword -syncHash $syncHash -clearAfterSeconds 5 -random $Global:togglePwRnd.IsChecked
    })

$Global:togglePwRnd = $syncHash.Window.FindName("togglePwRnd")
$Global:togglePwInd = $syncHash.Window.FindName("togglePwInd")
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

$Global:userBoxDisable = $syncHash.Window.FindName("userBoxDisable")
$userBoxDisable.Add_TextChanged( { Set-BtnEnabledByTextLength -current $userBoxDisable.Text.Length -minimum 5 -maximum 7 -button $btnDisable})
$Global:btnDisable = $syncHash.Window.FindName("btnDisable")
$btnDisable.Add_Click( {Get-OffboardingAccounts})

$Global:passwordBoxCurrent = $syncHash.Window.FindName("passwordBoxCurrent")
$passwordBoxCurrent.Add_PasswordChanged( { TextBoxPasswordHandler $_.KeyCode $passwordBoxCurrent.SecurePassword $btnAdminPswd})
$Global:btnAdminPswd = $syncHash.Window.FindName("btnAdminPswd")

$Global:userBoxTicket = $syncHash.Window.FindName("userBoxTicket")
$userBoxTicket.Add_TextChanged( { Set-BtnEnabledByTicketNumber -text $userBoxTicket.Text -button $Global:btnOffboard})
$Global:btnOffboard = $syncHash.Window.FindName("btnOffboard")

$Global:btnOffboardToClip = $syncHash.Window.FindName("btnOffboardToClip")
$btnOffboardToClip.Add_Click( {
        #Set-Clipboard -Value $syncHash.offboardingMessage
        $syncHash.offboardingMessage | clip.exe
    })

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
    param ($sender)
    Set-PasswordOverlay -dataContext $sender.DataContext
}

# Create click event for dynamic button -> set new password
[System.Windows.RoutedEventHandler]$funcSetCredentials = {
    param ($sender)
    Set-NewPasswordOverlay -dataContext $sender.DataContext
}

# Create click event for dynamic button -> copy password to clip board
[System.Windows.RoutedEventHandler]$funcCopyToClipBoard = {
    param ($sender)
    Set-RunSpaceContentToClipBoard -password $sender.DataContext.pswdNew -syncHash $syncHash -clearAfterSeconds 5 
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

###### Clip board data template
$dataTempClipBoard = $syncHash.Window.FindName("dataTempClipBoard")
$clipBoardBtnVisible = New-Object System.Windows.Data.Binding
$clipBoardBtnVisible.path = "clipBoardBtnVisible"
$buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent, [System.Windows.RoutedEventHandler]$funcCopyToClipBoard)
$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Copy to clip board")
# Add bindings
$buttonFactory.SetBinding([System.Windows.Controls.Button]::VisibilityProperty, $clipBoardBtnVisible)
$dataTempClipBoard.CellTemplate.VisualTree = $buttonFactory


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