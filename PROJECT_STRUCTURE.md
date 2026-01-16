# Nota Project Structure

## 📁 Root Directory

### Main Documentation
- `README.md` - Project overview and getting started
- `LICENSE` - MIT License
- `CHANGELOG_v2.4.0.md` - Current version changelog
- `RELEASE_v2.4.0.md` - Current release notes
- `LANGUAGE_SUPPORT.md` - Language support guide

### Quick Start Guides
- `QUICK_START_GUIDE.md` - Quick start for users
- `AUDIO_SETUP_GUIDE.md` - Audio setup instructions
- `MULTILINGUAL_TEST_CHECKLIST.md` - Testing checklist

## 📁 Nota-Swift/

Main application source code and build scripts.

### Source Code
- `Sources/` - Swift source files
  - `main.swift` - Entry point
  - `AudioRecorder.swift` - Audio recording and transcription
  - `DashboardWindow.swift` - Main dashboard UI
  - `StatusBarController.swift` - Menu bar controller
  - `MiniWindowController.swift` - Mini window UI

### Build & Distribution
- `build.sh` - Build script
- `create_app_bundle.sh` - Create .app bundle
- `create_dmg.sh` - Create DMG installer
- `install_nota.sh` - Installation script
- `VERSION` - Current version (2.4.0)
- `Package.swift` - Swift package manifest

### Testing & Debugging
- `test_transcription.swift` - Test transcription
- `test_audio_capture.swift` - Test audio capture
- `test_mic.swift` - Test microphone
- `check_default_input.swift` - Check audio input
- `monitor_app.sh` - Monitor app logs
- `diagnose_transcription.sh` - Diagnose issues

### Distribution
- `Nota-v2.4.0.dmg` - Latest installer
- `Nota-v2.2.dmg` - Previous stable version
- `Nota.app/` - Built application bundle

## 📁 docs/

Detailed documentation and guides.

### User Guides
- `README.md` - Documentation index
- `QUICKSTART.md` - Quick start guide
- `AUTO_UPDATE.md` - Auto-update guide
- `QUICK_FIX_AUDIO.md` - Audio troubleshooting
- `GATEKEEPER_FIX.md` - macOS Gatekeeper fix

### Technical Documentation
- `MULTILINGUAL_SUPPORT.md` - Multilingual features
- `TEST_RUSSIAN_WHISPER.md` - Russian transcription testing
- `WHAT_CHANGED_v2.4.0_UPDATE.md` - Latest update details
- `ASSEMBLYAI_IMPLEMENTATION.md` - AssemblyAI integration
- `DEEPGRAM_IMPLEMENTATION.md` - Deepgram (deprecated)
- `LIQUID_GLASS_IMPLEMENTATION.md` - UI design

### Development
- `CONTRIBUTING.md` - Contribution guidelines
- `SECURITY_CHECK.md` - Security checklist
- `AGGREGATE_DEVICE_FIX.md` - Audio device fixes

### Archive
- `archive/` - Old documentation
  - `CHANGELOG_v2.2.md` - v2.2 changelog
  - `CHANGELOG_v2.3.md` - v2.3 changelog
  - `CHANGELOG_v2.3.1.md` - v2.3.1 changelog
  - `RELEASE_NOTES_v2.2.md` - v2.2 release notes
  - `TEST_REPORT_v2.2.md` - v2.2 test report
  - `TEST_v2.3.1.md` - v2.3.1 test report
  - `TEST_ASSEMBLYAI_FIX.md` - AssemblyAI fix test

## 📁 releases/

Distribution files and installers (if any).

## 📁 assets/

Images, icons, and other assets.

## 📁 .github/

GitHub-specific files (workflows, issue templates, etc.).

## 📁 .kiro/

Kiro IDE configuration and specs.

### Specs
- `specs/audio-capture-requirements.md` - Audio capture requirements
- `specs/audio-capture-analysis.md` - Audio capture analysis

## 🗂️ File Organization

### Current Version (v2.4.0)
```
/CHANGELOG_v2.4.0.md
/RELEASE_v2.4.0.md
/LANGUAGE_SUPPORT.md
/docs/TEST_RUSSIAN_WHISPER.md
/docs/WHAT_CHANGED_v2.4.0_UPDATE.md
```

### Historical Versions
```
/docs/archive/CHANGELOG_v2.2.md
/docs/archive/CHANGELOG_v2.3.md
/docs/archive/CHANGELOG_v2.3.1.md
/docs/archive/RELEASE_NOTES_v2.2.md
/docs/archive/TEST_REPORT_v2.2.md
/docs/archive/TEST_v2.3.1.md
/docs/archive/TEST_ASSEMBLYAI_FIX.md
```

### User Documentation
```
/README.md
/QUICK_START_GUIDE.md
/AUDIO_SETUP_GUIDE.md
/MULTILINGUAL_TEST_CHECKLIST.md
/docs/QUICKSTART.md
/docs/QUICK_FIX_AUDIO.md
/docs/GATEKEEPER_FIX.md
```

### Technical Documentation
```
/docs/ASSEMBLYAI_IMPLEMENTATION.md
/docs/DEEPGRAM_IMPLEMENTATION.md (deprecated)
/docs/MULTILINGUAL_SUPPORT.md
/docs/LIQUID_GLASS_IMPLEMENTATION.md
/docs/SECURITY_CHECK.md
/docs/AGGREGATE_DEVICE_FIX.md
```

### Development
```
/docs/CONTRIBUTING.md
/.kiro/specs/
/Nota-Swift/test_*.swift
/Nota-Swift/*.sh
```

## 🚀 Quick Navigation

### For Users
1. Start here: `/README.md`
2. Quick start: `/QUICK_START_GUIDE.md`
3. Audio issues: `/AUDIO_SETUP_GUIDE.md` or `/docs/QUICK_FIX_AUDIO.md`
4. Language support: `/LANGUAGE_SUPPORT.md`

### For Developers
1. Build: `/Nota-Swift/build.sh`
2. Test: `/Nota-Swift/test_*.swift`
3. Contributing: `/docs/CONTRIBUTING.md`
4. Specs: `/.kiro/specs/`

### For Testing
1. Russian transcription: `/docs/TEST_RUSSIAN_WHISPER.md`
2. Multilingual: `/MULTILINGUAL_TEST_CHECKLIST.md`
3. Audio capture: `/Nota-Swift/test_audio_capture.swift`

## 📊 Statistics

- **Total Swift files**: 5 main source files
- **Test scripts**: 6 test files
- **Build scripts**: 8 shell scripts
- **Documentation files**: 20+ markdown files
- **Current version**: 2.4.0
- **Last updated**: January 16, 2026

## 🔄 Version Control

- **Repository**: GitHub
- **Branch**: main
- **Latest commit**: v2.4.0 - Context preservation + enhanced logging
- **Status**: ✅ Clean, organized, up to date

## 📝 Notes

- Old documentation moved to `/docs/archive/`
- Current release docs in root directory
- Technical docs in `/docs/`
- All test files in `/Nota-Swift/`
- DMG installers in `/Nota-Swift/`
