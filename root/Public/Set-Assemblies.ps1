Function Set-Assemblies()
{
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Data')  | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('System.ComponentModel') | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Data')           | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')        | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      | out-null
    [System.Reflection.Assembly]::LoadFrom($Global:scriptLocation+"\assembly\MahApps.Metro.dll")       | out-null
    [System.Reflection.Assembly]::LoadFrom($Global:scriptLocation+"\assembly\System.Windows.Interactivity.dll") | out-null
}