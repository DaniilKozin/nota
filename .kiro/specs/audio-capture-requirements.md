# Audio Capture Requirements - System Audio Support

## Problem Statement

Nota currently cannot capture system audio from meetings (Zoom, Google Meet, etc.) because AVAudioRecorder always uses the system default physical microphone, ignoring the BlackHole device selection. Users have active meetings where competitors like Cluealy work perfectly, but Nota captures complete silence (-160.0dB).

## User Stories

### Critical (P0)

**US-1: As a user, I want Nota to capture system audio from my meetings so I can transcribe conversations in real-time**

**Acceptance Criteria:**
- [ ] When I select "BlackHole 2ch" in Settings → Audio Settings
- [ ] And I start recording during a Zoom/Meet call
- [ ] Then Nota captures the meeting audio (not silence)
- [ ] And audio levels show real sound (> -40dB when people speak)
- [ ] And transcription appears in real-time

**Technical Notes:**
- Use AVAudioEngine (already implemented) instead of AVAudioRecorder
- Set input device using AudioUnitSetProperty
- Verify device selection works with BlackHole

---

**US-2: As a user, I want to see real-time audio levels so I know if audio is being captured**

**Acceptance Criteria:**
- [ ] When recording is active
- [ ] Then I see audio level indicator in the UI
- [ ] And levels update in real-time (every 100ms)
- [ ] And I can distinguish between silence (<-40dB) and speech (>-40dB)
- [ ] And visual feedback shows "Audio detected" or "No audio detected"

**Technical Notes:**
- Add audio metering to AVAudioEngine tap
- Calculate RMS or peak levels from audio buffer
- Display in MiniWindow or DashboardWindow
- Use color coding: green (good), yellow (low), red (silence)

---

**US-3: As a user, I want clear error messages when audio capture fails so I can fix the issue**

**Acceptance Criteria:**
- [ ] When BlackHole is not installed
- [ ] Then I see: "⚠️ BlackHole not found - Install to capture system audio"
- [ ] When BlackHole is installed but not selected
- [ ] Then I see: "⚠️ Using physical microphone - Select BlackHole in Settings"
- [ ] When no audio is detected for 10 seconds
- [ ] Then I see: "⚠️ No audio detected - Check audio routing"
- [ ] And each message includes a link to setup guide

**Technical Notes:**
- Check available devices on startup
- Monitor audio levels during recording
- Show contextual error messages
- Link to AUDIO_SETUP_GUIDE.md

---

### High Priority (P1)

**US-4: As a user, I want voice activity detection so transcription only happens when people are speaking**

**Acceptance Criteria:**
- [ ] When recording is active
- [ ] And audio level is below threshold (-40dB) for 2 seconds
- [ ] Then stop sending audio to transcription API
- [ ] When audio level rises above threshold
- [ ] Then resume sending audio to transcription API
- [ ] And I see visual indicator: "🔊 Speech detected" or "🔇 Silence"

**Technical Notes:**
- Implement VAD using audio level threshold
- Add hysteresis to prevent flapping (2s silence before stopping)
- Save API costs by not transcribing silence
- Improve transcript quality by filtering noise

---

**US-5: As a user, I want audio visualization so I can see that audio is being captured**

**Acceptance Criteria:**
- [ ] When recording is active
- [ ] Then I see a waveform or audio level bars
- [ ] And visualization updates in real-time
- [ ] And I can visually confirm audio is being captured
- [ ] And visualization shows in MiniWindow (compact) or Dashboard (detailed)

**Technical Notes:**
- Add NSView subclass for audio visualization
- Calculate audio levels from buffer
- Draw waveform or level bars
- Update at 30-60 FPS for smooth animation

---

**US-6: As a user, I want automatic audio device verification so I know if my setup is correct**

**Acceptance Criteria:**
- [ ] When app launches
- [ ] Then check if BlackHole is installed
- [ ] And check if selected device is available
- [ ] And test audio capture for 2 seconds
- [ ] And show setup status: "✅ Audio setup complete" or "⚠️ Setup required"
- [ ] When setup is incomplete
- [ ] Then show guided setup wizard

**Technical Notes:**
- Add startup health check
- Enumerate available audio devices
- Test capture from selected device
- Show setup wizard if issues detected

---

### Medium Priority (P2)

**US-7: As a user, I want global keyboard shortcuts so I can control recording without clicking the menu bar**

**Acceptance Criteria:**
- [ ] When I press Cmd+Shift+M
- [ ] Then recording starts/stops (toggle)
- [ ] When I press Cmd+Shift+H
- [ ] Then mini window shows/hides (toggle)
- [ ] And shortcuts work even when Nota is not focused
- [ ] And shortcuts are configurable in Settings

**Technical Notes:**
- Use NSEvent.addGlobalMonitorForEvents
- Register hotkeys with Carbon or Cocoa APIs
- Handle conflicts with other apps
- Allow customization in Settings

---

**US-8: As a user, I want automatic audio routing setup so I don't have to manually configure BlackHole**

**Acceptance Criteria:**
- [ ] When I click "Auto-configure audio" in Settings
- [ ] Then app checks if BlackHole is installed
- [ ] And creates Multi-Output Device (BlackHole + Built-in Output)
- [ ] And sets Multi-Output as system default output
- [ ] And sets BlackHole as Nota's input device
- [ ] And shows confirmation: "✅ Audio routing configured"

**Technical Notes:**
- Use CoreAudio API to create aggregate device
- Set device properties programmatically
- Requires user permission (may need manual steps)
- Provide fallback instructions if automation fails

---

**US-9: As a user, I want audio device health monitoring so I'm alerted if audio capture stops working**

**Acceptance Criteria:**
- [ ] When recording is active
- [ ] And selected device becomes unavailable (unplugged, disabled)
- [ ] Then show alert: "⚠️ Audio device disconnected"
- [ ] And automatically switch to default device
- [ ] And log device change event
- [ ] When device becomes available again
- [ ] Then show notification: "✅ Audio device reconnected"

**Technical Notes:**
- Listen for kAudioHardwarePropertyDevices notifications
- Monitor device availability during recording
- Implement automatic fallback to default device
- Log all device changes for debugging

---

### Low Priority (P3)

**US-10: As a user, I want stealth mode so Nota is invisible in screen shares and recordings**

**Acceptance Criteria:**
- [ ] When I enable "Stealth Mode" in Settings
- [ ] Then mini window becomes translucent (50% opacity)
- [ ] And window is invisible in screen shares
- [ ] And window is invisible in screenshots
- [ ] And window is invisible in recordings
- [ ] But I can still see and interact with it

**Technical Notes:**
- Set window level to NSWindow.Level.screenSaver or higher
- Set window alpha to 0.5 or configurable value
- Use NSWindow.sharingType = .none to hide from screen capture
- Test with Zoom, Meet, Teams, OBS

---

## Technical Architecture

### Current Implementation (Broken)

```swift
// AVAudioRecorder - ALWAYS uses system default device
audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
audioRecorder?.record()
// ❌ Cannot select BlackHole, captures physical mic
```

### New Implementation (Working)

```swift
// AVAudioEngine - CAN select specific devices
let engine = AVAudioEngine()
let inputNode = engine.inputNode

// Set BlackHole as input device
if let deviceID = findAudioDeviceID(byUID: "BlackHole2ch_UID") {
    var inputDeviceID = deviceID
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
    // Calculate audio levels for VAD and visualization
    let levels = calculateAudioLevels(buffer)
    
    // Voice activity detection
    if levels.rms > vadThreshold {
        // Send to transcription API
        sendToTranscription(buffer)
    }
    
    // Update visualization
    updateAudioVisualization(levels)
}

engine.start()
```

### Audio Level Calculation

```swift
func calculateAudioLevels(_ buffer: AVAudioPCMBuffer) -> AudioLevels {
    guard let channelData = buffer.floatChannelData else {
        return AudioLevels(rms: -160, peak: -160)
    }
    
    let channelDataValue = channelData.pointee
    let channelDataValueArray = stride(
        from: 0,
        to: Int(buffer.frameLength),
        by: buffer.stride
    ).map { channelDataValue[$0] }
    
    // Calculate RMS (Root Mean Square)
    let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
    let rmsDb = 20 * log10(rms)
    
    // Calculate peak
    let peak = channelDataValueArray.map { abs($0) }.max() ?? 0
    let peakDb = 20 * log10(peak)
    
    return AudioLevels(rms: rmsDb, peak: peakDb)
}
```

### Voice Activity Detection

```swift
class VoiceActivityDetector {
    private let threshold: Float = -40.0 // dB
    private let silenceDuration: TimeInterval = 2.0 // seconds
    private var lastSpeechTime: Date?
    
    func isSpeechDetected(audioLevel: Float) -> Bool {
        if audioLevel > threshold {
            lastSpeechTime = Date()
            return true
        }
        
        guard let lastSpeech = lastSpeechTime else {
            return false
        }
        
        let silenceTime = Date().timeIntervalSince(lastSpeech)
        return silenceTime < silenceDuration
    }
}
```

---

## Testing Plan

### Unit Tests

1. **Audio Device Discovery**
   - Test finding BlackHole device by UID
   - Test fallback to default device
   - Test handling missing devices

2. **Audio Level Calculation**
   - Test RMS calculation with known audio samples
   - Test peak detection
   - Test dB conversion

3. **Voice Activity Detection**
   - Test speech detection above threshold
   - Test silence detection below threshold
   - Test hysteresis (2s silence before stopping)

### Integration Tests

1. **AVAudioEngine Device Selection**
   - Test setting BlackHole as input device
   - Test audio capture from BlackHole
   - Test fallback to AVAudioRecorder

2. **Audio Streaming**
   - Test streaming to AssemblyAI
   - Test streaming to Deepgram
   - Test fallback to Whisper

3. **Error Handling**
   - Test device disconnection during recording
   - Test API failures
   - Test network errors

### Manual Tests

1. **Real Meeting Test**
   - Join Zoom/Meet call
   - Start recording in Nota
   - Verify audio levels show real sound
   - Verify transcription appears
   - Verify audio quality

2. **Device Selection Test**
   - Select BlackHole in Settings
   - Start recording
   - Verify BlackHole is used (not physical mic)
   - Switch devices during recording
   - Verify device change works

3. **Voice Activity Detection Test**
   - Start recording
   - Speak for 5 seconds
   - Stay silent for 5 seconds
   - Verify VAD indicator changes
   - Verify API calls stop during silence

---

## Success Metrics

### Critical Metrics

1. **Audio Capture Success Rate**
   - Target: 95% of recordings capture audio successfully
   - Measure: % of recordings with audio level > -40dB

2. **Transcription Accuracy**
   - Target: 90% word accuracy for clear speech
   - Measure: Compare transcript to reference text

3. **User Setup Success Rate**
   - Target: 80% of users complete audio setup successfully
   - Measure: % of users who reach "✅ Audio setup complete"

### Performance Metrics

1. **Audio Latency**
   - Target: <500ms from speech to transcription
   - Measure: Time from audio buffer to transcript update

2. **CPU Usage**
   - Target: <10% CPU during recording
   - Measure: Average CPU usage over 10-minute recording

3. **Memory Usage**
   - Target: <100MB RAM during recording
   - Measure: Peak memory usage over 10-minute recording

### User Experience Metrics

1. **Time to First Transcription**
   - Target: <5 seconds from start recording
   - Measure: Time from click "Record" to first transcript

2. **Error Recovery Time**
   - Target: <30 seconds to fix audio issues
   - Measure: Time from error message to successful recording

3. **User Satisfaction**
   - Target: 4.5/5 stars for audio capture feature
   - Measure: User feedback and ratings

---

## Dependencies

### External Dependencies

1. **BlackHole** (v2.0+)
   - Virtual audio device for system audio capture
   - User must install separately
   - Free and open source

2. **AssemblyAI API** (v3)
   - Real-time transcription with multilingual support
   - Requires API key
   - Fallback to Deepgram/Whisper if unavailable

3. **CoreAudio Framework**
   - macOS system framework for audio I/O
   - Built into macOS
   - No additional installation required

### Internal Dependencies

1. **AudioRecorder.swift**
   - Main audio capture and transcription logic
   - Needs refactoring to use AVAudioEngine by default

2. **DashboardWindow.swift**
   - Settings UI for device selection
   - Needs audio visualization component

3. **MiniWindowController.swift**
   - Recording controls and status
   - Needs audio level indicator

---

## Risks and Mitigations

### Risk 1: BlackHole Not Installed

**Impact**: High - Users cannot capture system audio
**Probability**: High - Not installed by default
**Mitigation**:
- Detect on startup and show clear instructions
- Provide download link and setup guide
- Consider bundling BlackHole installer (if license allows)

### Risk 2: Audio Routing Misconfigured

**Impact**: High - Audio not captured even with BlackHole
**Probability**: Medium - Requires manual setup
**Mitigation**:
- Provide automatic audio routing setup
- Show visual guide with screenshots
- Test audio capture on startup

### Risk 3: AVAudioEngine Performance

**Impact**: Medium - High CPU/memory usage
**Probability**: Low - AVAudioEngine is optimized
**Mitigation**:
- Profile performance with Instruments
- Optimize buffer sizes
- Use efficient audio format (16kHz mono)

### Risk 4: Device Compatibility

**Impact**: Medium - Some devices may not work
**Probability**: Low - BlackHole is well-tested
**Mitigation**:
- Test with multiple audio devices
- Provide fallback to AVAudioRecorder
- Log device information for debugging

---

## Timeline

### Phase 1: Critical Fixes (Week 1)

- [ ] Test AVAudioEngine with BlackHole
- [ ] Add real-time audio level monitoring
- [ ] Add clear error messages
- [ ] Verify transcription works with system audio

### Phase 2: User Experience (Week 2)

- [ ] Add voice activity detection
- [ ] Add audio visualization
- [ ] Add audio device health check
- [ ] Improve setup wizard

### Phase 3: Advanced Features (Week 3)

- [ ] Add global keyboard shortcuts
- [ ] Add automatic audio routing setup
- [ ] Add device health monitoring
- [ ] Add stealth mode

### Phase 4: Polish and Testing (Week 4)

- [ ] Comprehensive testing with real meetings
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] User feedback and iteration

---

## Open Questions

1. **Should we bundle BlackHole installer with Nota?**
   - Pros: Easier setup for users
   - Cons: Larger app size, license considerations

2. **Should we support other virtual audio devices (Loopback, Soundflower)?**
   - Pros: More flexibility for users
   - Cons: More testing and support burden

3. **Should we add audio recording to file (in addition to transcription)?**
   - Pros: Users can review original audio
   - Cons: Privacy concerns, storage space

4. **Should we add speaker diarization (who said what)?**
   - Pros: Better meeting notes
   - Cons: Requires additional API calls, more complex

5. **Should we add noise cancellation/audio enhancement?**
   - Pros: Better transcription accuracy
   - Cons: More CPU usage, complexity

---

## Next Steps

1. **Review this document with user** - Get feedback on priorities and approach
2. **Test AVAudioEngine implementation** - Verify it works with BlackHole
3. **Implement Phase 1 critical fixes** - Get audio capture working
4. **Iterate based on user feedback** - Adjust priorities and features
