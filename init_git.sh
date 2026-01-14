#!/bin/bash

# Nota - Git Repository Initialization Script
# This script initializes the git repository and prepares it for GitHub

set -e

echo "🚀 Initializing Nota Git Repository"
echo "===================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: git is not installed"
    echo "Please install git first: https://git-scm.com/downloads"
    exit 1
fi

# Check if already a git repository
if [ -d ".git" ]; then
    echo "⚠️  Warning: This is already a git repository"
    read -p "Do you want to reinitialize? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
    rm -rf .git
fi

# Initialize git repository
echo "📦 Initializing git repository..."
git init
echo "✅ Git repository initialized"

# Add all files
echo ""
echo "📝 Adding files to git..."
git add .
echo "✅ Files added"

# Show status
echo ""
echo "📊 Git status:"
git status --short

# Create initial commit
echo ""
read -p "Create initial commit? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git commit -m "Initial commit: Nota v2.1

- Native macOS app built with Swift
- Real-time transcription with Speech Recognition
- AI insights with GPT-5 Nano/Mini
- Recording history and project organization
- Liquid Glass 2026 design language
- BlackHole audio device support
- Multi-language support (23 languages)
"
    echo "✅ Initial commit created"
fi

# Rename branch to main
echo ""
echo "🔄 Renaming branch to 'main'..."
git branch -M main
echo "✅ Branch renamed to 'main'"

# Instructions for GitHub
echo ""
echo "🎉 Git repository initialized successfully!"
echo ""
echo "📝 Next steps:"
echo "=============="
echo ""
echo "1. Create a new repository on GitHub:"
echo "   https://github.com/new"
echo ""
echo "2. Add remote and push:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/nota.git"
echo "   git push -u origin main"
echo ""
echo "3. Create a release:"
echo "   git tag v2.1.0"
echo "   git push origin v2.1.0"
echo ""
echo "4. Upload DMG to GitHub Release:"
echo "   Nota-Swift/Nota-v2.1-SmartTranscription.dmg"
echo ""
echo "5. Update README.md:"
echo "   - Replace 'yourusername' with your GitHub username"
echo "   - Update repository URLs"
echo ""
echo "✨ Your project is ready for GitHub!"
