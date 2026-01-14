# Audio Setup Guide - Capturing Both Sides of a Call

## Problem
By default, macOS Speech Framework only captures your microphone, not system audio (sound from browser, Zoom, Teams, etc.).

## Solution: Aggregate Device with BlackHole

### ⚠️ IMPORTANT: Nota does NOT change system audio device automatically!
This is intentional to avoid breaking Zoom/Teams. You need to manually set the aggregate device as system input.

### Step 1: Install BlackHole
1. Download BlackHole: https://github.com/ExistentialAudio/BlackHole
2. Install BlackHole 2ch (or 16ch)
3. Restart Mac (optional)

### Step 2: Create Aggregate Device
1. Open **Audio MIDI Setup** (Finder → Applications → Utilities → Audio MIDI Setup)
2. Click **+** (bottom left) → **Create Aggregate Device**
3. Name it, for example: "Nota Recording"
4. Enable (✓) these devices:
   - **Built-in Microphone** (or your microphone)
   - **BlackHole 2ch**
5. Important: Set **Clock Source** to Built-in Microphone
6. Close Audio MIDI Setup

### Step 3: Set Aggregate Device as System Input
**Option A: Via System Settings (recommended)**
1. System Settings → Sound → Input
2. Select your Aggregate Device ("Nota Recording")

**Option B: Via Audio MIDI Setup**
1. Right-click on Aggregate Device
2. "Use This Device For Sound Input"

### Step 4: Configure Meeting Apps
For Zoom/Teams/Google Meet:
1. In app settings:
   - **Input**: Aggregate Device ("Nota Recording") - your voice
   - **Output**: BlackHole 2ch - partner's voice goes to BlackHole
2. This redirects partner's audio to BlackHole
3. Nota will capture: microphone + BlackHole (partner's voice)

### Step 5: Start Recording in Nota
1. Open Nota Dashboard
2. Click Record
3. Nota automatically uses system input (your Aggregate Device)

## How It Works

```
Microphone → Aggregate Device ┐
                              ├→ System Input → Nota
BlackHole ← Zoom/Teams -------┘
```

1. **Your voice**: Microphone → Aggregate Device → System Input → Nota
2. **Partner's voice**: Zoom → BlackHole → Aggregate Device → System Input → Nota
3. **Zoom hears you**: Aggregate Device (microphone) → Zoom Input
4. **Result**: Nota hears both, Zoom works normally!

## Alternative: Multi-Output Device (for listening)

If you want to **hear** your partner in headphones:

1. Create **Multi-Output Device** in Audio MIDI Setup
2. Enable:
   - **BlackHole 2ch**
   - **Built-in Output** (or headphones)
3. In Zoom/Teams select Output: Multi-Output Device
4. Now audio goes to both BlackHole (for Nota) and headphones (for you)

## Verification

### 1. Check System Settings:
```
System Settings → Sound → Input
Should show: Aggregate Device ("Nota Recording")
```

### 2. Check Zoom/Teams:
```
Settings → Audio
Input: Aggregate Device ("Nota Recording")
Output: BlackHole 2ch (or Multi-Output Device)
```

### 3. In Nota console (when starting recording):
```
🎤 Starting Speech Framework recording...
🎧 Selected audio device: default
🎧 Using system default audio input device
🎧 Current input device: Nota Recording (ID: ...)
🎤 Audio format: 48000Hz, 2 channels
✅ Speech Framework recording started successfully
🎧 Recording from: Nota Recording
```

## Troubleshooting

### Not capturing partner's voice in Nota
1. ✅ Check System Settings → Sound → Input = Aggregate Device
2. ✅ Check Zoom/Teams Output = BlackHole 2ch
3. ✅ Check Aggregate Device created correctly
4. ✅ Restart recording in Nota

### Partner can't hear me
1. ✅ Check Zoom/Teams Input = Aggregate Device (NOT BlackHole!)
2. ✅ Check microphone is enabled in Aggregate Device
3. ✅ Check microphone level in System Settings

### Can't hear partner in headphones
1. ✅ Create Multi-Output Device (see above)
2. ✅ In Zoom/Teams Output = Multi-Output Device
3. ✅ Check headphones enabled in Multi-Output Device

### Aggregate Device not appearing
1. ✅ Restart Nota
2. ✅ Check Aggregate Device created in Audio MIDI Setup
3. ✅ Check device is enabled (✓)
4. ✅ Set as system input in System Settings

### Poor audio quality
1. ✅ Increase Sample Rate in Audio MIDI Setup (48000 Hz)
2. ✅ Check Clock Source (should be on microphone)
3. ✅ Ensure both devices in Aggregate are enabled

## Why Nota Doesn't Change System Device Automatically?

**Reason:** Programmatically changing the system default input device breaks other apps (Zoom, Teams, Discord, etc.) that are already using the microphone.

**Solution:** User manually sets Aggregate Device as system input once, and all apps (including Nota) use it.

**Benefits:**
- ✅ Zoom/Teams continue working normally
- ✅ Partner hears you
- ✅ Nota captures both voices
- ✅ No need to switch devices each time

## Current Implementation in Nota

### What Nota Does:
✅ Automatically discovers all audio input devices  
✅ Shows them in Settings (for information)  
✅ Uses system default input device  
✅ Does NOT change system default (to avoid breaking other apps)  
✅ Logs current device to console  

### What Nota Does NOT Do:
❌ Does NOT change system default input device  
❌ Does NOT switch devices automatically  
❌ Does NOT create aggregate devices automatically  

## Recommended Setup

### For Regular Use:
1. Create Aggregate Device once
2. Set it as system input in System Settings
3. Configure Zoom/Teams once
4. Use Nota without additional setup

### For Temporary Use:
1. Before meeting: set Aggregate Device as system input
2. After meeting: revert to Built-in Microphone as system input

## Useful Links

- BlackHole: https://github.com/ExistentialAudio/BlackHole
- Audio MIDI Setup: `/Applications/Utilities/Audio MIDI Setup.app`
- System Settings → Sound: `System Settings.app`

---

**Note**: Nota uses the system default input device, so you need to manually set the Aggregate Device as system input in System Settings.
