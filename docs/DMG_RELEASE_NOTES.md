# Nota v2.1 - DMG Release Notes

## 📦 Release Information

**Version:** 2.1 - Smart Transcription Edition  
**Date:** January 14, 2026  
**File:** `Nota-v2.1-SmartTranscription.dmg`  
**Size:** 2.6 MB  
**Platform:** macOS 13.0 (Ventura) or later  

---

## ✅ Security Verification

### Pre-Release Security Check
- ✅ **No API keys** in binary
- ✅ **No personal data** (emails, names, addresses)
- ✅ **No hardcoded credentials**
- ✅ **test_apis.swift deleted** (contained test keys)
- ✅ **All user data stored locally** (UserDefaults + Application Support)
- ✅ **No analytics or telemetry**
- ✅ **No data sent to developer**

### What's Included in DMG
```
Nota v2.1/
├── Nota.app (4.0 MB)
│   ├── Contents/
│   │   ├── MacOS/Nota (binary)
│   │   ├── Resources/
│   │   │   ├── AppIcon.icns
│   │   │   ├── tray-18x18.png
│   │   │   ├── tray-22x22.png
│   │   │   ├── tray-36x36.png
│   │   │   └── tray-icon.png
│   │   └── Info.plist
│   └── PkgInfo
├── Applications (symlink)
└── README.txt (comprehensive guide)
```

### What's NOT Included
❌ API keys  
❌ User settings  
❌ Recording history  
❌ Personal data  
❌ Configuration files  

---

## 🚀 Distribution Instructions

### For Sharing:
1. Upload `Nota-v2.1-SmartTranscription.dmg` to:
   - Google Drive
   - Dropbox
   - GitHub Releases
   - File sharing service

2. Share download link with users

3. Users will:
   - Download DMG
   - Mount DMG
   - Drag Nota.app to Applications
   - Configure their own API keys

### For Users:

#### Installation:
```bash
1. Download Nota-v2.1-SmartTranscription.dmg
2. Double-click to mount
3. Drag Nota.app to Applications folder
4. Open Nota from Applications or Spotlight
```

#### First-Time Setup:
```bash
1. Grant permissions:
   - Microphone (required)
   - Speech Recognition (required)
   - Accessibility (optional, for hotkeys)

2. Configure API key:
   - Open Dashboard
   - Go to Settings tab
   - Enter OpenAI API key
   - Choose GPT-5 Nano (recommended)

3. Start recording!
```

---

## 🎯 Key Features

### Smart Transcription
- ✅ Live transcription every 6 seconds
- ✅ AI insights every 45 seconds
- ✅ Messenger-style transcript bubbles
- ✅ Incremental updates (not restart from beginning)

### GPT-5 Integration
- ✅ GPT-5 Nano ($0.05/$0.40 per 1M tokens) - Default
- ✅ GPT-5 Mini ($0.25/$2.00 per 1M tokens) - Optional
- ✅ Smart token management
- ✅ Cost-efficient processing

### Recording Management
- ✅ Recording history with sessions
- ✅ Project organization with keywords
- ✅ Auto-assignment by keywords
- ✅ Meeting type detection
- ✅ Company identification

### Audio Support
- ✅ Built-in microphone
- ✅ External microphones
- ✅ BlackHole aggregate devices
- ✅ Multi-channel support
- ✅ 48kHz sample rate

### Design
- ✅ Liquid Glass 2026 design language
- ✅ Compact mini window (380x280)
- ✅ Full Dashboard with analytics
- ✅ Dark mode support
- ✅ Retina display optimized

### Languages
- ✅ 23 languages supported
- ✅ Auto-detection
- ✅ Multi-language meetings

---

## 💰 Pricing

### OpenAI GPT-5 (User's API Key)
| Model | Input | Output | Typical 1h Meeting |
|-------|-------|--------|-------------------|
| GPT-5 Nano | $0.05/1M | $0.40/1M | $0.01-0.05 |
| GPT-5 Mini | $0.25/1M | $2.00/1M | $0.05-0.15 |

**Recommendation:** Use GPT-5 Nano for best cost/performance ratio.

---

## 🔐 Privacy & Security

### Data Storage
- **Settings:** `~/Library/Preferences/com.daniilkozin.nota.plist`
- **Recordings:** `~/Library/Application Support/com.daniilkozin.nota/`
- **All data:** Stored locally on user's Mac

### Data Transmission
- **To OpenAI:** Only transcripts for analysis (with user's API key)
- **To Developer:** Nothing (no analytics, no telemetry)
- **To Third Parties:** None

### User Control
- ✅ Users configure their own API keys
- ✅ Users control their data
- ✅ Users can delete all data anytime
- ✅ Open source - code can be verified

---

## 🆘 Troubleshooting

### Common Issues:

**1. No transcription appearing**
- Check microphone permissions in System Settings
- Verify Speech Recognition is authorized
- Check that microphone is working

**2. No AI insights**
- Add OpenAI API key in Settings
- Verify API key is valid (starts with sk-)
- Check internet connection

**3. Can't hear meeting partner**
- Set up aggregate device (see Audio Setup Guide)
- Verify Zoom/Teams output = BlackHole
- Check System Settings → Sound → Input

**4. Partner can't hear me**
- Verify Zoom/Teams input = Aggregate Device (NOT BlackHole)
- Check microphone is included in aggregate device
- Test microphone in System Settings

**5. App won't open**
- Right-click → Open (first time only)
- Check macOS version (13.0+ required)
- Check Console.app for error logs

---

## 📚 Documentation

### Included in Repository:
- `README.md` - Project overview
- `AUDIO_SETUP_GUIDE.md` - Detailed audio configuration
- `QUICK_FIX_AUDIO.md` - Quick troubleshooting
- `SECURITY_CHECK.md` - Privacy and security details
- `FIXES_SUMMARY_JAN14.md` - Recent fixes and improvements
- `ICON_FIXES_SUMMARY.md` - Icon system documentation

### In DMG:
- `README.txt` - Comprehensive user guide

---

## 🔄 Version History

### v2.1 (January 14, 2026)
- ✅ GPT-5 Nano/Mini support
- ✅ Smart transcription (6s intervals)
- ✅ Insights generation (45s intervals)
- ✅ Messenger-style bubbles
- ✅ Recording history system
- ✅ Project organization
- ✅ Liquid Glass 2026 design
- ✅ Audio device management
- ✅ Keywords and meeting type detection
- ✅ Synchronized AudioRecorder across Dashboard and MiniWindow
- ✅ Icon consistency fixes
- ✅ Settings tab in Dashboard
- ✅ Improved audio device support

### v2.0 (January 2026)
- Complete Swift rewrite
- Native macOS performance
- Liquid Glass design language
- Mini window interface
- Dashboard with analytics

### v1.0 (December 2025)
- Initial release
- Basic transcription
- OpenAI integration

---

## 📞 Support

### Getting Help:
1. Check README.txt in DMG
2. Read documentation in repository
3. Open issue on GitHub
4. Check Console.app for error logs

### Reporting Issues:
- Include macOS version
- Include Nota version
- Include error messages from Console.app
- Describe steps to reproduce

---

## 🎉 Ready for Distribution!

**DMG File:** `Nota-v2.1-SmartTranscription.dmg`  
**Size:** 2.6 MB  
**Security:** ✅ Verified clean  
**Status:** ✅ Ready to share  

### Next Steps:
1. Upload DMG to file sharing
2. Share download link
3. Users download and install
4. Each user configures their own API keys
5. Start recording meetings!

---

**Built with ❤️ using Swift for optimal macOS performance**  
**Version 2.1 - January 14, 2026**
