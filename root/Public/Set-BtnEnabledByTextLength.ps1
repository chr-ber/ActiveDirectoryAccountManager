Function Set-BtnEnabledByTextLength
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $current,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $minimum,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $maximum,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $button
    )   

    # If button was passed
    if ($button)
    {
        if ($current -lt $minimum -or $current -gt $maximum)
        {
            $button.IsEnabled = $false
        }
        else
        {
            $button.IsEnabled = $true
        }
    }

}