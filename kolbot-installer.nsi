; Kolbot and SoloPlay Installer Script
; Written by theBGuy

!addplugindir "${NSISDIR}\Plugins"

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; General settings
Name "Kolbot with SoloPlay"
OutFile "KolbotSoloplayInstaller.exe"
InstallDir "$PROGRAMFILES\Kolbot"
RequestExecutionLevel admin

; Interface settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

; Custom page for update confirmation
Var Dialog_Update
Var Label_Update
Var UpdateChoice
Var FreshInstall
Var ExitChoice
Var RestoreData
Var BackupName

Var RadioGroup

Function UpdateChoicePage
  ; Skip this page if no existing installation
  ${IfNot} ${FileExists} "$INSTDIR\kolbot\.git"
    Abort
  ${EndIf}

  !insertmacro MUI_HEADER_TEXT "Installation Options" "An existing Kolbot installation was found"
  
  ; Create dialog with more vertical space
  nsDialogs::Create /NOUNLOAD 1018 
  Pop $Dialog_Update
  ${If} $Dialog_Update == error
    Abort
  ${EndIf}
  
  ; Create group box with increased height and better margins
  ${NSD_CreateGroupBox} 5 5 290 180u "Installation Options"
  Pop $RadioGroup
  
  ; Create label with improved spacing and clarity
  ${NSD_CreateLabel} 15 25 270 35u "What would you like to do with the existing installation at:$\n$INSTDIR"
  Pop $Label_Update
  
  ; Create radio buttons with larger click areas and improved spacing
  ; Increased height and adjusted vertical spacing for better clickability
  ${NSD_CreateRadioButton} 20 75 270 25u "Update existing installation"
  Pop $UpdateChoice
  
  ${NSD_CreateRadioButton} 20 110 270 25u "Perform fresh install (will delete existing installation)"
  Pop $FreshInstall
  
  ${NSD_CreateRadioButton} 20 145 270 25u "Exit without making changes" 
  Pop $ExitChoice
  
  ; Set default selection immediately after creation
  ${NSD_Check} $UpdateChoice
  
  ; Force immediate dialog update for clean rendering
  System::Call 'user32::UpdateWindow(p $Dialog_Update)'
  ShowWindow $Dialog_Update ${SW_SHOW}
  
  nsDialogs::Show
FunctionEnd

Function UpdateChoicePageLeave
  ${NSD_GetState} $UpdateChoice $0      ; Update option
  ${If} $0 == ${BST_CHECKED}
    Return ; Continue with update
  ${EndIf}
  ${NSD_GetState} $FreshInstall $0      ; Fresh install option
  ${If} $0 == ${BST_CHECKED}
    DetailPrint "Creating backup of existing installation..."
    ${GetTime} "" "L" $1 $2 $3 $4 $5 $6 $7
    StrCpy $BackupName "$INSTDIR\backups\kolbot_backup_$3$2$1_$4$5.zip"
    DetailPrint "Creating backup at: $BackupName"
    
    ; Use our CreateBackup function
    Push $BackupName
    Call CreateBackup
    
    ; Preserve user data before deletion
    CreateDirectory "$TEMP\kolbot_userdata"
    DetailPrint "Preserving user data..."
    CopyFiles /SILENT "$INSTDIR\kolbot\data\*.*" "$TEMP\kolbot_userdata\data\"
    CopyFiles /SILENT "$INSTDIR\kolbot\d2bs\kolbot\data\*.*" "$TEMP\kolbot_userdata\kolbot_data\"
    CopyFiles /SILENT "$INSTDIR\kolbot\d2bs\kolbot\mules\*.*" "$TEMP\kolbot_userdata\mules\"
    CopyFiles /SILENT "$INSTDIR\kolbot\d2bs\kolbot\pickit\*.*" "$TEMP\kolbot_userdata\pickit\"
    CopyFiles /SILENT "$INSTDIR\kolbot\d2bs\kolbot\libs\SoloPlay\Data\*.*" "$TEMP\kolbot_userdata\soloplay_data\"
    
    ; Delete existing installation
    RMDir /r "$INSTDIR\kolbot"
    RMDir /r "$INSTDIR\kolbot-SoloPlay"
    
    ; Set flag to restore data after fresh install
    StrCpy $RestoreData "1"
    Return
  ${EndIf}
  
  ${NSD_GetState} $ExitChoice $0        ; Exit option
  ${If} $0 == ${BST_CHECKED}
    MessageBox MB_OK "Installation cancelled. No changes were made."
    Quit ; This will properly exit the installer
  ${EndIf}
FunctionEnd

; Finish page settings
!define MUI_FINISHPAGE_TITLE "Complete Kolbot Installation"
!define MUI_FINISHPAGE_TEXT "Kolbot has been installed successfully.$\n$\nWould you like to create shortcuts?"

!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Start Menu shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateKolbotStartMenuShortcut

!define MUI_FINISHPAGE_RUN ""
!define MUI_FINISHPAGE_RUN_TEXT "Create Desktop shortcut"
!define MUI_FINISHPAGE_RUN_FUNCTION CreateKolbotDesktopShortcut

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom UpdateChoicePage UpdateChoicePageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"

; Init function
Function .onInit
  ; Check if running with admin rights
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "admin"
    MessageBox MB_ICONSTOP "Administrator rights required!"
    Abort
  ${EndIf}
FunctionEnd

; Installation section
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Check for VC++ Redistributable
  DetailPrint "Checking for Visual C++ Redistributable..."
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
  ${If} $0 != 1
    ReadRegDWORD $0 HKLM "SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
    ${If} $0 != 1
      MessageBox MB_YESNO "Visual C++ Redistributable (x86) is required. Download and install now?" IDYES InstallVCRedist IDNO SkipVCRedist
      InstallVCRedist:
        DetailPrint "Downloading Visual C++ Redistributable..."
        NSISdl::download "https://aka.ms/vs/16/release/vc_redist.x86.exe" "$TEMP\vc_redist.x86.exe"
        Pop $0
        ${If} $0 != "success"
          MessageBox MB_ICONSTOP "Failed to download Visual C++ Redistributable. Please install it manually and run the installer again."
          Abort
        ${EndIf}
        DetailPrint "Installing Visual C++ Redistributable..."
        ExecWait '"$TEMP\vc_redist.x86.exe" /quiet /norestart' $0
        ${If} $0 != 0
          MessageBox MB_ICONSTOP "Failed to install Visual C++ Redistributable. Please install it manually and run the installer again."
          Abort
        ${EndIf}
      SkipVCRedist:
    ${EndIf}
  ${EndIf}
  
  ; Check for Git installation
  DetailPrint "Checking for Git..."
  nsExec::ExecToStack '"cmd.exe" /C "where git"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_YESNO "Git is required. Download and install now?" IDYES InstallGit IDNO SkipGit
    InstallGit:
      DetailPrint "Downloading Git..."
      NSISdl::download "https://github.com/git-for-windows/git/releases/download/v2.46.2.windows.1/Git-2.46.2-64-bit.exe" "$TEMP\git-installer.exe"
      Pop $0
      ${If} $0 != "success"
        MessageBox MB_ICONSTOP "Failed to download Git. Please install it manually and run the installer again."
        Abort
      ${EndIf}
      DetailPrint "Installing Git..."
      ExecWait '"$TEMP\git-installer.exe" /VERYSILENT /NORESTART' $0
      ${If} $0 != 0
        MessageBox MB_ICONSTOP "Failed to install Git. Please install it manually and run the installer again."
        Abort
      ${EndIf}
      
      ; Update PATH environment variable
      EnVar::SetHKLM
      EnVar::AddValue "PATH" "$PROGRAMFILES\Git\cmd"
      Pop $0
    SkipGit:
  ${EndIf}    ; Handle Kolbot repository
  ${If} ${FileExists} "$INSTDIR\kolbot\.git"
    DetailPrint "Updating existing Kolbot repository..."
    nsExec::ExecToLog '"cmd.exe" /C "cd $INSTDIR\kolbot && git pull --recurse-submodules"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Failed to update Kolbot repository. Error: $0"
      Abort
    ${EndIf}
  ${Else}
    DetailPrint "Cloning Kolbot repository..."
    nsExec::ExecToLog '"cmd.exe" /C "git clone --recurse-submodules https://github.com/blizzhackers/kolbot.git kolbot"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Failed to clone Kolbot repository. Error: $0"
      Abort
    ${EndIf}
  ${EndIf}
  
  ${If} ${FileExists} "$INSTDIR\kolbot-SoloPlay\.git"
    DetailPrint "Updating existing Kolbot-SoloPlay repository..."
    nsExec::ExecToLog '"cmd.exe" /C "cd $INSTDIR\kolbot-SoloPlay && git pull"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_YESNO "Failed to update Kolbot-SoloPlay repository. Would you like to do a fresh install?" IDYES DoFreshSoloPlay IDNO SkipSoloPlay
      DoFreshSoloPlay:
        RMDir /r "$INSTDIR\kolbot-SoloPlay"
        DetailPrint "Cloning Kolbot-SoloPlay repository..."
        nsExec::ExecToLog '"cmd.exe" /C "git clone https://github.com/blizzhackers/kolbot-SoloPlay.git kolbot-SoloPlay"'
        Pop $0
        ${If} $0 != 0
          MessageBox MB_ICONSTOP "Failed to clone Kolbot-SoloPlay repository. Error: $0"
          Abort
        ${EndIf}
        Goto SoloPlayDone
      SkipSoloPlay:
        Abort
    ${EndIf}
  ${Else}
    DetailPrint "Cloning Kolbot-SoloPlay repository..."
    nsExec::ExecToLog '"cmd.exe" /C "git clone https://github.com/blizzhackers/kolbot-SoloPlay.git kolbot-SoloPlay"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Failed to clone Kolbot-SoloPlay repository. Error: $0"
      Abort
    ${EndIf}
  ${EndIf}
  SoloPlayDone:
  
  ; Get commit hashes
  DetailPrint "Getting commit hashes..."
  nsExec::ExecToStack '"cmd.exe" /C "cd kolbot && git rev-parse HEAD"'
  Pop $0
  Pop $1
  StrCpy $2 $1
  
  nsExec::ExecToStack '"cmd.exe" /C "cd kolbot-SoloPlay && git rev-parse HEAD"'
  Pop $0
  Pop $1
  StrCpy $3 $1
  
  ; Write commit hashes to file
  DetailPrint "Writing commit hashes to file..."
  FileOpen $4 "$INSTDIR\latest_commit_hashes.txt" w
  FileWrite $4 "kolbot latest commit hash: $2$\r$\n"
  FileWrite $4 "kolbot-SoloPlay latest commit hash: $3$\r$\n"
  FileClose $4
    ; Copy files  DetailPrint "Copying SoloPlay files to Kolbot..."
  CreateDirectory "$INSTDIR\kolbot\d2bs\kolbot"
  ; Use xcopy with correct paths - we're already in the install directory
  nsExec::ExecToLog 'cmd.exe /C "xcopy /E /Y /I kolbot-SoloPlay\* kolbot\d2bs\kolbot\"'
  Pop $0
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Failed to copy SoloPlay files. Error: $0"
    Abort
  ${EndIf}
  
  ; Keep kolbot-SoloPlay for future updates  DetailPrint "Setup complete! Note: SoloPlay repository is preserved for future updates."
  
  ; Restore preserved data if this was a fresh install
  ${If} $RestoreData == "1"
    DetailPrint "Restoring preserved user data..."
    CopyFiles /SILENT "$TEMP\kolbot_userdata\data\*.*" "$INSTDIR\kolbot\data\"
    CopyFiles /SILENT "$TEMP\kolbot_userdata\kolbot_data\*.*" "$INSTDIR\kolbot\d2bs\kolbot\data\"
    CopyFiles /SILENT "$TEMP\kolbot_userdata\mules\*.*" "$INSTDIR\kolbot\d2bs\kolbot\mules\"
    CopyFiles /SILENT "$TEMP\kolbot_userdata\pickit\*.*" "$INSTDIR\kolbot\d2bs\kolbot\pickit\"
    CopyFiles /SILENT "$TEMP\kolbot_userdata\soloplay_data\*.*" "$INSTDIR\kolbot\d2bs\kolbot\libs\SoloPlay\Data\"
    
    ; Clean up
    RMDir /r "$TEMP\kolbot_userdata"
    DetailPrint "User data restored successfully"
    DetailPrint "Backup created at: $INSTDIR\$BackupName"
  ${EndIf}
  
  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Function CreateKolbotStartMenuShortcut
  CreateDirectory "$SMPROGRAMS\Kolbot"
  CreateShortcut "$SMPROGRAMS\Kolbot\Kolbot.lnk" "$INSTDIR\kolbot\D2Bot.exe"
FunctionEnd

Function CreateKolbotDesktopShortcut
  CreateShortcut "$DESKTOP\Kolbot.lnk" "$INSTDIR\kolbot\D2Bot.exe"
FunctionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove application files
  RMDir /r "$INSTDIR\kolbot"
  Delete "$INSTDIR\latest_commit_hashes.txt"
  Delete "$INSTDIR\uninstall.exe"
  
  ; Remove shortcuts
  RMDir /r "$SMPROGRAMS\Kolbot"
  
  ; Remove installation directory if empty
  RMDir "$INSTDIR"
SectionEnd

; Function to create backup
Function CreateBackup
  Pop $0 ; Get backup folder name from stack
  DetailPrint "Creating backup: $0"
  
  ; Create backups directory if it doesn't exist
  CreateDirectory "$INSTDIR\backups"
    ; Extract the folder name from the full path (remove .zip extension since we're not zipping anymore)
  ${GetFileName} "$0" $1
  StrCpy $1 "$INSTDIR\backups\$1"
  # Remove .zip extension if present
  ${If} $1 != ""
    StrCpy $2 "$1" "" -4
    ${If} $2 == ".zip"
      StrCpy $1 "$1" -4
    ${EndIf}
  ${EndIf}
  
  DetailPrint "Moving kolbot directory to backup location: $1"
  
  ; Try to rename (move) the directory first as it's faster
  Rename "$INSTDIR\kolbot" "$1"
  ${If} ${Errors}
    ClearErrors
    ; If rename fails (perhaps across drives), try copying
    DetailPrint "Move failed, trying to copy files..."
    CreateDirectory "$1"
    CopyFiles /SILENT "$INSTDIR\kolbot\*.*" "$1\*.*"
    ${If} ${Errors}
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Warning: Failed to backup files.$\nClick OK to continue without backup, or Cancel to abort installation." IDOK continue IDCANCEL abort
      abort:
        Abort
      continue:
        DetailPrint "User chose to continue without backup"
        Return
    ${EndIf}
  ${EndIf}
  
  DetailPrint "Backup completed successfully at: $1"
  Return
FunctionEnd