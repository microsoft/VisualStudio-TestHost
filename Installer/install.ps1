param($vs, $vsdrop, [switch] $uninstall)

$install_dirs = @(
    "Common7\IDE\PublicAssemblies\Microsoft.VisualStudioTools.VSTestHost.15.0.dll",
    "Common7\IDE\CommonExtensions\Platform\Microsoft.VisualStudioTools.VSTestHost.15.0.pkgdef"
)

$to_delete = $install_dirs | ?{ Test-Path "$vs\$_" } | %{ gi "$vs\$_" }
if ($to_delete) {
    "Cleaning old install..."
    $to_delete | ?{ 'Directory' -in $_.Attributes } | rmdir -Recurse -Force
    $to_delete | ?{ -not ('Directory' -in $_.Attributes) } | del -Force
    if ($uninstall) {
        # Only uninstalling, so run devenv /setup now
        Start-Process -Wait "$vs\Common7\IDE\devenv.exe" "/setup"
    }
}

if (-not $uninstall) {
    $source = $MyInvocation.MyCommand.Definition | Split-Path -Parent
    
    copy -Recurse -Force $vsdrop\engine ${env:Temp}\engine
    
    Set-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\HostAdapters\VSTestHost" -Name "EditorType" -Value "Microsoft.VisualStudioTools.VSTestHost.TesterTestControl, Microsoft.VisualStudioTools.VSTestHost.15.0, Version=15.0.4.0, Culture=neutral, PublicKeyToken=B03F5F7F11D50A3A"
    Set-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\HostAdapters\VSTestHost" -Name "Type" -Value "Microsoft.VisualStudioTools.VSTestHost.TesterTestAdapter, Microsoft.VisualStudioTools.VSTestHost.15.0, Version=15.0.4.0, Culture=neutral, PublicKeyToken=B03F5F7F11D50A3A"
    Set-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\HostAdapters\VSTestHost\SupportedTestTypes" -Name "{13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b}" -Value "Unit Test"
    Set-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\TestTypes\{13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b}\SupportedHostAdapters" -Name "VSTestHost" -Value "VS Test Host Adapter"
    
    & "${env:Temp}\engine\setup.exe" install --catalog "$source\Microsoft.VisualStudioTools.VSTestHost_Sideload.vsman" --installdir "$vs" --layoutdir "$source"
    # devenv /setup is run by setup.exe
}
