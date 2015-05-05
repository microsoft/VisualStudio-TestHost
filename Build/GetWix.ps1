function Get-Wix {
    param($target)

    Write-Output "Downloading Wix to $target"

    $file = [IO.Path]::GetTempFileName()
    Write-Output "  - temporary storage: $file"

    Invoke-WebRequest "https://wix.codeplex.com/downloads/get/1421697" -UseBasicParsing -OutFile $file

    [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($file, $target)

    del $file
}
