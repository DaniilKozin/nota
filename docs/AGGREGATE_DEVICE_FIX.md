# Fix: Microphone Not Working for Other Apps

## Problem
When Nota records audio, other people can't hear you in calls (Zoom, Teams, etc.) because Nota is using the microphone exclusively.

## Solution: Create Multi-Output Device

### Step 1: Open Audio MIDI Setup
1. Open **Spotlight** (CMD+Space)
2. Type "Audio MIDI Setup"
3. Press Enter

### Step 2: Create Multi-Output Device
1. Click the **+** button at bottom left
2. Select **"Create Multi-Output Device"**
3. Name it: **"Nota + Passthrough"**

### Step 3: Configure Multi-Output Device
Check these devices in the list:
- ✅ **Your Microphone** (e.g., "Mac mini Microphone", "External Microphone")
- ✅ **Your Output Device** (e.g., "Mac mini Speakers", "Headphones")

**Important**: Make sure "Drift Correction" is enabled for all devices except the first one.

### Step 4: Create Aggregate Device (Optional)
If you need both input and output:
1. Click **+** → **"Create Aggregate Device"**
2. Name it: **"Nota Full Audio"**
3. Check:
   - ✅ Your Microphone (for input)
   - ✅ Multi-Output Device (for output)

### Step 5: Configure Nota
1. Open Nota
2. Click menu bar icon → **Dashboard**
3. Go to **Settings** tab
4. Under "Input Device", select:
   - **"Nota + Passthrough"** (if using Multi-Output)
   - OR **"Nota Full Audio"** (if using Aggregate)

### Step 6: Configure System
1. Open **System Settings** → **Sound**
2. Set **Output** to: **"Nota + Passthrough"** or your normal output
3. Set **Input** to: Your normal microphone (NOT the aggregate device)

## Alternative: Use BlackHole (Recommended)

BlackHole is a virtual audio driver that doesn't block your microphone.

### Install BlackHole
```bash
brew install blackhole-2ch
```

### Configure with BlackHole
1. Open **Audio MIDI Setup**
2. Create **Multi-Output Device**:
   - ✅ BlackHole 2ch
   - ✅ Your normal output (speakers/headphones)
3. Create **Aggregate Device**:
   - ✅ Your microphone
   - ✅ BlackHole 2ch
4. In Nota Settings:
   - Input Device: **Aggregate Device**
5. In System Settings → Sound:
   - Output: **Multi-Output Device**
   - Input: **Your normal microphone**

## How It Works

**Without Fix:**
```
Microphone → Nota (EXCLUSIVE) → ❌ Other apps can't access
```

**With Multi-Output:**
```
Microphone → Nota → ✅ Passthrough to system → ✅ Other apps can access
```

**With BlackHole:**
```
Microphone → System → ✅ All apps (including Nota)
BlackHole → Nota (for recording)
```

## Verify It Works

1. Start recording in Nota
2. Open **Zoom/Teams/Discord**
3. Check if your microphone works in the call
4. If you see audio levels moving → ✅ Fixed!

## Troubleshooting

### Still not working?
- Make sure Nota is using the **Aggregate/Multi-Output device**, not your direct microphone
- Check that "Drift Correction" is enabled in Audio MIDI Setup
- Restart Nota after changing audio devices

### Audio quality issues?
- Make sure all devices use the same sample rate (48000 Hz recommended)
- In Audio MIDI Setup, select your device → Format → 48000 Hz

### Echo or feedback?
- Don't use the same device for both input and output in the aggregate device
- Use headphones instead of speakers

## Need Help?

Open an issue: https://github.com/DaniilKozin/nota/issues
