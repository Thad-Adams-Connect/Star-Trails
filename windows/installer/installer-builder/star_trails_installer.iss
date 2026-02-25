[Setup]
AppName=Star Trails
AppVersion=1.0.0
AppPublisher=Ubertas Lab, LLC
LicenseFile=..\LICENSE.txt
DefaultDirName={autopf}\Star Trails
DefaultGroupName=Star Trails
OutputDir=..\installer\output
OutputBaseFilename=StarTrails_Setup_v1.0.0
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=C:\Users\thada\OneDrive\Documents\Repositories\Star Trails\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\star_trails.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "C:\Users\thada\OneDrive\Documents\Repositories\Star Trails\build\windows\x64\runner\Release\star_trails.exe"; DestDir: "{app}"
Source: "C:\Users\thada\OneDrive\Documents\Repositories\Star Trails\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"
Source: "C:\Users\thada\OneDrive\Documents\Repositories\Star Trails\build\windows\x64\runner\Release\native_assets.json"; DestDir: "{app}"
Source: "C:\Users\thada\OneDrive\Documents\Repositories\Star Trails\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Star Trails"; Filename: "{app}\star_trails.exe"
Name: "{group}\Uninstall Star Trails"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Star Trails"; Filename: "{app}\star_trails.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\star_trails.exe"; Description: "Launch Star Trails"; Flags: nowait postinstall skipifsilent
