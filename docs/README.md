# Documentation

This folder contains additional documentation, development notes, and implementation details for Nota.

## User Documentation

For end-user documentation, see the main project files:
- [../README.md](../README.md) - Main project README
- [../AUDIO_SETUP_GUIDE.md](../AUDIO_SETUP_GUIDE.md) - Audio configuration guide
- [../SECURITY_CHECK.md](../SECURITY_CHECK.md) - Privacy and security information

## Development Documentation

### Design & Implementation
- [LIQUID_GLASS_IMPLEMENTATION.md](LIQUID_GLASS_IMPLEMENTATION.md) - Apple Liquid Glass 2026 design language implementation details
- [DMG_RELEASE_NOTES.md](DMG_RELEASE_NOTES.md) - Release packaging and distribution notes
- [GATEKEEPER_FIX.md](GATEKEEPER_FIX.md) - Fix "damaged app" error on macOS

### Quick Guides
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide for new users
- [QUICK_FIX_AUDIO.md](QUICK_FIX_AUDIO.md) - Quick audio troubleshooting tips

### Development History
- [FIXES_SUMMARY_JAN14.md](FIXES_SUMMARY_JAN14.md) - Summary of fixes from January 14, 2026
- [AUDIO_FIX_SUMMARY.md](AUDIO_FIX_SUMMARY.md) - Audio system fixes and improvements
- [ICON_FIXES_SUMMARY.md](ICON_FIXES_SUMMARY.md) - Icon synchronization fixes

## Contributing

See [../CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## Project Structure

```
nota/
├── README.md                   # Main project documentation
├── LICENSE                     # MIT License
├── CONTRIBUTING.md             # Contribution guidelines
├── AUDIO_SETUP_GUIDE.md        # Audio configuration guide
├── SECURITY_CHECK.md           # Security and privacy details
├── .gitignore                  # Git ignore rules
├── docs/                       # Additional documentation (this folder)
│   ├── README.md              # This file
│   ├── LIQUID_GLASS_IMPLEMENTATION.md
│   ├── DMG_RELEASE_NOTES.md
│   ├── QUICKSTART.md
│   ├── QUICK_FIX_AUDIO.md
│   ├── FIXES_SUMMARY_JAN14.md
│   ├── AUDIO_FIX_SUMMARY.md
│   └── ICON_FIXES_SUMMARY.md
└── Nota-Swift/                 # Swift application source
    ├── README.md              # Development guide
    ├── Package.swift          # Swift package configuration
    ├── Sources/               # Source code
    ├── icons/                 # Application icons
    ├── build.sh              # Build script
    ├── create_app_bundle.sh  # App bundle creation
    ├── create_dmg.sh         # DMG creation
    └── test_transcription.swift  # Testing utility
```

## Version History

### v2.1 (January 14, 2026)
- GPT-5 Nano/Mini support
- Smart transcription system
- Recording history
- Liquid Glass 2026 design
- Audio device management improvements

See [../Nota-Swift/CHANGELOG.md](../Nota-Swift/CHANGELOG.md) for detailed version history.
