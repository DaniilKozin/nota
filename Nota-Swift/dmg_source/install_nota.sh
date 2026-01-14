#!/bin/bash

# Nota Installation Script
# Installs Nota.app and removes Gatekeeper quarantine

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Nota Installation Script v2.1                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Nota.app exists
if [ ! -d "Nota.app" ]; then
    echo -e "${RED}❌ Error: Nota.app not found in current directory${NC}"
    echo ""
    echo "Please run this script from the Nota-Swift directory:"
    echo "  cd Nota-Swift"
    echo "  ./install_nota.sh"
    exit 1
fi

# Get version
VERSION="2.1.0"
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
fi

echo -e "${YELLOW}📦 Installing Nota v${VERSION}...${NC}"
echo ""

# Check if /Applications is writable
if [ ! -w "/Applications" ]; then
    echo -e "${YELLOW}⚠️  /Applications is not writable, will need sudo${NC}"
    USE_SUDO="sudo"
else
    USE_SUDO=""
fi

# Remove old version if exists
if [ -d "/Applications/Nota.app" ]; then
    echo -e "${YELLOW}🗑️  Removing old version...${NC}"
    $USE_SUDO rm -rf "/Applications/Nota.app"
    echo -e "${GREEN}✅ Old version removed${NC}"
fi

# Copy new version
echo -e "${YELLOW}📋 Copying Nota.app to /Applications...${NC}"
$USE_SUDO cp -R "Nota.app" "/Applications/"
echo -e "${GREEN}✅ Copied successfully${NC}"

# Remove quarantine attribute (fixes "damaged" error)
echo ""
echo -e "${YELLOW}🔓 Removing Gatekeeper quarantine...${NC}"
$USE_SUDO xattr -cr "/Applications/Nota.app"
echo -e "${GREEN}✅ Quarantine removed${NC}"

# Verify installation
echo ""
echo -e "${YELLOW}🔍 Verifying installation...${NC}"

if [ -d "/Applications/Nota.app" ]; then
    echo -e "${GREEN}✅ Nota.app installed successfully${NC}"
    
    # Check if executable exists
    if [ -f "/Applications/Nota.app/Contents/MacOS/Nota" ]; then
        echo -e "${GREEN}✅ Executable found${NC}"
        
        # Check permissions
        if [ -x "/Applications/Nota.app/Contents/MacOS/Nota" ]; then
            echo -e "${GREEN}✅ Executable permissions OK${NC}"
        else
            echo -e "${YELLOW}⚠️  Fixing executable permissions...${NC}"
            $USE_SUDO chmod +x "/Applications/Nota.app/Contents/MacOS/Nota"
            echo -e "${GREEN}✅ Permissions fixed${NC}"
        fi
    else
        echo -e "${RED}❌ Executable not found${NC}"
        exit 1
    fi
    
    # Get app size
    APP_SIZE=$(du -sh "/Applications/Nota.app" | cut -f1)
    echo -e "${GREEN}✅ App size: ${APP_SIZE}${NC}"
else
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Installation Complete! 🎉                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Nota v${VERSION} installed successfully!${NC}"
echo ""
echo -e "${YELLOW}🚀 To launch Nota:${NC}"
echo "   1. Press CMD+Space (Spotlight)"
echo "   2. Type 'Nota'"
echo "   3. Press Enter"
echo ""
echo "   Or run: open /Applications/Nota.app"
echo ""
echo -e "${YELLOW}⚙️  First-time setup:${NC}"
echo "   1. Look for microphone icon in menu bar"
echo "   2. Click icon to open mini window"
echo "   3. Click home icon to open Dashboard"
echo "   4. Go to Settings tab"
echo "   5. Enter your OpenAI API key"
echo "   6. Start recording!"
echo ""
echo -e "${YELLOW}🔐 Permissions:${NC}"
echo "   You'll be asked to grant:"
echo "   • Microphone access (required)"
echo "   • Speech Recognition (required)"
echo "   • Accessibility (optional, for hotkeys)"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo "   • Audio setup: See AUDIO_SETUP_GUIDE.md"
echo "   • Troubleshooting: See docs/QUICK_FIX_AUDIO.md"
echo "   • Security: See SECURITY_CHECK.md"
echo ""
echo -e "${GREEN}🎯 Ready to use!${NC}"
echo ""

# Ask if user wants to launch now
read -p "Launch Nota now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}🚀 Launching Nota...${NC}"
    open /Applications/Nota.app
    echo -e "${GREEN}✅ Nota launched! Look for microphone icon in menu bar.${NC}"
fi
