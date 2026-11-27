; Kairo's Windows installer: Yapfast with Kairo's features, installed as an
; app of its own. make-installer.ps1, beside the repository's root, compiles it
; with Inno Setup from the release build.
;
; It installs for the person running it, without administrator rights. It has
; its own AppId and folder, so it sits beside an official Yapfast rather than
; replacing it, and claims none of Yapfast's links.

#ifndef AppVersion
  #error Compile through make-installer.ps1, which defines AppVersion, VersionNumber and SourceDir
#endif

[Setup]
; Windows knows an installed Kairo by this; never change it.
AppId={{EA23F3ED-97EE-42E2-81DA-17642D512FE0}
AppName=Kairo
AppVersion={#AppVersion}
AppVerName=Kairo {#AppVersion}
AppPublisher=Nobakrec
AppPublisherURL=https://github.com/Nobakrec/Kairo
AppSupportURL=https://github.com/Nobakrec/Kairo/issues
AppUpdatesURL=https://github.com/Nobakrec/Kairo/releases
VersionInfoVersion={#VersionNumber}
; Per user: %LOCALAPPDATA%\Programs\Kairo, with no UAC prompt.
PrivilegesRequired=lowest
DefaultDirName={autopf}\Kairo
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputBaseFilename=Kairo-{#AppVersion}-windows-x64-setup
SetupIconFile=yapfast.ico
UninstallDisplayIcon={app}\yapfast.exe
UninstallDisplayName=Kairo
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
; It keeps running in the tray with its window closed, so an update or
; uninstall closes it rather than asking.
CloseApplications=force
RestartApplications=no
#ifdef LicenseFile
LicenseFile={#LicenseFile}
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Kairo"; Filename: "{app}\yapfast.exe"
Name: "{autodesktop}\Kairo"; Filename: "{app}\yapfast.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\yapfast.exe"; Description: "{cm:LaunchProgram,Kairo}"; Flags: nowait postinstall skipifsilent
