param([string] $options, [switch] $sign, [switch] $mocksign, [switch] $rebuild)

if ($rebuild) {
    $buildtarget = "Rebuild"
} else {
    $buildtarget = "Build"
}

if (-not (get-command msbuild -EA 0)) {
    Write-Error "Visual Studio build tools are required."
    exit 1
}

$projectDir = Split-Path -parent $MyInvocation.MyCommand.Definition

if (-not $outdir) {
    $outdir = "$projectDir"
}
Write-Output "Writing output MSIs to $outdir"

Remove-Item $projectdir\BuildOutput\*.nupkg

$vsVersions = @(
    @{v="16.0"; year="2019"},
    @{v="15.0"; year="2017"},
    @{v="14.0"; year="2015"},
    @{v="12.0"; year="2013"},
    @{v="11.0"; year="2012"}
) | ?{
    if ([Environment]::Is64BitOperatingSystem) {
        $vs_path = ((gp "HKLM:\Software\Wow6432Node\Microsoft\VisualStudio\SxS\VS7")."$($_.v)")
    } else {
        $vs_path = ((gp "HKLM:\Software\Microsoft\VisualStudio\SxS\VS7")."$($_.v)")
    }
    return $vs_path -and (Test-Path "$vs_path\Common7\IDE\devenv.exe");
}

foreach($ver in $vsVersions) {
    $versionNumber = $ver.Key
    $versionName = $ver.Value
    msbuild $projectDir\VSTestUtilities\Utilities.UI\TestUtilities.UI.csproj `
        /fl /flp:logfile="$projectDir\VSTestUtilities.build.log" `
        /t:$buildtarget `
        /v:m `
        /nologo `
        /p:VSTarget="$($ver.v)" `
        /p:Configuration=Release `
        /p:Platform=x86 `
        $options
    if (-not $?) {
        Throw "Build failed"
    }
}

$dllsource = "raw"

if ($sign -or $mocksign) {
    Write-Output "Submitting signing job"
    if ($sign) {
        Import-Module -force $projectDir\Build\BuildReleaseHelpers.psm1
    } else {
        Import-Module -force $projectDir\Build\BuildReleaseMockHelpers.psm1
    }
    
    $approvers = "smortaz", "dinov", "stevdo", "pminaev", "gilbertw", "huvalo", "crwilcox"
    $approvers = @($approvers | Where-Object {$_ -ne $env:USERNAME})

    $dlljobs = @()
    foreach($ver in $vsVersions) {
        $dllfiles = @(
            Get-ChildItem "$projectDir\BuildOutput\Release$($ver.v)\raw\Microsoft.VisualStudioTools.TestUtilities*.dll", "$projectDir\BuildOutput\Release$($ver.v)\raw\Microsoft.VisualStudioTools.MockVsTests*.dll" `
            | %{ @{path=$_.FullName; name=$_.Name} }
        )
        $destdir = "$outdir\BuildOutput\Release$($ver.v)\signed"
        $dlljobs += begin_sign_files $dllfiles $destdir $approvers "VS Test Host $($ver.year)" `
            "https://github.com/Microsoft/VisualStudio-TestHost" `
            "VS Test Host" "Visual Studio; test" "authenticode;strongname"
    }

    end_sign_files $dlljobs
    $dllsource = "signed"
}

foreach($ver in $vsVersions) {
    Build\nuget pack `
        "$projectDir\VSTestUtilities\VSTestUtilities.nuspec" `
        /OutputDirectory (mkdir "$projectDir\BuildOutput\Release$($ver.v)\pkg" -Force) `
        /Prop VSTarget="$($ver.v)" `
        /Prop VSVersion="$($ver.year)" `
        /Prop Source="$dllsource"
    if (-not $?) {
        Throw "Build failed"
    }
}


if ($sign -or $mocksign) {
    Write-Output "Submitting nupkg signing job"
    $pkgjobs = @()
    foreach($ver in $vsVersions) {
        $pkgfiles = @(Get-ChildItem "$projectDir\BuildOutput\Release$($ver.v)\pkg\*.nupkg" | %{ @{path=$_.FullName; name=$_.Name } })
        $pkgjobs += begin_sign_files $pkgfiles $outdir $approvers "VS Test Utilities Nuget Packages" `
            "https://github.com/Microsoft/VisualStudio-TestHost" `
            "VS Test Host" "Visual Studio; test" "vsix"
    }
    end_sign_files $pkgjobs
} else {
    Copy-Item "$projectDir\BuildOutput\Release*\pkg\*.nupkg" $outdir
}

Write-Output ""
Write-Output " *"
Write-Output " * Final nupkgs:"
Write-Output " *   $((gci $outdir\*.nupkg) -join '
 *   ')"
Write-Output " *"
Write-Output ""



