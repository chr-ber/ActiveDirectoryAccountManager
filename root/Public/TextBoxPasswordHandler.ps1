Function TextBoxPasswordHandler($key, [SecureString]$pswd, $btn){

    # Checks if there is already an Instance of this Method active, if yes, it will skip 
    If($global:TextBoxHandlerActive){return;}else{$global:TextBoxHandlerActive = $true}             

    # If button was passed
    if($btn){
        if($pswd.Length -lt 8){
            $btn.IsEnabled = $false
        }else{
            $btn.IsEnabled = $true
        }
    }
    Write-Host $btn.IsEnabled
    $global:TextBoxHandlerActive = $false
    $global:pswdCurrent = $pswd
}