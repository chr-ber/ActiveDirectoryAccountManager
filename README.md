# ActiveDirectoryAccountManager

This desktop application was created to allow IT engineers to quickly and effectively change all their Active Directory passwords across multiple domains.

It is written completley in PowerShell but utilizing .NET Framework classes and assemblies.

![Application Image](https://raw.githubusercontent.com/ChrisLeeBearger/ActiveDirectoryAccountManager/master/doc/app_image_01.png)

## Technologies

* [PowerShell](https://docs.microsoft.com/en-us/PowerShell/)
* [Windows Forms](https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms)
* [XAML](https://docs.microsoft.com/en-us/visualstudio/xaml-tools/xaml-overview)
* [MahApps](https://mahapps.com/)

## Features

* Change all your Active Directory user passwords in one place
* Multiple options for setting the passwords:
  * Set one password for all your accounts (obviously less secure and might conflict with your company’s password policy)
  * Set a different password for each of your accounts
  * Instead of manually typing a password, choose to set one or multiple random passwords, receive it via one of the **Copy to Clipboard** buttons.
* User based settings are stored between sessions
  * Color theme options
  * Window state, position and size
  * **Window stay on top** choice

## How it Works

* Searches user accounts in all configured domains based on the [sAMAccountName](https://docs.microsoft.com/en-us/windows/win32/ad/naming-properties#samaccountname) of the user currently running the app. This means that relevant user accounts are only found in case there is a naming convention applied to the sAMAccountName across all domains. (e.g.  DOMAIN1\\**jdoe**, DOMAIN2\\**jdoe**, DOMAIN3\\**jdoe**,...)
* Current password and new password can be set either for all user accounts at once or individually
* Password can only be changed before expiration. If an expired user account is found it will be automatically unchecked and ignored
* The initial search is performed with the currently logged in user, only if there is a domain trust setup user accounts within other domains are found immediately. If this is not in place the search will be performed again with domain local credentials as soon as a password has been provided
* The password change will be performed with the provided credentials entered in one of the "Current Password" fields. There is no super user required for the app to work
* All credentials are held in memory as [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring)

## Requirements
* [PowerShell](https://docs.microsoft.com/en-us/PowerShell/) 5.0 or later
* [Remote Server Administration Tools](https://docs.microsoft.com/en-us/windows-server/remote/remote-server-administration-tools) installed on the machine that will run the client
* Port 9389 for [Active Directory Web Services](https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements#system-services-ports) opened from the client to all domain controllers

## Getting Started
1. Make sure that all points under requirements are in place
2. Clone the repository and open the [config.csv](https://github.com/ChrisLeeBearger/ActiveDirectoryAccountManager/blob/master/config.csv) file
3. Remove all the example domain entries from the file
4. Add the domains that should be searched for accounts
5. You are done, start the app via adam.exe and begin searching for your user accounts

## Configuration Files

### Global Configuration

The domains need to be configured in the [config.csv](https://github.com/ChrisLeeBearger/ActiveDirectoryAccountManager/blob/master/config.csv) file located in the root folder of the app. It will apply to all users, if each user has a different set of domains its required to have multiple installations of the this repository.

|Column| Description | Example |
| ------------- | ------------- | ------------- | 
| DomainName  | The name that is going to be displayed | Contoso |
| DomainController  | Hostname of the domain controller that will be used to change the password | contoso-dc1 |
| DomainBase  | The full qualified domain name  | contoso.lan |

### User Based Configuration

User based settings are stored under `%appdata%\ActiveDirectoryAccountManager_cberg\userConfig.csv`.

This file is generated on the first close of the application and stores choices made in the settings flyout and various fields of the application window.

![Settings Image](https://raw.githubusercontent.com/ChrisLeeBearger/ActiveDirectoryAccountManager/master/doc/app_image_02_settings.png)

|Column| Description | Default |
| ------------- | ------------- | ------------- | 
| Height  | Window height in pixels | 600 |
| Width  | Window width in pixels | 1200 |
| Top  | Pixel offset from top  | 0 |
| Left  | Pixel offset from left  | 0 |
| ThemeSkin  | Selected base skin (BaseLight, BaseDark) | BaseDark |
| ThemeAccent  | Accent color of the theme  | Cobalt |
| WindowStayTop  | If true, window will position itself on top of other windows, even if focus is lost  | true |
| WindowState  | Specifies whether a window is minimized, maximized, or restored. [WindowState Enum](https://docs.microsoft.com/en-us/dotnet/api/system.windows.windowstate)  | Normal |
