# Nota - AI Meeting Recorder

<div align="center">

![Nota Icon](Nota-Swift/icons/icon.png)

**Smart transcription and AI-powered meeting analysis for macOS**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#-features-in-detail) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🎯 Overview

Nota is a native macOS application that provides real-time transcription and AI-powered analysis of meetings, conversations, and audio recordings. Built with Swift for optimal performance and featuring Apple's Liquid Glass 2026 design language.

### Key Features

- 🎤 **Live Transcription** - Real-time speech-to-text using Apple's Speech Recognition
- 🤖 **AI Insights** - Smart analysis with GPT-5 Nano/Mini
- 💬 **Messenger-Style Bubbles** - Incremental transcript display
- 📊 **Recording History** - Automatic session saving and management
- 🏢 **Project Organization** - Auto-categorization by keywords
- 🎨 **Liquid Glass Design** - Modern macOS design language
- 🌍 **Multi-Language** - Support for 23 languages
- 🔊 **Advanced Audio** - BlackHole aggregate device support
- 🔄 **Auto-Updates** - Automatic update notifications from GitHub

---

## 📦 Installation

### Download

Download the latest release from [Releases](../../releases) page.

Or build from source (see [Building from Source](#-building-from-source)).

### Install

**Method 1: Automatic (Recommended)**

1. Mount the DMG file
2. Open Terminal
3. Drag `install_nota.sh` to Terminal window
4. Press Enter and follow prompts

**Method 2: Manual**

1. Mount the DMG file
2. Drag **Nota.app** to **Applications** folder
3. Open Terminal and run:
   ```bash
   xattr -cr /Applications/Nota.app
   open /Applications/Nota.app
   ```

**Method 3: Right-click**

1. Drag **Nota.app** to **Applications** folder
2. Right-click (or Control+click) on Nota.app
3. Select **"Open"** from menu
4. Click **"Open"** in the dialog

> **Note:** If you see "Nota is damaged" error, this is macOS Gatekeeper blocking unsigned apps. Use one of the methods above to bypass it. See [docs/GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) for details.

### First-Time Setup

1. Grant permissions when prompted:
   - Microphone access (required)
   - Speech Recognition (required)
   - Accessibility (optional, for hotkeys)
2. Click the microphone icon in menu bar
3. Open Dashboard (home icon)
4. Go to **Settings** tab
5. Enter your **OpenAI API key** ([get one here](https://platform.openai.com))
6. Choose **GPT-5 Nano** (recommended) or **GPT-5 Mini**
7. Start recording!

---

## 🚀 Usage

### Quick Start

1. **Click** the microphone icon in menu bar
2. **Click Record** button in mini window
3. **Speak** or join a meeting
4. **Watch** live transcription appear
5. **Click Stop** when done
6. **View** insights and history in Dashboard

### Capturing Both Sides of a Call

To record both your voice and your meeting partner's voice:

1. Install [BlackHole](https://github.com/ExistentialAudio/BlackHole)
2. Create Aggregate Device in **Audio MIDI Setup**:
   - Include: Built-in Microphone + BlackHole 2ch
   - Set Clock Source: Built-in Microphone
3. Set as system input: **System Settings → Sound → Input**
4. In Zoom/Teams:
   - Input: Aggregate Device
   - Output: BlackHole 2ch

See [AUDIO_SETUP_GUIDE.md](AUDIO_SETUP_GUIDE.md) for detailed instructions.

---

## 💰 Pricing

Nota is **free and open source**. You only pay for OpenAI API usage:

| Model | Input | Output | Typical 1h Meeting |
|-------|-------|--------|-------------------|
| **GPT-5 Nano** (recommended) | $0.05/1M tokens | $0.40/1M tokens | $0.01-0.05 |
| **GPT-5 Mini** | $0.25/1M tokens | $2.00/1M tokens | $0.05-0.15 |

---

## 🎨 Features in Detail

### Smart Transcription
- Real-time transcription every 6 seconds
- AI insights generation every 45 seconds
- Messenger-style incremental bubbles
- Automatic sentence segmentation
- Multi-language support (23 languages)

### AI Analysis
- Meeting summary (1-2 paragraphs)
- Action items with SMART criteria
- Key insights and observations
- Topics discussed
- Decisions made
- Questions raised
- Sentiment analysis
- **Keywords extraction** (new in v2.1)
- **Company identification** (new in v2.1)
- **Meeting type detection** (new in v2.1)

### Recording Management
- Automatic session saving (up to 50 sessions)
- Recording history with metadata
- Project organization with keywords
- Auto-assignment to projects
- Continue from previous session
- Export transcripts

### Interface
- **Mini Window** (380x280) - Compact floating interface
- **Dashboard** - Full-featured management interface
- **Liquid Glass 2026** - Modern design language
- **Dark Mode** - Automatic adaptation
- **Retina Display** - Optimized for high-DPI

---

## 📚 Documentation

- [AUDIO_SETUP_GUIDE.md](AUDIO_SETUP_GUIDE.md) - Detailed audio configuration with BlackHole
- [SECURITY_CHECK.md](SECURITY_CHECK.md) - Privacy and security details
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute to the project
- [Nota-Swift/README.md](Nota-Swift/README.md) - Development guide

### Additional Documentation

- [docs/GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) - Fix "damaged app" error
- [docs/AUTO_UPDATE.md](docs/AUTO_UPDATE.md) - Auto-update system documentation
- [docs/LIQUID_GLASS_IMPLEMENTATION.md](docs/LIQUID_GLASS_IMPLEMENTATION.md) - Design guidelines
- [docs/DMG_RELEASE_NOTES.md](docs/DMG_RELEASE_NOTES.md) - Release information
- [docs/QUICKSTART.md](docs/QUICKSTART.md) - Quick start guide
- [docs/QUICK_FIX_AUDIO.md](docs/QUICK_FIX_AUDIO.md) - Audio troubleshooting

---

## 🔐 Privacy & Security

- ✅ **All data stored locally** on your Mac
- ✅ **No analytics or telemetry**
- ✅ **No data sent to developer**
- ✅ **API keys stored securely** in Keychain
- ✅ **Transcripts only sent to OpenAI** with your key
- ✅ **Open source** - verify the code yourself

### Data Locations
- Settings: `~/Library/Preferences/com.daniilkozin.nota.plist`
- Recordings: `~/Library/Application Support/com.daniilkozin.nota/`

---

## 🛠️ Building from Source

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build Steps

```bash
# Clone repository
git clone https://github.com/yourusername/nota.git
cd nota/Nota-Swift

# Build release version
swift build -c release

# Create app bundle
./create_app_bundle.sh

# Create DMG (optional)
./create_dmg.sh
```

### Development

```bash
# Build debug version
swift build

# Run tests
swift test

# Open in Xcode
open Package.swift
```

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start for Contributors

```bash
# Fork and clone
git clone https://github.com/yourusername/nota.git
cd nota/Nota-Swift

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
swift build
./create_app_bundle.sh

# Commit and push
git commit -m "feat: your feature description"
git push origin feature/your-feature
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📝 Changelog

### v2.1 (January 14, 2026)
- ✅ GPT-5 Nano/Mini support
- ✅ Smart transcription (6s intervals)
- ✅ Insights generation (45s intervals)
- ✅ Messenger-style bubbles
- ✅ Recording history system
- ✅ Project organization
- ✅ Keywords and meeting type detection
- ✅ Liquid Glass 2026 design
- ✅ Audio device management
- ✅ Icon consistency fixes
- ✅ Settings tab in Dashboard

### v2.0 (January 2026)
- Complete Swift rewrite
- Native macOS performance
- Mini window interface
- Dashboard with analytics

### v1.0 (December 2025)
- Initial release
- Basic transcription
- OpenAI integration

---

## 🆘 Troubleshooting

### No transcription appearing
- Check microphone permissions in System Settings
- Verify Speech Recognition is authorized
- Ensure microphone is working

### No AI insights
- Add OpenAI API key in Settings
- Verify API key is valid (starts with `sk-`)
- Check internet connection

### Can't hear meeting partner
- Set up aggregate device (see [AUDIO_SETUP_GUIDE.md](AUDIO_SETUP_GUIDE.md))
- Verify Zoom/Teams output = BlackHole
- Check System Settings → Sound → Input

### Partner can't hear me
- Verify Zoom/Teams input = Aggregate Device (NOT BlackHole)
- Check microphone is included in aggregate device
- Test microphone in System Settings

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

- [OpenAI](https://openai.com) - GPT-5 API
- [BlackHole](https://github.com/ExistentialAudio/BlackHole) - Virtual audio driver
- Apple - Speech Recognition Framework
- Swift Community

---

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: See [docs/](docs/) folder

---

<div align="center">

**Built with ❤️ using Swift for optimal macOS performance**

[⬆ Back to Top](#nota---ai-meeting-recorder)

</div>
