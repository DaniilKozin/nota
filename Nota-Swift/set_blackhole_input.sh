#!/bin/bash

# Script to set BlackHole as default input device

echo "🎧 Setting BlackHole 2ch as default input device..."

# This requires SwitchAudioSource utility
# Install with: brew install switchaudio-osx

if command -v SwitchAudioSource &> /dev/null; then
    SwitchAudioSource -s "BlackHole 2ch" -t input
    echo "✅ BlackHole 2ch set as default input"
else
    echo "❌ SwitchAudioSource not found"
    echo "📦 Install with: brew install switchaudio-osx"
    echo ""
    echo "Or manually:"
    echo "1. Open System Settings > Sound"
    echo "2. Go to Input tab"
    echo "3. Select 'BlackHole 2ch'"
fi
