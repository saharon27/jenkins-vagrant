# set keyboard layout.
# NB you can get the name from the list:
#      [Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the welcome screen culture and keyboard layout.
# NB the .DEFAULT key is for the local SYSTEM account (S-1-5-18).
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
'Control Panel\International','Keyboard Layout' | ForEach-Object {
    Remove-Item -Path "HKU:.DEFAULT\$_" -Recurse -Force
    Copy-Item -Path "HKCU:$_" -Destination "HKU:.DEFAULT\$_" -Recurse -Force
}

# set the timezone.
# tzutil /l lists all available timezone ids
& $env:windir\system32\tzutil /s "GMT Standard Time"

# show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show protected operating system files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSuperHidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# set the desktop wallpaper.
Add-Type -AssemblyName System.Drawing
$backgroundColor = [System.Drawing.Color]::FromArgb(75, 117, 139) #4b758b
$logo = [System.Drawing.Image]::FromFile((Resolve-Path 'jenkins.png'))
$b = New-Object System.Drawing.Bitmap($logo.Width, $logo.Height)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear($backgroundColor)
$g.DrawImage($logo, 0, 0, $logo.Width, $logo.Height)
$b.Save('C:\Windows\Web\Wallpaper\Windows\jenkins.png')
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name Wallpaper -Value C:\Windows\Web\Wallpaper\Windows\jenkins.png
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name WallpaperStyle -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name TileWallpaper -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Colors' -Name Background -Value ($backgroundColor.R,$backgroundColor.G,$backgroundColor.B -join ' ')

# cleanup the taskbar by removing the existing buttons and unpinning all applications; once the user logs on.
# NB the shell executes these RunOnce commands about ~10s after the user logs on.
[IO.File]::WriteAllText(
    "$env:USERPROFILE\ConfigureDesktop.ps1",
@'
# unpin all applications from the taskbar.
# NB this can only be done in a logged on session.
$pinnedTaskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
(New-Object -Com Shell.Application).NameSpace($pinnedTaskbarPath).Items() `
    | ForEach-Object {
        $unpinVerb = $_.Verbs() | Where-Object { $_.Name -eq 'Unpin from tas&kbar' }
        if ($unpinVerb) {
            $unpinVerb.DoIt()
        } else {
            $shortcut = (New-Object -Com WScript.Shell).CreateShortcut($_.Path)
            if (!$shortcut.TargetPath -and ($shortcut.IconLocation -eq '%windir%\explorer.exe,0')) {
                Remove-Item -Force $_.Path
            }
        }
    }
Get-Item HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband `
    | Set-ItemProperty -Name Favorites -Value 0xff `
    | Set-ItemProperty -Name FavoritesResolve -Value 0xff `
    | Set-ItemProperty -Name FavoritesVersion -Value 3 `
    | Set-ItemProperty -Name FavoritesChanges -Value 1 `
    | Set-ItemProperty -Name FavoritesRemovedChanges -Value 1

# hide the search button.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

# hide the task view button.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0

# never combine the taskbar buttons.
# possibe values:
#   0: always combine and hide labels (default)
#   1: combine when taskbar is full
#   2: never combine
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 2

# remove default or uneeded files.
@(
    "$env:USERPROFILE\Desktop\desktop.ini"
    "$env:USERPROFILE\Desktop\*.lnk"
    "$env:USERPROFILE\Desktop\*.url"
    "$env:PUBLIC\Desktop\desktop.ini"
    "$env:PUBLIC\Desktop\*.lnk"
    "$env:PUBLIC\Desktop\*.url"
) | Remove-Item -Force

# execute hooks.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Get-ChildItem "$PSScriptRoot\ConfigureDesktop-*.ps1" `
    | Sort-Object -Property Name `
    | ForEach-Object { &$_ }

# restart explorer to apply the changed settings.
(Get-Process explorer).Kill()
'@)
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\RunOnce -Force `
    | New-ItemProperty -Name ConfigureDesktop -Value 'PowerShell -WindowStyle Hidden -File "%USERPROFILE%\ConfigureDesktop.ps1"' -PropertyType ExpandString `
    | Out-Null

# set default Explorer location to This PC.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null

# install classic shell.
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu -Force `
    | New-ItemProperty -Name ShowedStyle2      -Value 1 -PropertyType DWORD `
    | Out-Null
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu\Settings -Force `
    | New-ItemProperty -Name EnableStartButton -Value 1 -PropertyType DWORD `
    | New-ItemProperty -Name SkipMetro         -Value 1 -PropertyType DWORD `
    | Out-Null
choco install -y classic-shell -installArgs ADDLOCAL=ClassicStartMenu

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
choco install -y googlechrome
$chromeLocation = 'C:\Program Files (x86)\Google\Chrome\Application'
cp -Force GoogleChrome-external_extensions.json (Get-Item "$chromeLocation\*\default_apps\external_extensions.json").FullName
cp -Force GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# install useful applications.
choco install -y 7zip
choco install -y notepad2
choco install -y visualstudiocode

# we uninstall defender because it takes way too much resources for what its worth.
Write-Host 'Uninstalling Windows Defender...'
Uninstall-WindowsFeature Windows-Defender-Features