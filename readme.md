# Quick Kolbot/SoloPlay Installer

## Why?
Made this because a lot of people have gotten this wrong so this is to make it easy to get set up quickly.

## How to use
### Recommended: Windows Installer (No Git Bash or manual setup required)
- Download and run `KolbotSoloplayInstaller.exe` from the [Releases](https://github.com/theBGuy/kolbot-soloplay-installer/releases) page or from this repo.
- The installer will:
  - Check for and install the Visual C++ Redistributable (x86) if needed
  - Check for and install Git if needed
  - Clone Kolbot and Kolbot-SoloPlay (with submodules)
  - Copy SoloPlay files into the correct Kolbot folder
  - Write the latest commit hashes to a file
  - Create a Start Menu shortcut
  - Provide a proper uninstaller

### Advanced: Shell Script (for Git Bash/PowerShell users)
- Install Git Bash and Git <https://git-scm.com/downloads/win>
- Download this repo
- Open up the repo in Git Bash and run `./installer.sh`

#### Alternative w/o cloning this repo directly
- Open PowerShell and run:
  ```powershell
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/theBGuy/kolbot-soloplay-installer/master/installer.sh" -OutFile "installer.sh"; ./installer.sh
  ```
- Or open cmd and run:
  ```cmd
  curl -sL "https://raw.githubusercontent.com/theBGuy/kolbot-soloplay-installer/master/installer.sh" | bash
  ```

## Requirements
- Windows 7 or later
- Internet connection
- (For script method) git - <https://git-scm.com/downloads/win>

## Troubleshooting
- Try running as admin, this needs privileges to be able to copy the folder contents and write to file
- The installer will prompt you if dependencies are missing and attempt to install them automatically
