function Set-RunSpaceContentToClipBoard
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $syncHash,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$password,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [boolean]$random,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $clearAfterSeconds,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $content
    )

    $syncHash.Host = $host
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "UseNewThread"
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
    $Runspace.SessionStateProxy.SetVariable("clearAfterSeconds", $clearAfterSeconds)    
    $Runspace.SessionStateProxy.SetVariable("content", $content)

    If ($random -eq $true)
    {
        $Runspace.SessionStateProxy.SetVariable("password", $syncHash.randomPassword)    
    }
    else
    {
        $Runspace.SessionStateProxy.SetVariable("password", $password)    
    }
    


    While ($syncHash.clipBoardRunspace -gt 0)
    {
        Start-Sleep -Milliseconds 250
    }
    $syncHash.clipBoardRunspace++
    While ($syncHash.clipBoardRunspace -gt 2)
    {
        Start-Sleep -Milliseconds 500
        $syncHash.clipBoardRunspace--
        return
    }

    $code = {

        If (($password))
        {
            ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) | clip.exe

        }
        elseif (($content))
        {
            Set-Clipboard -Value $content
        }
        else
        {
            Write-Error "-Password and -Content have been null, please provide value for one of the paramters."
        }

        $syncHash.Window.Dispatcher.invoke([action] {
                $syncHash.statusBarText.Text = "Copied password to clipboard."
            })

        for ($i = 0; $i -le $clearAfterSeconds; $i += 0.250)
        {
            # Close runspace if another clipboard runspace has been opened
            If ($syncHash.clipBoardRunspace -gt 1)
            {
                $syncHash.clipBoardRunspace--
                return
            }
            $syncHash.Window.Dispatcher.invoke([action] {
                    $syncHash.statusBarProgress.Value = $i / $clearAfterSeconds * 100
                })
            Start-Sleep -Milliseconds 250
        }
        [System.Windows.Forms.Clipboard]::Clear()

        #Refresh the gui if the last Runspace has finished
        $syncHash.Window.Dispatcher.invoke([action] {
                $syncHash.statusBarText.Text = "Cleared clipboard."
                $syncHash.statusBarProgress.Value = 0
            })
        $syncHash.clipBoardRunspace--
    }
    $PSinstance = [powershell]::Create().AddScript($code)
    $PSinstance.Runspace = $Runspace
    $PSinstance.BeginInvoke()
}