Function Set-BtnEnabledByTicketNumber
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $text,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $button
    )   
    
    # Compare value to regular expression, string must begin with TSK or INC and have minimum of 4 digits
    if ($text -notmatch '[I,i,T,t][S,s,N,n][K,k,C,c]\d\d\d\d\d*')
    {
        $button.IsEnabled = $false
    }
    else
    {
        $button.IsEnabled = $true
        $Global:syncHash.ticketNumber = $text
    }
}