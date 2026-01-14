# Nota - AI Meeting Recorder

<div align="center">

![Nota Icon](assets/nota-icon.png)

**Smart transcription and AI-powered meeting analysis for macOS**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Download](https://img.shields.io/badge/Download-v2.1.0-brightgreen.svg)](releases/Nota-v2.1.dmg)

[Download](#-download) • [Features](#-features) • [Installation](#-installation) • [Documentation](#-documentation)

</div>

---

## 🎯 Overview

Nota is a native macOS application that provides real-time transcription and AI-powered analysis of meetings, conversations, and audio recordings. Built with Swift for optimal performance.

### Key Features

- 🎤 **Live Transcription** - Real-time speech-to-text using Apple's Speech Recognition
- 🤖 **AI Insights** - Smart analysis with GPT-5 Nano/Mini
- 💬 **Messenger-Style Display** - Incremental transcript bubbles
- 📊 **Recording History** - Automatic session saving
- 🏢 **Project Organization** - Auto-categorization by keywords
- 🌍 **Multi-Language** - Support for 23 languages
- 🔊 **Advanced Audio** - BlackHole aggregate device support
- 🎨 **Native macOS Design** - Liquid Glass inspired interface
- 🔄 **Auto-Updates** - GitHub release notifications

---

## 📥 Download

**Latest Release: v2.1.0**

[⬇️ Download Nota-v2.1.dmg](releases/Nota-v2.1.dmg) (2.6 MB)

### System Requirements
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- Microphone access
- Internet connection (for AI features)

---

## 🚀 Installation

### Quick Install

1. **Download** [Nota-v2.1.dmg](releases/Nota-v2.1.dmg)
2. **Open** the DMG file
3. **Drag** Nota.app to Applications folder
4. **Right-click** Nota.app → **Open** (first time only)
5. **Grant permissions** when prompted (Microphone, Speech Recognition)

### First Launch

If you see "Nota is damaged" error:
```bash
xattr -cr /Applications/Nota.app
open /Applications/Nota.app
```

See [docs/GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) for details.

---

## ⚙️ Setup

1. Click the **microphone icon** in menu bar
2. Open **Dashboard** (home icon)
3. Go to **Settings** tab
4. Enter your **OpenAI API key** ([get one here](https://platform.openai.com))
5. Choose **GPT-5 Nano** (recommended) or **GPT-5 Mini**
6. Select your **audio device** and **language**
7. Start recording!

---

## 💡 Features

### Smart Transcription
- Real-time transcription every 6 seconds
- AI insights generation every 45 seconds
- Messenger-style incremental bubbles
- Multi-language support (23 languages)

### AI Analysis
- Meeting summary
- Action items with SMART criteria
- Key insights and observations
- Topics discussed
- Decisions made
- Sentiment analysis
- Keywords extraction
- Company identification
- Meeting type detection

### Recording Management
- Automatic session saving (up to 50 sessions)
- Recording history with metadata
- Project organization with keywords
- Auto-assignment to projects
- Export transcripts

---

## 💰 Pricing

Nota is **free and open source**. You only pay for OpenAI API usage:

| Model | Input | Output | Typical 1h Meeting |
|-------|-------|--------|-------------------|
| **GPT-5 Nano** (recommended) | $0.05/1M tokens | $0.40/1M tokens | $0.01-0.05 |
| **GPT-5 Mini** | $0.25/1M tokens | $2.00/1M tokens | $0.05-0.15 |

---

## 📚 Documentation

- [AUDIO_SETUP_GUIDE.md](AUDIO_SETUP_GUIDE.md) - Audio configuration with BlackHole
- [docs/GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) - Fix "damaged app" error
- [docs/AGGREGATE_DEVICE_FIX.md](docs/AGGREGATE_DEVICE_FIX.md) - Fix microphone passthrough
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) - How to contribute
- [docs/SECURITY_CHECK.md](docs/SECURITY_CHECK.md) - Privacy and security
- [Nota-Swift/README.md](Nota-Swift/README.md) - Development guide

---

## 🔐 Privacy & Security

- ✅ **All data stored locally** on your Mac
- ✅ **No analytics or telemetry**
- ✅ **No data sent to developer**
- ✅ **API keys stored securely** in UserDefaults
- ✅ **Transcripts only sent to OpenAI** with your key
- ✅ **Open source** - verify the code yourself

---

## 🛠️ Building from Source

```bash
# Clone repository
git clone https://github.com/DaniilKozin/nota.git
cd nota/Nota-Swift

# Build release version
swift build -c release

# Create app bundle
./create_app_bundle.sh

# Create DMG (optional)
./create_simple_dmg.sh
```

See [Nota-Swift/README.md](Nota-Swift/README.md) for development details.

---

## 🤝 Contributing

Contributions are welcome! See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

---

## 🆘 Troubleshooting

### No transcription appearing
- Grant **Microphone** permission in System Settings
- Grant **Speech Recognition** permission in System Settings
- Check that microphone is working

### No AI insights
- Add **OpenAI API key** in Settings
- Verify API key is valid (starts with `sk-`)
- Check internet connection

### Partner can't hear me in calls
- See [docs/AGGREGATE_DEVICE_FIX.md](docs/AGGREGATE_DEVICE_FIX.md)
- Create Multi-Output Device in Audio MIDI Setup
- Or use BlackHole virtual audio driver

### App crashes when opening Settings
- Update to latest version
- Try restarting the app

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

- [OpenAI](https://openai.com) - GPT-5 API
- [BlackHole](https://github.com/ExistentialAudio/BlackHole) - Virtual audio driver
- Apple - Speech Recognition Framework

---

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)

---

<div align="center">

**Built with ❤️ using Swift for optimal macOS performance**

[⬆ Back to Top](#nota---ai-meeting-recorder)

</div>
