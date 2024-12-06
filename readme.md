# Quick Kolbot/SoloPlay installer

## Why?
Made this because a lot of people have gotten this wrong so this is to make it easy to get set up quickly.

## How to use
- Install Git Bash and Git <https://git-scm.com/downloads/win>
- Download this repo
- Open up the repo in Git Bash and run `.\installer.sh`

## Alternative w/o cloning this repo directly
### WebRequest
- Open PowerShell and run the following command:
  ```powershell
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/theBGuy/kolbot-soloplay-installer/master/installer.sh" -OutFile "installer.sh"; ./installer.sh
  ```

### curl
- Open cmd and run the following command:
  ```bash
  curl -sL "https://raw.githubusercontent.com/theBGuy/kolbot-soloplay-installer/master/installer.sh" | bash
  ```

## Requirments
- git - <https://git-scm.com/downloads/win>

## Troubleshooting
- Try running as admin, this needs privalages to be able to copy the folder contents and write to file
