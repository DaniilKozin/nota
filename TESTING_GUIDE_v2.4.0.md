# Testing Guide v2.4.0 - Stability & Russian Support

## 🎯 What to Test

### 1. **Settings Window Stability** (CRITICAL)
**Before**: Crashed ~30% of the time  
**After**: Should be 100% stable

**Test Steps:**
1. Open Nota from menu bar
2. Click "Settings" 
3. Open/close Settings window 10 times rapidly
4. Change language settings multiple times
5. Click "Refresh Devices" multiple times
6. Try changing settings while recording (should be disabled)

**Expected Results:**
- ✅ No crashes
- ✅ Smooth opening/closing
- ✅ Device list populates correctly
- ✅ Controls disabled during recording
- ✅ Helpful tooltips on disabled buttons

### 2. **Russian Transcription** (NEW FEATURE)
**Before**: Russian didn't work at all  
**After**: Should work with context preservation

**Test Steps:**
1. Install new version: `cd Nota-Swift && ./install_nota.sh`
2. Open Settings:
   - Language: Russian (or Auto)
   - Provider: Whisper
   - OpenAI API Key: Your key
   - Input Device: Your microphone
3. Start recording
4. Speak in Russian for 15-20 seconds
5. Check Console.app (filter for "Nota")

**Expected Results:**
- ✅ Transcription appears within 5-10 seconds
- ✅ Russian text correctly transcribed
- ✅ Context preserved between chunks
- ✅ Console shows: "🔗 Using context prompt"
- ✅ No errors in Console.app

**Expected Console Logs:**
```
🌍 Output language setting: ru
🇷🇺 Using Russian (ru-RU)
🎯 Selected provider: whisper
🎤 Starting Whisper chunked transcription...
✅ Audio recording started
📤 Sending audio to Whisper API...
📊 Audio file size: 123456 bytes
🔗 Using context prompt: Привет, меня зовут...
📡 Whisper API response status: 200
🌍 Whisper detected language: ru
✅ Whisper transcription (25 chars): Даниил и я работаю над проектом
📝 Total buffer size: 67 chars
```

### 3. **Mixed Language Support** (ENHANCED)
**Test Steps:**
1. Set language to "Auto" or "Whisper"
2. Start recording
3. Speak English for 10 seconds
4. Switch to Russian for 10 seconds
5. Switch back to English for 10 seconds

**Expected Results:**
- ✅ Both languages transcribed correctly
- ✅ Context preserved across language switches
- ✅ No loss of conversation flow
- ✅ Console shows language detection per chunk

### 4. **Device Discovery Stability** (FIXED)
**Test Steps:**
1. Plug/unplug audio devices while app is running
2. Open Settings and click "Refresh Devices"
3. Try refreshing during recording (should be disabled)
4. Test with various audio interfaces (USB, Bluetooth, etc.)

**Expected Results:**
- ✅ No crashes during device discovery
- ✅ Device list updates correctly
- ✅ Graceful handling of device errors
- ✅ Fallback to "Default Input" if needed

## 🚨 What Could Go Wrong

### Settings Window Issues
**Symptoms**: Crashes, freezing, blank device list  
**Check**: Console.app for CoreAudio errors  
**Solution**: Restart app, check audio permissions

### Russian Transcription Issues
**Symptoms**: No transcription, wrong language, context lost  
**Check**: Console.app for Whisper API errors  
**Common fixes**:
- Verify OpenAI API key is valid
- Check internet connection
- Ensure microphone permissions granted
- Try manual language selection (not Auto)

### Device Discovery Issues
**Symptoms**: Empty device list, crashes on refresh  
**Check**: Audio permissions in System Settings  
**Solution**: Grant microphone access, restart app

## 📊 Performance Expectations

### Settings Window
- **Opening**: Instant (was slow/crashy)
- **Device discovery**: 1-2 seconds (was crashy)
- **Stability**: 100% (was 70%)

### Russian Transcription
- **Latency**: 5-10 seconds per chunk
- **Accuracy**: 90-95% for clear speech
- **Context**: Preserved between chunks
- **Cost**: ~$0.36/hour

### Mixed Languages
- **Detection**: Automatic per chunk
- **Accuracy**: Good for both languages
- **Context**: Maintained across switches

## 🔧 Debugging

### Console.app Logs
Filter for "Nota" and look for:

**Good signs:**
- ✅ "🔧 Settings: Starting safe device discovery"
- ✅ "🎧 Found input device: [device name]"
- ✅ "🔗 Using context prompt: [text]..."
- ✅ "📡 Whisper API response status: 200"

**Warning signs:**
- ⚠️ "⚠️ Skipping device discovery during recording"
- ⚠️ "⚠️ Error discovering audio devices"
- ⚠️ "❌ Whisper API error"

**Bad signs:**
- ❌ CoreAudio errors
- ❌ Memory allocation failures
- ❌ HTTP status != 200

### Common Issues

**Issue**: Settings window won't open  
**Fix**: Restart app, check Console for errors

**Issue**: No devices in list  
**Fix**: Check microphone permissions, click "Refresh Devices"

**Issue**: Russian not transcribing  
**Fix**: Check OpenAI API key, verify internet connection

**Issue**: Context not preserved  
**Fix**: Look for "🔗 Using context prompt" in logs

## 📝 Test Checklist

### Stability Tests
- [ ] Settings window opens/closes 10 times without crash
- [ ] Device refresh works multiple times
- [ ] Settings changes disabled during recording
- [ ] No memory leaks or crashes
- [ ] Proper error messages shown

### Russian Transcription Tests
- [ ] Russian speech transcribed correctly
- [ ] Context preserved between chunks
- [ ] Mixed English + Russian works
- [ ] Console shows proper logs
- [ ] No API errors

### Device Tests
- [ ] Device list populates correctly
- [ ] Plug/unplug devices handled gracefully
- [ ] Default device fallback works
- [ ] Various audio interfaces supported

### Performance Tests
- [ ] Settings window responsive
- [ ] Device discovery completes quickly
- [ ] No UI freezing or blocking
- [ ] Smooth user experience

## 🎉 Success Criteria

**Settings Window:**
- ✅ 0% crash rate (was 30%)
- ✅ Fast, responsive UI
- ✅ Reliable device discovery

**Russian Transcription:**
- ✅ Works with Whisper
- ✅ Context preserved
- ✅ Mixed languages supported

**Overall Stability:**
- ✅ No crashes in normal use
- ✅ Graceful error handling
- ✅ Better user experience

## 📞 Support

If you find issues:
1. Check Console.app logs (filter "Nota")
2. Try restarting the app
3. Verify permissions in System Settings
4. Test with English first to isolate issues
5. Report with Console logs and steps to reproduce

---

**Ready for testing!** 🚀  
**Version**: 2.4.0  
**Focus**: Stability + Russian support  
**Expected**: Much more stable, Russian transcription working