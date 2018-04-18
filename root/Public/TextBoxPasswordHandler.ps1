Function TextBoxPasswordHandler($key, [SecureString]$pswd, $btn)
{

    # If button was passed
    if ($btn)
    {
        if ($pswd.Length -lt 8)
        {
            $btn.IsEnabled = $false
        }
        else
        {
            $btn.IsEnabled = $true
        }
    }
    $global:pswdCurrent = $pswd
}