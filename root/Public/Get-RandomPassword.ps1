Function Get-RandomPassword
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Length,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Minimum,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Maximum,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$AsPlainText = $false
    )
        
    If (!($Length))
    {
        If (($Minimum) -and ($Maximum)) 
        {
            $Length = Get-Random -Minimum $Minimum -Maximum $Maximum
        }
    }
        

    # Create string that holds all possible characters
    $pswdChars = (([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126))) + 0..9 | Where-Object {$_ -notlike '&'} | Sort-Object {Get-Random})
    [String]$pswdTmp = ""

    # Go through for loop amount of times set by password length
    for ($i = 0; $i -lt $Length; $i++)
    {
        # Get-Random character from char string
        $rnd = Get-Random -Minimum 0 -Maximum $pswdChars.Length
        # Add selected random character to the password string
        $pswdTmp += $pswdChars[$rnd]
    }
    
    # Build the password variable
    If ($AsPlainText -eq $true)
    {
        $pswd = $pswdTmp
    }
    else
    {
        [SecureString]$pswd = ConvertTo-SecureString -String $pswdTmp -AsPlainText -Force
    }
    #Write-Host $pswd.GetType()
    return $pswd
}