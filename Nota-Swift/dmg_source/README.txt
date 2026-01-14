╔═══════════════════════════════════════════════════════════════╗
║                  Nota v2.1.0 - AI Meeting Recorder              ║
║                    Smart Transcription Edition                ║
╚═══════════════════════════════════════════════════════════════╝

📦 INSTALLATION (IMPORTANT!)
════════════════════════════
⚠️  To avoid "damaged and can't be opened" error:

METHOD 1 (Recommended - Automatic):
1. Open Terminal (Applications → Utilities → Terminal)
2. Drag install_nota.sh to Terminal window
3. Press Enter
4. Follow the prompts

METHOD 2 (Manual):
1. Drag Nota.app to Applications folder
2. Open Terminal (Applications → Utilities → Terminal)
3. Run: xattr -cr /Applications/Nota.app
4. Run: open /Applications/Nota.app

METHOD 3 (Right-click):
1. Drag Nota.app to Applications folder
2. Right-click (or Control+click) on Nota.app
3. Select "Open" from menu
4. Click "Open" in the dialog

WHY THIS HAPPENS:
macOS Gatekeeper blocks apps from unidentified developers.
The commands above tell macOS to trust this app.

🔐 SECURITY NOTE:
This app is open source and safe. The "damaged" message is
just macOS being cautious about apps without Apple Developer
certificate (9/year). You can verify the source code on GitHub.

🚀 QUICK START
═══════════════
1. Look for microphone icon in menu bar
2. Click icon to open mini window
3. Click Record button to start
4. Speak or join a meeting
5. Watch live transcription appear
6. Click Stop when done
7. View insights and history in Dashboard

⚙️ FIRST-TIME SETUP
═══════════════════
1. Open Dashboard (home icon in mini window)
2. Go to Settings tab
3. Enter your OpenAI API key (get from platform.openai.com)
4. Choose GPT-5 Nano (recommended) or GPT-5 Mini
5. Select your language (auto-detect by default)
6. Configure audio input device

🎯 KEY FEATURES
═══════════════
✓ Live transcription using Apple Speech Recognition
✓ AI-powered insights with GPT-5 Nano/Mini
✓ Smart transcription every 6 seconds
✓ Insights generation every 45 seconds
✓ Messenger-style transcript bubbles
✓ Recording history with sessions
✓ Project organization with keywords
✓ Liquid Glass 2026 design language
✓ Compact mini window (380x280)
✓ Full Dashboard with analytics
✓ BlackHole aggregate device support
✓ Multi-language support (23 languages)

🎤 AUDIO SETUP (for capturing both sides)
═════════════════════════════════════════
To capture both your voice AND your meeting partner:

1. Install BlackHole: https://github.com/ExistentialAudio/BlackHole
2. Create Aggregate Device in Audio MIDI Setup:
   • Include: Built-in Microphone + BlackHole 2ch
   • Set Clock Source: Built-in Microphone
3. Set as system input: System Settings → Sound → Input
4. In Zoom/Teams:
   • Input: Aggregate Device
   • Output: BlackHole 2ch (or Multi-Output Device)

📋 REQUIREMENTS
═══════════════
• macOS 13.0 (Ventura) or later
• Microphone access
• Internet connection for AI features
• OpenAI API key (for GPT-5 features)

💰 PRICING (OpenAI GPT-5)
═════════════════════════
• GPT-5 Nano: ./create_dmg.sh.05/./create_dmg.sh.40 per 1M tokens (recommended)
• GPT-5 Mini: ./create_dmg.sh.25/.00 per 1M tokens

Typical 1-hour meeting costs: ./create_dmg.sh.01-0.05 with Nano

🔐 PRIVACY & SECURITY
═════════════════════
✓ All data stored locally on your Mac
✓ No analytics or telemetry
✓ No data sent to developer
✓ API keys stored securely in Keychain
✓ Transcripts only sent to OpenAI with your key
✓ Open source - you can verify the code

📂 DATA LOCATIONS
═════════════════
• Settings: ~/Library/Preferences/com.daniilkozin.nota.plist
• Data: ~/Library/Application Support/com.daniilkozin.nota/
• Recordings: Stored in app data folder

🗑️ UNINSTALL
═════════════
1. Delete /Applications/Nota.app
2. Delete ~/Library/Preferences/com.daniilkozin.nota.plist
3. Delete ~/Library/Application Support/com.daniilkozin.nota/

⌨️ KEYBOARD SHORTCUTS
═════════════════════
• CMD+\ : Show/hide mini window (requires Accessibility)

🆘 TROUBLESHOOTING
══════════════════
• No transcription? Check microphone permissions
• No insights? Add OpenAI API key in Settings
• Can't hear partner? Set up aggregate device (see Audio Setup)
• Partner can't hear you? Check Zoom/Teams input = Aggregate Device
• App crashes? Check Console.app for logs

📚 DOCUMENTATION
════════════════
Full documentation included in app:
• AUDIO_SETUP_GUIDE.md - Detailed audio configuration
• QUICK_FIX_AUDIO.md - Quick troubleshooting
• SECURITY_CHECK.md - Privacy and security details

🔗 LINKS
════════
• GitHub: https://github.com/daniilkozin/nota
• OpenAI API: https://platform.openai.com
• BlackHole: https://github.com/ExistentialAudio/BlackHole
• Support: Open issue on GitHub

📝 VERSION HISTORY
══════════════════
v2.1.0 (January 2026)
• GPT-5 Nano/Mini support
• Smart transcription (6s intervals)
• Insights generation (45s intervals)
• Messenger-style bubbles
• Recording history system
• Project organization
• Liquid Glass 2026 design
• Audio device management
• Keywords and meeting type detection
• Improved Gatekeeper handling

v2.0 (January 2026)
• Complete Swift rewrite
• Native macOS performance
• Liquid Glass design language
• Mini window interface
• Dashboard with analytics

v1.0 (December 2025)
• Initial release
• Basic transcription
• OpenAI integration

═══════════════════════════════════════════════════════════════
Built with ❤️ using Swift for optimal macOS performance
Version 2.1.0 - January 14, 2026
═══════════════════════════════════════════════════════════════
