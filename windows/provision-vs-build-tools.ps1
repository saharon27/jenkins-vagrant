# add support for building .net applications.
# NB we have to install netfx-4.7.1-devpack manually, because for some odd reason,
#    the setup is returning the -1073741819 exit code even thou it installs
#    successfully.
$archiveUrl = 'https://packages.chocolatey.org/netfx-4.7.1-devpack.4.7.2558.0.nupkg'
$archiveHash = 'e293769f03da7a42ed72d37a92304854c4a61db279987fc459d3ec7aaffecf93'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName.zip"
Write-Host 'Downloading the netfx-4.7.1-devpack package...'
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Expand-Archive $archivePath "$archivePath.tmp"
Push-Location "$archivePath.tmp"
Remove-Item -Recurse _rels,package,*.xml
Set-Content -Encoding Ascii `
    tools/ChocolateyInstall.ps1 `
    ((Get-Content tools/ChocolateyInstall.ps1) -replace '0, # success','0,-1073741819, # success')
choco pack
choco install -y netfx-4.7.1-devpack -Source $PWD
Pop-Location
choco install -y netfx-4.5.2-devpack

# install NuGet.
# NB MSBuild from the build tools does not have nuget integration (i.e.
#    there is no support for the restore target), as such, we need nuget.
choco install -y nuget.commandline

# install the Visual Studio Build Tools.
# see https://www.visualstudio.com/downloads/
# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/11226569/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe'
$archiveHash = '32bd244943c662af28a5e70a05996be09171c92d3cee22e512d91bbe7ce91065'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Build Tools Setup Bootstrapper...'
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing the Visual Studio Build Tools...'
$vsBuildToolsHome = 'C:\VS2017BuildTools'
for ($try = 1; ; ++$try) {
    &$archivePath `
        --installPath $vsBuildToolsHome `
        --add Microsoft.VisualStudio.Workload.MSBuildTools `
        --add Microsoft.VisualStudio.Workload.NetCoreBuildTools `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.VC.CLI.Support `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop `
        --norestart `
        --quiet `
        --wait `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        if ($try -le 5) {
            Write-Host "Failed to install the Visual Studio Build Tools with Exit Code $LASTEXITCODE. Trying again (hopefully the error was transient)..."
            Start-Sleep -Seconds 10
            continue
        }
        throw "Failed to install the Visual Studio Build Tools with Exit Code $LASTEXITCODE"
    }
    break
}

# add MSBuild to the machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$vsBuildToolsHome\MSBuild\15.0\Bin",
    'Machine')