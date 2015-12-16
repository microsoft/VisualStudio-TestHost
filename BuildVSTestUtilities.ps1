$vsVersions = @{"14.0" = "2015"; "12.0" = "2013";  "11.0"= "2012"}

foreach($ver in $vsVersions.GetEnumerator())
{
    $versionNumber = $ver.Key
    $versionName = $ver.Value
    msbuild VSTestUtilities.sln /P:VSTarget="$versionNumber" /P:Configuration=Release /P:Platform=x86
    VSTestUtilities\Build\nuget pack VSTestUtilities\VSTestUtilities.nuspec `
					/Prop VSTarget="$versionNumber" `
					/Prop VSVersion="$versionName" `
					/OutputDirectory VSTestUtilities\BuildOutput
}


