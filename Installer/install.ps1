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
    
    "Enabling use of mstest.exe"
    $regroot = mkdir -Force "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\HostAdapters\VSTestHost";
    $regsupporttest = mkdir -Force "HKLM:$regroot\SupportedTestTypes";
    $regunittest = mkdir -Force "HKLM:\Software\WOW6432Node\Microsoft\VisualStudio\15.0\EnterpriseTools\QualityTools\TestTypes\{13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b}";
    $regextensions = mkdir -Force "HKLM:$regunittest\Extensions";
    $regsupporthost = mkdir -Force "HKLM:$regunittest\SupportedHostAdapters";
    Set-ItemProperty HKLM:$regroot -Name "EditorType" -Value "Microsoft.VisualStudioTools.VSTestHost.TesterTestControl, Microsoft.VisualStudioTools.VSTestHost.15.0, Version=15.0.4.0, Culture=neutral, PublicKeyToken=B03F5F7F11D50A3A";
    Set-ItemProperty HKLM:$regroot -Name "Type" -Value "Microsoft.VisualStudioTools.VSTestHost.TesterTestAdapter, Microsoft.VisualStudioTools.VSTestHost.15.0, Version=15.0.4.0, Culture=neutral, PublicKeyToken=B03F5F7F11D50A3A";
    Set-ItemProperty HKLM:$regsupporttest -Name "{13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b}" -Value "Unit Test";
    Set-ItemProperty HKLM:$regunittest -Name "ServiceType" -Value "Microsoft.VisualStudio.TestTools.TestTypes.Unit.SUnitTestService, Microsoft.VisualStudio.QualityTools.Vsip, Version=15.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
    Set-ItemProperty HKLM:$regunittest -Name "NameId" -Value "#212";
    Set-ItemProperty HKLM:$regunittest -Name "SatelliteBasePath" -Value "%ExecutingAssemblyDirectory%";
    Set-ItemProperty HKLM:$regunittest -Name "SatelliteDllName" -Value "Microsoft.VisualStudio.QualityTools.Tips.TuipPackageUI.dll";
    Set-ItemProperty HKLM:$regunittest -Name "VsEditor" -Value "{00000000-0000-0000-0000-000000000000}";
    Set-ItemProperty HKLM:$regunittest -Name "TipProvider" -Value "Microsoft.VisualStudio.TestTools.TestTypes.Unit.UnitTestTip, Microsoft.VisualStudio.QualityTools.Tips.UnitTest.Tip, Version=15.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
    Set-ItemProperty HKLM:$regunittest -Name "RunConfigurationEditorType" -Value "Microsoft.VisualStudio.TestTools.Tips.TuipPackage.UnitTestRunConfigControl, Microsoft.VisualStudio.QualityTools.Tips.TuipPackage, Version=15.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
    Set-ItemProperty HKLM:$regextensions -Name ".dll" -Value 215;
    Set-ItemProperty HKLM:$regextensions -Name ".exe" -Value 215;
    Set-ItemProperty HKLM:$regsupporthost -Name "VSTestHost" -Value "VS Test Host Adapter";
    
    $mstest = [xml](gc "$vs\Common7\IDE\MSTest.exe.config");
    if (-not $mstest.configuration.runtime.assemblyBinding.probing.privatePath.Contains("CommonExtensions\Microsoft\Editor")) {
        "Adding necessary entries to mstest.exe.config"
        $mstest.configuration.runtime.assemblyBinding.probing.privatePath += ";..\..\MSBuild\15.0\Bin;CommonExtensions\Microsoft\Editor";
        $mstest.Save("$vs\Common7\IDE\MSTest.exe.config");
    }
    
    & "${env:Temp}\engine\setup.exe" install --catalog "$source\Microsoft.VisualStudioTools.VSTestHost_Sideload.vsman" --installdir "$vs" --layoutdir "$source"
    # devenv /setup is run by setup.exe
}
