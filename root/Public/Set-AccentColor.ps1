Function Set-AccentColor ($sender)
{
    # Use the btn name to turn it into the name of the accent
    $syncHash.ThemeAccent = $sender.Name -replace "btnAccent", ""
    #Use Mahapps ThemeManager class to change the current theme depending on the selection
    [MahApps.Metro.ThemeManager]::ChangeAppStyle($syncHash.Window, ([MahApps.Metro.ThemeManager]::GetAccent($syncHash.ThemeAccent)),  ([MahApps.Metro.ThemeManager]::GetAppTheme($syncHash.ThemeSkin)))
}