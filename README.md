# ActiveDirectoryAccountManager

This client application was created to allow IT engineers to quickly and effectivly change all their Active Directory passwords accross multiple domains.

## Technologies

* [Powershell](https://docs.microsoft.com/en-us/powershell/)
* [XAML](https://docs.microsoft.com/en-us/visualstudio/xaml-tools/xaml-overview)
* [MahApps](https://mahapps.com/)

## How it Works
1. Install the latest

## Requirements
* Powershell 5.0 or later
* [Remote Server Administration Tools](https://docs.microsoft.com/en-us/windows-server/remote/remote-server-administration-tools)
* Port 9389 for [Active Directory Web Services](https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements#system-services-ports) from the client to all domain controllers

## Getting Started
1. Clone the repository and open the [config.csv](https://github.com/ChrisLeeBearger/ActiveDirectoryAccountManager/blob/master/config.csv) file.
2. Remove all of the example domains from the file.
3. Add the domains that should be searched for accounts.
4. If you ensured all the requirements are in place you are done, use adam.exe to start the app.

## Configuration File

|Column| Description | Example |
| ------------- | ------------- | ------------- | 
| DomainName  | The name that is going to be displayed | Contoso |
| DomainController  | Hostname of the domain controller that will be used to change the password | contoso-dc1 |
| DomainBase  | The full qualified domain name  | contoso.lan |
