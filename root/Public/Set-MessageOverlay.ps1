Function Set-MessageOverlay
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $msgHeader,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $msgText
    )
    
    [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($syncHash.Window, $msgHeader, $msgText)     
}