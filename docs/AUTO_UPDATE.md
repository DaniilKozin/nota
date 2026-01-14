# Auto-Update System for Nota

## Overview

Nota includes an automatic update checker that notifies users when new versions are available on GitHub.

## Features

✅ **Automatic checks** - Checks for updates once per day on app launch  
✅ **Manual checks** - Users can check anytime from menu or settings  
✅ **GitHub integration** - Fetches latest release from GitHub API  
✅ **Version comparison** - Smart semantic version comparison  
✅ **Direct download** - Opens GitHub release page or DMG download  
✅ **Release notes** - Shows what's new in the update  

## For Users

### Automatic Checks

Nota automatically checks for updates once per day when you launch the app. If an update is available, you'll see a notification.

### Manual Check

**Method 1: Status Bar Menu**
1. Right-click the microphone icon in menu bar
2. Select "Check for Updates..."

**Method 2: Dashboard Settings**
1. Open Dashboard (home icon)
2. Go to Settings tab
3. Scroll to "About" section
4. Click "Check for Updates" button

### Installing Updates

When an update is available:
1. Click "Download" in the dialog
2. Download the new DMG file
3. Run `install_nota.sh` from the DMG
4. Or manually: `xattr -cr /Applications/Nota.app`

## For Developers

### How It Works

1. **GitHub API** - Fetches latest release info
   ```
   GET https://api.github.com/repos/daniilkozin/nota/releases/latest
   ```

2. **Version Comparison** - Compares semantic versions
   ```swift
   Current: 2.1.0
   Latest:  2.2.0
   Result:  Update available ✅
   ```

3. **User Notification** - Shows dialog with options
   - Download (opens GitHub release)
   - View Release Notes
   - Later (dismiss)

### Configuration

Update the GitHub repo in `UpdateChecker.swift`:

```swift
private let githubRepo = "daniilkozin/nota" // Change to your username
```

### Check Frequency

Updates are checked:
- **On launch** - Once per day (24 hours)
- **Manual** - Anytime user clicks "Check for Updates"

Frequency is controlled by:
```swift
// Check once per day (86400 seconds)
if now - lastCheck > 86400 {
    checkForUpdates(silent: true)
}
```

### Silent vs Interactive

**Silent check** (on launch):
- No dialog if already up to date
- Only shows dialog if update available

**Interactive check** (manual):
- Always shows dialog
- "You're up to date!" or "Update available"

## Release Workflow

### 1. Create New Release

```bash
cd Nota-Swift

# Update version
./version.sh bump minor  # 2.1.0 → 2.2.0

# Build
./build.sh

# Commit and tag
VERSION=$(cat VERSION)
git add .
git commit -m "Release v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin main
git push origin "v${VERSION}"
```

### 2. Create GitHub Release

1. Go to GitHub → Releases → New Release
2. Choose tag: `v2.2.0`
3. Title: `Nota v2.2.0`
4. Description:
   ```markdown
   ## What's New
   - Feature 1
   - Feature 2
   
   ## Bug Fixes
   - Fixed issue X
   
   ## Installation
   See [GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md)
   ```
5. Upload DMG: `Nota-v2.2-SmartTranscription.dmg`
6. Publish release

### 3. Users Get Notified

- Next time users launch Nota, they'll see update notification
- Or they can manually check for updates

## API Response Format

GitHub API returns:

```json
{
  "tag_name": "v2.2.0",
  "name": "Nota v2.2.0",
  "body": "## What's New\n- Feature 1\n...",
  "assets": [
    {
      "name": "Nota-v2.2-SmartTranscription.dmg",
      "browser_download_url": "https://github.com/.../Nota-v2.2-SmartTranscription.dmg"
    }
  ]
}
```

UpdateChecker parses:
- `tag_name` → Latest version
- `body` → Release notes
- `assets[].browser_download_url` → DMG download link

## Version Comparison

Semantic versioning comparison:

```swift
2.1.0 vs 2.2.0 → Update available ✅
2.2.0 vs 2.1.0 → Already latest ✅
2.1.0 vs 2.1.0 → Already latest ✅
2.1.0 vs 3.0.0 → Update available ✅
```

Algorithm:
1. Split versions by `.` → [2, 1, 0]
2. Compare major, then minor, then patch
3. Return true if new > current

## User Experience

### Update Available Dialog

```
╔═══════════════════════════════════════╗
║        Update Available               ║
╠═══════════════════════════════════════╣
║ A new version of Nota is available!   ║
║                                       ║
║ Current version: v2.1.0               ║
║ Latest version:  v2.2.0               ║
║                                       ║
║ Would you like to download it now?   ║
╠═══════════════════════════════════════╣
║  [Download]  [View Release Notes]    ║
║              [Later]                  ║
╚═══════════════════════════════════════╝
```

### Already Up to Date Dialog

```
╔═══════════════════════════════════════╗
║        You're up to date!             ║
╠═══════════════════════════════════════╣
║ Nota v2.2.0 is the latest version.   ║
╠═══════════════════════════════════════╣
║              [OK]                     ║
╚═══════════════════════════════════════╝
```

## Testing

### Test Update Check

```bash
# 1. Build current version
cd Nota-Swift
./build.sh

# 2. Create a newer release on GitHub
./version.sh set 2.3.0
./build.sh
# Upload to GitHub as v2.3.0

# 3. Revert to old version locally
./version.sh set 2.2.0
./build.sh

# 4. Run app and check for updates
open Nota.app
# Right-click menu → Check for Updates
# Should show: Update available to v2.3.0
```

### Test No Update

```bash
# 1. Build latest version
./version.sh set 2.3.0
./build.sh

# 2. Check for updates
open Nota.app
# Right-click menu → Check for Updates
# Should show: You're up to date!
```

## Troubleshooting

### Update check fails

**Symptom:** No dialog appears, console shows error

**Causes:**
1. No internet connection
2. GitHub API rate limit (60 requests/hour)
3. Invalid repo name
4. No releases on GitHub

**Solution:**
```bash
# Check console logs
open Nota.app
# Look for: "❌ Update check failed: ..."

# Test GitHub API manually
curl https://api.github.com/repos/daniilkozin/nota/releases/latest
```

### Wrong version detected

**Symptom:** Shows update available when already on latest

**Cause:** Version in Info.plist doesn't match GitHub tag

**Solution:**
```bash
# Check current version
defaults read "$(pwd)/Nota.app/Contents/Info.plist" CFBundleShortVersionString

# Should match GitHub tag (without 'v' prefix)
# GitHub: v2.2.0
# Info.plist: 2.2.0
```

### Download button doesn't work

**Symptom:** Clicking "Download" does nothing

**Cause:** No DMG asset in GitHub release

**Solution:**
1. Go to GitHub release
2. Edit release
3. Upload DMG file
4. DMG filename must end with `.dmg`

## Advanced Configuration

### Change Check Frequency

Edit `UpdateChecker.swift`:

```swift
// Check once per day (86400 seconds)
if now - lastCheck > 86400 {  // Change this value
    checkForUpdates(silent: true)
}

// Examples:
// 3600 = 1 hour
// 43200 = 12 hours
// 86400 = 24 hours (default)
// 604800 = 1 week
```

### Disable Auto-Check

```swift
// In main.swift, comment out:
// updateChecker?.checkOnLaunch()
```

Users can still manually check from menu.

### Custom Update Server

To use your own update server instead of GitHub:

```swift
// In UpdateChecker.swift, change:
let urlString = "https://your-server.com/api/latest-version"

// Expected JSON format:
{
  "version": "2.2.0",
  "download_url": "https://your-server.com/Nota-v2.2.dmg",
  "release_notes": "What's new..."
}
```

## Security

### HTTPS Only

All update checks use HTTPS to prevent man-in-the-middle attacks.

### No Auto-Install

Nota **never** automatically downloads or installs updates. Users must:
1. Click "Download"
2. Download DMG manually
3. Install manually

This prevents malicious updates.

### Verify Downloads

Users should verify DMG integrity:

```bash
# Check DMG signature (if signed)
codesign --verify --verbose Nota-v2.2-SmartTranscription.dmg

# Check file size (should be ~2-3 MB)
ls -lh Nota-v2.2-SmartTranscription.dmg
```

## Future Enhancements

### Sparkle Framework

For more advanced updates, consider [Sparkle](https://sparkle-project.org/):
- Automatic download and install
- Delta updates (smaller downloads)
- Code signing verification
- Rollback support

### In-App Updates

Download and install updates without leaving the app:
```swift
// Download DMG
// Mount DMG
// Copy new version
// Restart app
```

Requires more complex implementation and testing.

## Summary

✅ **Simple** - Uses GitHub releases API  
✅ **Secure** - HTTPS only, manual install  
✅ **User-friendly** - Clear dialogs and options  
✅ **Developer-friendly** - Automatic with version.sh  
✅ **No dependencies** - Pure Swift, no frameworks  

---

**Created:** January 14, 2026  
**Version:** 2.1.0  
**Status:** ✅ Implemented and tested
