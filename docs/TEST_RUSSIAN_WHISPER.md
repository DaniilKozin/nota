# Testing Russian Transcription with Whisper

## What Changed in v2.4.0

### Context Preservation
- Added `prompt` parameter to Whisper API calls
- Last 200 characters of transcript are sent with each new chunk
- Maintains conversation flow and improves accuracy
- Works across language switches in mixed-language meetings

### Enhanced Logging
- Audio file size logging
- HTTP response status codes
- Raw API responses for debugging
- Detailed error messages
- Character count tracking

## How to Test

### 1. Install New Version
```bash
cd Nota-Swift
./install_nota.sh
```

### 2. Configure Settings
1. Open Nota from menu bar
2. Click "Settings"
3. Set:
   - **Language**: Russian (or Auto)
   - **Provider**: Whisper
   - **OpenAI API Key**: Your key
   - **Input Device**: Your microphone or BlackHole

### 3. Start Recording
1. Click "Start Recording"
2. Speak in Russian
3. Wait 5-10 seconds for first transcription

### 4. Check Console Logs
Open Console.app and filter for "Nota":

**Expected logs:**
```
🌍 Output language setting: ru
🇷🇺 Using Russian (ru-RU)
🎯 Selected provider: whisper
🎤 Starting Whisper chunked transcription...
✅ Audio recording started
📤 Sending audio to Whisper API...
📊 Audio file size: 123456 bytes
🔗 Using context prompt: [previous text]...
📡 Whisper API response status: 200
📥 Whisper raw response: {"text":"...","language":"ru"}
🌍 Whisper detected language: ru
✅ Whisper transcription (45 chars): Привет, как дела?...
📝 Total buffer size: 45 chars
```

**If you see errors:**
```
❌ Whisper API error: [error message]
❌ No data received from Whisper
❌ Failed to read audio file
⚠️ No 'text' field in Whisper response
```

### 5. Test Mixed Languages
1. Speak in English for 10 seconds
2. Switch to Russian for 10 seconds
3. Switch back to English

**Expected behavior:**
- Each chunk auto-detects language
- Context is preserved between chunks
- Transcript shows both languages
- No loss of conversation flow

## Debugging

### If Russian doesn't transcribe:

1. **Check audio file is created:**
   ```bash
   ls -lh ~/Documents/recording_*.m4a
   ```
   Should see files with size > 0 bytes

2. **Check OpenAI API key:**
   - Open Settings
   - Verify API key is entered
   - Test key at: https://platform.openai.com/api-keys

3. **Check Console logs:**
   - Look for "📤 Sending audio to Whisper API..."
   - Check HTTP status code (should be 200)
   - Look for error messages

4. **Check audio input:**
   ```bash
   swift run Nota check_default_input.swift
   ```

### Common Issues

**Issue**: No transcription appears
**Solution**: 
- Wait 5-10 seconds (Whisper processes in chunks)
- Check Console.app for errors
- Verify OpenAI API key is valid

**Issue**: Transcription in wrong language
**Solution**:
- Set language to "Auto" or manually select "Russian"
- Whisper auto-detects language per chunk
- Context is preserved between chunks

**Issue**: Context lost between chunks
**Solution**:
- This should be fixed in v2.4.0
- Check logs for "🔗 Using context prompt"
- If not present, context preservation isn't working

## What to Look For

### Success Indicators:
- ✅ Transcription appears within 5-10 seconds
- ✅ Russian text is correctly transcribed
- ✅ Context is maintained between chunks
- ✅ Mixed languages work (English + Russian)
- ✅ No errors in Console.app

### Failure Indicators:
- ❌ No transcription after 30 seconds
- ❌ Errors in Console.app
- ❌ Audio file size is 0 bytes
- ❌ HTTP status code is not 200
- ❌ Context lost between chunks

## Performance Expectations

### Whisper (Russian)
- **Latency**: 5-10 seconds per chunk
- **Accuracy**: High (90-95%)
- **Context**: Preserved between chunks
- **Mixed languages**: Supported (auto-detect per chunk)
- **Cost**: ~$0.36/hour

### AssemblyAI (English)
- **Latency**: 100-200ms (real-time)
- **Accuracy**: Very high (95-98%)
- **Context**: Real-time streaming
- **Mixed languages**: Supported (code-switching)
- **Cost**: ~$0.27/hour

## Next Steps

If Russian transcription works:
1. Test mixed English + Russian
2. Test context preservation (long conversation)
3. Test with different speakers
4. Test with background noise

If Russian transcription doesn't work:
1. Share Console.app logs
2. Check audio file size
3. Verify OpenAI API key
4. Test with English first (to isolate issue)
