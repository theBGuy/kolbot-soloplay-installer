#!/bin/bash

# Ensure the script has execute permissions
chmod +x "$0"

# Check if git is installed
if ! command -v git &> /dev/null
then
    echo "git could not be found. Attempting to install git..."
    if [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        echo "Downloading Git installer for Windows..."
        curl -LO https://github.com/git-for-windows/git/releases/download/v2.46.2.windows.1/Git-2.46.2-64-bit.exe
        echo "Running Git installer..."
        ./Git-2.34.1-64-bit.exe /VERYSILENT /NORESTART
        rm Git-2.46.2-64-bit.exe
    else
        echo "Unsupported OS. Please install git manually."
        exit 1
    fi

    # Verify git installation
    if ! command -v git &> /dev/null
    then
        echo "git installation failed. Please install git manually from https://git-scm.com/download/win."
        exit 1
    fi
fi

# Function to check if Visual C++ Redistributable (x86) is installed
check_vc_redist_x86() {
    local keys=(
        "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
        "HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
        "HKLM\SOFTWARE\Microsoft\DevDiv\VC\Servicing\14.0\RuntimeMinimum"
        "HKLM\SOFTWARE\Wow6432Node\Microsoft\DevDiv\VC\Servicing\14.0\RuntimeMinimum"
    )
    for key in "${keys[@]}"; do
        if reg query "$key" &> /dev/null; then
            return 0
        fi
    done
    return 1
}

# Check if Visual C++ Redistributable (x86) is installed
if ! check_vc_redist_x86
then
    echo "Visual C++ 2010 Redistributable (x86) not found."
    echo "Open mvc-redistributable and run vcredist_x86.exe then re-run"
    read -p "Press enter to continue..."
    exit 1
fi

# the repository URLs
KOLBOT_REPO="https://github.com/blizzhackers/kolbot.git"
SOLOPLAY_REPO="https://github.com/blizzhackers/kolbot-SoloPlay.git"

# the directories to clone into
KOLBOT_DIR="kolbot"
SOLOPLAY_DIR="kolbot-SoloPlay"

# Clone the repositories
echo "Cloning kolbot repository..."
git clone --recurse-submodules $KOLBOT_REPO $KOLBOT_DIR

echo "Cloning kolbot-SoloPlay repository..."
git clone $SOLOPLAY_REPO $SOLOPLAY_DIR

# Get the latest commit hashes
KOLBOT_COMMIT_HASH=$(git -C $KOLBOT_DIR rev-parse HEAD)
SOLOPLAY_COMMIT_HASH=$(git -C $SOLOPLAY_DIR rev-parse HEAD)

# Write the commit hashes to a file
echo "kolbot latest commit hash: $KOLBOT_COMMIT_HASH" > latest_commit_hashes.txt
echo "kolbot-SoloPlay latest commit hash: $SOLOPLAY_COMMIT_HASH" >> latest_commit_hashes.txt

# Copy the contents of kolbot-SoloPlay into kolbot
echo "Copying contents of kolbot-SoloPlay into kolbot..."
cp -r $SOLOPLAY_DIR/* $KOLBOT_DIR/d2bs/kolbot/

# Clean up
echo "Cleaning up..."
rm -rf $SOLOPLAY_DIR

echo "Done!"

# Pause until a key is pressed
read -p "Press enter to continue..."