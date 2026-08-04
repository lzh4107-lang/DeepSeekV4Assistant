#define MyAppName "DeepSeek V4 Assistant"
#ifndef AppVersion
  #define AppVersion "0.1.1"
#endif
#define MyAppPublisher "DeepSeek V4 Assistant Project"
#define MyAppExeName "deepseek_v4_assistant.exe"
#define WebView2ClientKey "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

[Setup]
AppId={{9A75E067-67E7-4EEB-A164-A56893827A62}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={code:GetDefaultInstallDir}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=DeepSeekV4Assistant-{#AppVersion}-Windows-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
RestartApplications=no
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
LicenseFile=..\LICENSE
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} installer

[Languages]
Name: "chinesesimp"; MessagesFile: "ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "MicrosoftEdgeWebview2Setup.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NOTICE.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README_ZH_CN.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\MicrosoftEdgeWebview2Setup.exe"; Parameters: "/silent /install"; StatusMsg: "正在安装 Microsoft WebView2..."; Flags: waituntilterminated runascurrentuser; Check: WebView2Missing
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function GetDefaultInstallDir(Param: String): String;
begin
  if DirExists('D:\') then
    Result := 'D:\DeepSeek V4 Assistant'
  else
    Result := ExpandConstant('{localappdata}\Programs\DeepSeek V4 Assistant');
end;

function HasValidVersion(const Value: String): Boolean;
begin
  Result := (Value <> '') and (Value <> '0.0.0.0');
end;

function WebView2Missing(): Boolean;
var
  Version: String;
begin
  Result := True;
  if RegQueryStringValue(HKCU, '{#WebView2ClientKey}', 'pv', Version) and
     HasValidVersion(Version) then
    Result := False;
  if Result and RegQueryStringValue(HKLM32, '{#WebView2ClientKey}', 'pv', Version) and
     HasValidVersion(Version) then
    Result := False;
end;
