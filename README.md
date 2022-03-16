# ActiveDirectoryAccountManager

This application was created to allow IT engineers to quickly and effectivly change all their Active Directory passwords accross multiple domains.

## Technologies

* [MahApps](https://mahapps.com/)
* [XAML](https://docs.microsoft.com/en-us/visualstudio/xaml-tools/xaml-overview?view=vs-2022#:~:text=Extensible%20Application%20Markup%20Language%20(XAML,Universal%20Windows%20Platform%20(UWP)%20apps)
* [Powershell](https://docs.microsoft.com/en-us/powershell/)

## Getting Started

Clone the repository and add your domain relevant information in the [config.csv](https://github.com/ChrisLeeBearger/ActiveDirectoryAccountManager/blob/master/config.csv) file.

Make sure to remove all of the example domains.

|Column| Function |
| ------------- | ------------- |
| DomainName  | The display name  |
| DomainController  | Hostname of the domain controller that will be used to change the password |
| DomainBase  | The full qualified domain name  |
