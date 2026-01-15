# Quick Start Guide - Nota v2.2.0

## 🚀 First Time Setup (2 minutes)

### Step 1: Grant Microphone Permission
1. Click the **microphone icon** in your menu bar (top right)
2. Click **"Start Recording"** button in the mini window
3. macOS will ask for **Microphone permission** → Click **"OK"**

That's it! The app will now start recording and transcribing.

---

## 🎯 What You'll See

### When Recording Starts:
- ✅ Status changes to "Recording (AssemblyAI)..."
- ✅ Real-time transcript appears in the mini window
- ✅ Transcript updates every 100-200ms as you speak

### When Recording Stops:
- ✅ Final transcript is saved
- ✅ Session appears in Recording History
- ✅ AI insights generated (if OpenAI key configured)

---

## 🔧 Current Configuration

Your app is already configured with:
- ✅ **AssemblyAI key**: Included (default)
- ✅ **Provider**: Auto (uses AssemblyAI for all languages)
- ✅ **Language**: English
- ✅ **Deepgram key**: Configured (backup)
- ✅ **OpenAI key**: Configured (for AI insights)

**You just need to grant microphone permission!**

---

## 📝 How to Test

### Test 1: Basic Recording
1. Click menu bar icon
2. Click "Start Recording"
3. Grant microphone permission
4. Say: "Hello, this is a test recording"
5. Wait 2-3 seconds
6. You should see the text appear in real-time
7. Click "Stop Recording"

### Test 2: Multi-Language (Russian)
1. Open Dashboard (home icon)
2. Go to Settings
3. Change Language to "Русский"
4. Start recording
5. Speak in Russian
6. Verify transcription appears

### Test 3: AI Insights
1. Record a 1-minute conversation
2. After 45 seconds, insights will appear
3. Stop recording
4. Check the insights panel for:
   - Meeting summary
   - Action items
   - Key insights
   - Keywords

---

## ⚠️ Troubleshooting

### No transcription appearing?
**Cause**: Microphone permission not granted

**Solution**:
1. System Settings → Privacy & Security → Microphone
2. Find "Nota" in the list
3. Toggle it ON
4. Restart the app

### "Microphone access denied" message?
**Cause**: You clicked "Don't Allow" when prompted

**Solution**:
1. System Settings → Privacy & Security → Microphone
2. Enable Nota
3. Restart recording

### Transcription is slow?
**Cause**: Internet connection or API latency

**Solution**:
- Check internet connection
- AssemblyAI should be ~100-200ms latency
- If slow, try switching to Deepgram in Settings

---

## 🎉 You're Ready!

Just click the menu bar icon and start recording. The app will:
1. Request microphone permission (first time only)
2. Start recording audio
3. Stream to AssemblyAI for transcription
4. Show real-time transcript
5. Generate AI insights (if OpenAI key configured)
6. Save to recording history

**No credit card, no signup, no hassle. Just record and transcribe!**

---

## 📚 Next Steps

- **Add custom vocabulary**: Coming in v2.3
- **Speaker diarization**: Coming in v2.3
- **Export formats**: Coming in v2.3
- **Cloud sync**: Coming in v2.3

---

**Need help?** Check the full documentation in the `docs/` folder or open an issue on GitHub.
