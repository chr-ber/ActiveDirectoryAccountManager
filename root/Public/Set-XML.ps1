function Set-XML($filename)
{
    try{
        $XamlLoader=(New-Object System.Xml.XmlDocument)
        $XamlLoader.Load($filename)
        return $XamlLoader
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
}