# Nota - Quick Start Guide

## 🎯 Choose Your Launch Method

### 🚀 For Development (Fastest Iteration)
```bash
./start.sh          # or double-click: quick-start.command
```

### 📦 Run Built App (No DMG needed)
```bash
./run-app.sh        # Launch the compiled app
```

### 💿 Install from DMG (Production)
```bash
./open-dmg.sh       # Open existing DMG in Finder
# or
./build_app.sh      # Build new DMG (takes 5-10 min)
```

> **See [RUN_FROM_DMG.md](RUN_FROM_DMG.md) for detailed comparison and instructions**

---

## 🚀 Fast Launch (Development)

### Option 1: Double-Click Launch (Easiest)
1. Double-click `quick-start.command` in Finder
2. The app will start automatically

### Option 2: Terminal Launch
```bash
./start.sh
```

### Option 3: Manual Launch
```bash
# Terminal 1 - Backend
cd backend
source .venv/bin/activate
python3 main.py

# Terminal 2 - Frontend
cd frontend
npm run tauri dev
```

## 🎧 BlackHole Audio Setup (For Recording System Audio)

BlackHole allows you to record system audio (meeting participants in Zoom, Meet, Teams).

> **📖 Detailed guide:** See [BLACKHOLE_SETUP_GUIDE.md](BLACKHOLE_SETUP_GUIDE.md) for all scenarios

### Quick Setup: Record Complete Meetings (You + Others)

This is the recommended setup that captures EVERYONE in the meeting.

#### Step 1: Install BlackHole
```bash
brew install blackhole-2ch
```

#### Step 2: Multi-Output Device (for OUTPUT - so you can hear)

1. Open **Audio MIDI Setup** (⌘+Space → "Audio MIDI Setup")
2. Click **+** button → **Create Multi-Output Device**
3. Name it "Speakers + BlackHole"
4. Check BOTH:
   - ✅ **Built-in Output** (your speakers)
   - ✅ **BlackHole 2ch**
5. Right-click → **Use This Device For Sound Output**

#### Step 3: Aggregate Device (for INPUT - what Nota records)

1. In Audio MIDI Setup, click **+** → **Create Aggregate Device**
2. Name it "Meeting + Mic"
3. Check BOTH:
   - ✅ **BlackHole 2ch** (captures meeting audio)
   - ✅ **Built-in Microphone** (captures your voice)
4. Click gear icon → **Drift Correction** → Check BlackHole 2ch
5. Set same sample rate (48000 Hz) for both devices

#### Step 4: Configure Nota

1. Open Nota → Settings → Audio Input
2. Click **Refresh**
3. Select your **Aggregate Device** (e.g., "Meeting + Mic")
4. Save

#### Result
✅ You hear the meeting through speakers (Multi-Output)
✅ Nota records meeting audio (via BlackHole in Aggregate)
✅ Nota records your voice (via Microphone in Aggregate)
✅ Complete conversation captured!

### Alternative: Meeting Audio Only (Without Your Voice)

If you only want to record others (not yourself):

1. Do Steps 1-2 above (Install + Multi-Output Device)
2. Skip Step 3 (don't create Aggregate Device)
3. In Nota: Select **BlackHole 2ch** directly
4. This records only what comes through your speakers

### Testing

1. Set up as above (complete meeting setup)
2. Play a YouTube video (should hear it + see transcription)
3. Speak into microphone (should see your words too)
4. Both sources = setup is correct!

### Troubleshooting

**Can't hear audio:**
- Verify Multi-Output includes Built-in Output
- Check Multi-Output is set as system sound output
- Increase volume

**Not recording meeting audio:**
- Use Aggregate Device (not just BlackHole or Microphone alone)
- Ensure BlackHole is in both Multi-Output AND Aggregate
- Click Refresh in Nota to see latest devices

**Not recording your voice:**
- Verify Built-in Microphone is in Aggregate Device
- Grant microphone permission when prompted
- Check microphone isn't muted

**Detailed troubleshooting:** [BLACKHOLE_SETUP_GUIDE.md](BLACKHOLE_SETUP_GUIDE.md)

## 🔧 First Time Setup

1. **Install Dependencies**:
   ```bash
   # Backend
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   cd ..

   # Frontend
   cd frontend
   npm install
   cd ..
   ```

2. **Configure API Keys**:
   - Launch the app
   - Click Settings (gear icon)
   - Enter your API keys:
     - **OpenAI API Key** (for GPT models and transcription)
     - **Deepgram API Key** (for real-time transcription, optional)

3. **Select Audio Input**:
   - In Settings → Audio Input
   - Choose your microphone or BlackHole (for system audio)

## 📝 Usage Tips

### Recording Meetings
1. Start Nota (it opens in mini mode at the top of your screen)
2. Join your meeting
3. Click the **Record** button in Nota
4. Speak or let the meeting proceed
5. Click **Stop & Analyze** when done
6. View summary, tasks, and transcript

### Auto-Recording
Enable in Settings:
- ✅ **Auto-detect meetings** - Detects Zoom/Meet/Teams windows
- ✅ **Auto-start recording** - Starts recording automatically

### Mini vs Full Mode
- **Mini Mode** (Cloud): Small floating widget, always on top
- **Full Mode** (Dashboard): Complete interface with history, projects, chat

Switch modes:
- Mini → Full: Click the home icon
- Full → Mini: Click the minimize icon

## 🏗️ Building for Production

```bash
./build_app.sh
```

The DMG will be in: `frontend/src-tauri/target/release/bundle/dmg/`

## 🆘 Common Issues

### Backend won't start
- Check if port 8000 is in use: `lsof -i :8000`
- Kill existing process: `pkill -f "python3 main.py"`

### Frontend won't connect
- Ensure backend is running (check http://127.0.0.1:8000)
- Look for errors in backend.log

### No transcription appearing
- Check backend logs for Deepgram debug messages
- Verify API keys are correct
- Ensure microphone permission is granted
- Try switching transcription provider in settings

### App is slow
- First launch is slower (loading dependencies)
- Subsequent launches should be faster
- Check system resources (Activity Monitor)

## 📚 More Help

- Full documentation: See README_USERS.md
- Build instructions: See BUILD_INSTRUCTIONS.md
- Security guide: See SECURITY_CHECKLIST.md
