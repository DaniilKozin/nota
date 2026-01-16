# Audio Capture Analysis: Pluely vs Nota

## Executive Summary

**Current Status**: Nota's audio capture is NOT working for system audio (meetings). The app compiles successfully but captures complete silence (-160.0dB) because AVAudioRecorder always uses the system default physical microphone, ignoring the BlackHole device selection.

**Critical Issue**: User has active meetings RIGHT NOW where Cluealy works perfectly but Nota captures nothing.

---

## What We Know About Pluely

### Architecture
- **Platform**: Tauri (Rust backend + React frontend)
- **Size**: ~10MB (27x smaller than Cluely's 270MB)
- **Performance**: <100ms startup, 50% less CPU/RAM than Electron apps
- **Audio Capture**: System Audio Capture with keyboard shortcut (Cmd+Shift+M)

### Key Features
1. **System Audio Capture**
   - Captures audio directly from computer's output (not microphone)
   - Perfect for meetings, presentations, system audio
   - Voice activity detection
   - Real-time audio visualization
   - Automatic processing status indicators
   - Configurable audio input devices in settings

2. **Privacy-First**
   - All data stored locally in SQLite
   - Direct API calls to AI providers (no proxy servers)
   - No telemetry or tracking
   - Offline capability for local features

3. **Stealth Mode**
   - Translucent overlay window
   - Invisible in video calls, screen shares, recordings
   - Always-on-top mode
   - Keyboard shortcuts for instant access

### Technology Stack (Inferred)
- **Rust**: Likely using `cpal` (Cross-Platform Audio Library) for audio I/O
- **Tauri**: Native system integration
- **React**: Frontend UI
- **SQLite**: Local data storage

---

## What We Have in Nota

### Architecture
- **Platform**: Swift + AppKit (native macOS)
- **Size**: Unknown (likely larger due to .dmg packaging)
- **Audio Capture**: Attempted with AVAudioRecorder + AVAudioEngine

### Current Implementation

#### Audio Recording Approach
```swift
// Two implementations:
1. AVAudioEngine (NEW - for device selection)
   - Can select specific audio devices (BlackHole)
   - Uses AudioUnit API to set input device
   - Installs tap on input node
   - Converts audio to 16kHz mono PCM
   - Streams to Deepgram/AssemblyAI

2. AVAudioRecorder (FALLBACK)
   - Simple recording API
   - ALWAYS uses system default input device
   - Cannot select BlackHole programmatically
   - This is why we capture silence
```

#### Transcription Providers
- **Primary**: AssemblyAI v3 (multilingual streaming)
- **Fallback 1**: Deepgram (multilingual streaming)
- **Fallback 2**: Whisper (chunked, every 5 seconds)

#### Current Problems
1. **AVAudioRecorder ignores device selection** - captures physical mic, not system audio
2. **AVAudioEngine implementation works** - but needs testing with BlackHole
3. **User has BlackHole installed** but audio routing may not be configured
4. **No audio visualization** - user can't see if audio is being captured
5. **No voice activity detection** - can't tell if someone is speaking

---

## Comparison: Pluely vs Nota

### What Pluely Has That We Don't

| Feature | Pluely | Nota | Priority |
|---------|--------|------|----------|
| **System Audio Capture** | ✅ Works perfectly | ❌ Captures silence | 🔴 CRITICAL |
| **Voice Activity Detection** | ✅ Yes | ❌ No | 🟡 HIGH |
| **Real-time Audio Visualization** | ✅ Yes | ❌ No | 🟡 HIGH |
| **Audio Device Selection UI** | ✅ Yes | ✅ Yes (but broken) | 🟡 HIGH |
| **Keyboard Shortcuts** | ✅ Cmd+Shift+M | ✅ Menu bar click | 🟢 MEDIUM |
| **Stealth Mode** | ✅ Translucent overlay | ⚠️ Mini window | 🟢 MEDIUM |
| **Local Storage** | ✅ SQLite | ✅ UserDefaults + files | 🟢 LOW |
| **Cross-platform** | ✅ Mac/Win/Linux | ❌ macOS only | 🟢 LOW |

### What We Have That Pluely Might Not

| Feature | Nota | Pluely | Notes |
|---------|------|--------|-------|
| **Native macOS Integration** | ✅ Swift/AppKit | ⚠️ Tauri/Webview | Nota is truly native |
| **Multiple AI Providers** | ✅ 3 providers with fallback | ✅ Many providers | Both good |
| **Multilingual Support** | ✅ AssemblyAI v3 | ❓ Unknown | Need to verify |
| **AI Insights** | ✅ Periodic summaries | ❓ Unknown | Need to verify |
| **Menu Bar Integration** | ✅ Native status bar | ⚠️ Dock icon | Nota better integrated |

---

## Root Cause Analysis

### Why Nota Doesn't Capture System Audio

1. **AVAudioRecorder Limitation**
   ```swift
   // This ALWAYS uses system default input device
   audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
   // Even if we set inputDeviceId in UserDefaults, AVAudioRecorder ignores it
   ```

2. **System Default Device**
   - macOS system default: "USB Condenser Microphone" (physical mic)
   - User wants: "BlackHole 2ch" (virtual audio device for system audio)
   - AVAudioRecorder has NO API to change input device

3. **AVAudioEngine Solution**
   ```swift
   // This CAN select specific devices
   let inputNode = engine.inputNode
   AudioUnitSetProperty(
       audioUnit,
       kAudioOutputUnitProperty_CurrentDevice,
       kAudioUnitScope_Global,
       0,
       &inputDeviceID,
       propertySize
   )
   ```

### Why Cluealy/Pluely Works

1. **Proper Device Selection**
   - They correctly implement device selection at the audio capture level
   - Likely using lower-level APIs (CoreAudio on macOS, CPAL in Rust)

2. **Audio Routing**
   - They may automatically configure audio routing
   - Or provide clear instructions for BlackHole setup

3. **Voice Activity Detection**
   - They detect when audio is actually present
   - Provides feedback to user that capture is working

---

## Recommended Improvements

### 🔴 CRITICAL (Fix Immediately)

1. **Complete AVAudioEngine Implementation**
   - ✅ Code is written and compiles
   - ⏳ Needs testing with BlackHole device
   - ⏳ Verify audio levels show real sound (not -160.0dB)
   - ⏳ Verify streaming to AssemblyAI works

2. **Audio Routing Verification**
   - Add startup check: Is BlackHole installed?
   - Add startup check: Is BlackHole set as input device?
   - Provide clear error messages if not configured
   - Link to setup guide

3. **Real-time Audio Level Monitoring**
   ```swift
   // Add visual feedback in UI
   - Show dB levels in real-time
   - Show waveform or audio bars
   - Indicate when speech is detected
   - Show "No audio detected" warning
   ```

### 🟡 HIGH (Next Priority)

4. **Voice Activity Detection (VAD)**
   - Detect when someone is actually speaking
   - Only send audio chunks when speech detected
   - Save bandwidth and API costs
   - Provide visual feedback to user

5. **Audio Visualization**
   - Real-time waveform display
   - Audio level meters
   - Visual confirmation that audio is being captured
   - Helps user debug audio issues

6. **Better Error Messages**
   ```swift
   // Instead of: "Recording..."
   // Show:
   - "✅ Recording from BlackHole 2ch - Audio detected"
   - "⚠️ Recording from USB Mic - No system audio (use BlackHole)"
   - "❌ No audio detected - Check audio routing"
   ```

### 🟢 MEDIUM (Future Enhancements)

7. **Automatic Audio Routing**
   - Detect if BlackHole is installed
   - Offer to configure audio routing automatically
   - Create Multi-Output Device if needed
   - Guide user through setup

8. **Audio Device Health Check**
   - Test audio capture on startup
   - Verify device is working
   - Show sample audio levels
   - Warn if device is silent

9. **Keyboard Shortcuts**
   - Add global hotkey for start/stop recording
   - Add hotkey for show/hide window
   - Make it more accessible like Pluely

### 🟢 LOW (Nice to Have)

10. **Cross-platform Support**
    - Consider Tauri for future versions
    - Would enable Windows/Linux support
    - Smaller app size
    - But lose native macOS integration

---

## Technical Implementation Details

### How Pluely Likely Captures System Audio

Based on Tauri + Rust architecture, they probably use:

```rust
// Using cpal (Cross-Platform Audio Library)
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

// Get audio host
let host = cpal::default_host();

// Find BlackHole or system audio device
let device = host.input_devices()
    .find(|d| d.name().contains("BlackHole"))
    .or_else(|| host.default_input_device());

// Create audio stream
let stream = device.build_input_stream(
    &config,
    move |data: &[f32], _: &cpal::InputCallbackInfo| {
        // Process audio data
        // Send to transcription API
    },
    |err| eprintln!("Audio error: {}", err),
)?;

stream.play()?;
```

### How Nota Should Capture System Audio

```swift
// Using AVAudioEngine (already implemented)
let engine = AVAudioEngine()
let inputNode = engine.inputNode

// Set BlackHole as input device
let deviceId = "BlackHole2ch_UID"
if let audioDeviceID = findAudioDeviceID(byUID: deviceId) {
    var inputDeviceID = audioDeviceID
    AudioUnitSetProperty(
        inputNode.audioUnit,
        kAudioOutputUnitProperty_CurrentDevice,
        kAudioUnitScope_Global,
        0,
        &inputDeviceID,
        UInt32(MemoryLayout<AudioDeviceID>.size)
    )
}

// Install tap to capture audio
inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
    // Convert to 16kHz mono
    // Send to AssemblyAI/Deepgram
}

engine.start()
```

---

## Action Plan

### Immediate Actions (Today)

1. ✅ **Fix compilation errors** - DONE (code compiles)
2. ⏳ **Test AVAudioEngine with BlackHole**
   - Run the app
   - Start recording
   - Check if audio levels show real sound
   - Verify transcription works

3. ⏳ **Add audio level logging**
   - Show real-time dB levels in console
   - Help debug if audio is being captured

4. ⏳ **Verify BlackHole configuration**
   - Check if BlackHole is set as input in System Settings
   - Check if audio routing is correct
   - Provide setup instructions if needed

### Short-term (This Week)

5. **Add Voice Activity Detection**
   - Detect speech vs silence
   - Only process when speech detected
   - Show visual indicator

6. **Add Audio Visualization**
   - Real-time audio level meters
   - Waveform display
   - Visual confirmation of capture

7. **Improve Error Messages**
   - Clear feedback about audio status
   - Warnings if no audio detected
   - Instructions for fixing issues

### Medium-term (Next Sprint)

8. **Audio Device Health Check**
   - Startup verification
   - Test audio capture
   - Guide user through setup

9. **Automatic Audio Routing**
   - Detect BlackHole
   - Configure routing automatically
   - Create Multi-Output Device

10. **Global Keyboard Shortcuts**
    - Hotkey for start/stop
    - Hotkey for show/hide
    - More accessible like Pluely

---

## Questions for User

Before implementing changes from Pluely's approach, we need to answer:

1. **Do you want audio visualization?**
   - Real-time waveform display
   - Audio level meters
   - Visual feedback that audio is being captured

2. **Do you want voice activity detection?**
   - Only transcribe when speech detected
   - Save API costs
   - Reduce noise in transcripts

3. **Do you want automatic audio routing setup?**
   - App configures BlackHole automatically
   - Creates Multi-Output Device
   - Or prefer manual setup with clear instructions?

4. **Do you want global keyboard shortcuts?**
   - Hotkey to start/stop recording (like Pluely's Cmd+Shift+M)
   - Hotkey to show/hide window
   - More accessible than menu bar click?

5. **Do you want stealth mode improvements?**
   - Translucent overlay window (like Pluely)
   - Invisible in screen shares
   - Or current mini window is fine?

---

## Conclusion

**The core issue is simple**: AVAudioRecorder doesn't support device selection. We've already implemented AVAudioEngine which DOES support device selection. Now we need to:

1. Test it with BlackHole
2. Verify audio is actually being captured
3. Add visual feedback so user knows it's working
4. Add voice activity detection for better UX

Pluely's success comes from:
- Proper device selection (we now have this)
- Voice activity detection (we need this)
- Audio visualization (we need this)
- Clear user feedback (we need this)

**Next Step**: Test the AVAudioEngine implementation with BlackHole and verify it captures system audio correctly.
