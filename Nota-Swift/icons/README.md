# Nota Icons

This directory contains all icon assets for the Nota application.

## Icon Files

### App Icons (for Dock/Finder)
- **AppIcon.icns** - Main app icon (used in Info.plist)
- **app-icon.icns** - Duplicate of AppIcon.icns (for compatibility)
- **icon.icns** - Duplicate of AppIcon.icns (fallback)

All three .icns files are identical and contain multiple resolutions:
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

### Tray Icons (for Menu Bar)
- **tray-18x18.png** - Standard resolution tray icon (18x18px)
- **tray-22x22.png** - Slightly larger tray icon (22x22px)
- **tray-36x36.png** - Retina display tray icon (36x36px = 18x18@2x)
- **tray-icon.png** - Full resolution source (1024x1024px)

### Source Files
- **Remove_background-1768397997157.png** - Original tray icon source (1024x1024px)
- **icon.png** - App icon source (1024x1024px)

### Legacy Files (not used)
- **32x32.png** - Old size variant
- **64x64.png** - Old size variant
- **128x128.png** - Old size variant
- **app-tray-icon.png** - Old tray icon
- **tray-bw-18x18.png** - Old black & white variant

## Icon Usage

### In Code (StatusBarController.swift)
The tray icon is loaded in this order:
1. Try bundle resources: `tray-18x18.png`, `tray-22x22.png`, `tray-icon.png`
2. Try development paths: `Nota-Swift/icons/tray-18x18.png`, etc.
3. Fallback to SF Symbol: `mic.fill`

### In App Bundle (create_app_bundle.sh)
The build script copies these icons to the app bundle:
- `AppIcon.icns` → `Contents/Resources/AppIcon.icns`
- `tray-18x18.png` → `Contents/Resources/tray-18x18.png`
- `tray-22x22.png` → `Contents/Resources/tray-22x22.png`
- `tray-36x36.png` → `Contents/Resources/tray-36x36.png`
- `tray-icon.png` → `Contents/Resources/tray-icon.png`

## Creating New Icons

### To update the tray icon:
1. Replace `Remove_background-1768397997157.png` with your new icon (1024x1024px, transparent background)
2. Run the icon generation script:
```bash
./Nota-Swift/icons/generate_tray_icons.sh
```

### To update the app icon:
1. Replace `icon.png` with your new icon (1024x1024px)
2. Create .icns file:
```bash
mkdir AppIcon.iconset
sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png
iconutil -c icns AppIcon.iconset
rm -rf AppIcon.iconset
```

## Design Guidelines

### Tray Icon
- **Size:** 18x18px (36x36px for Retina)
- **Style:** Monochrome, simple, recognizable at small size
- **Format:** PNG with transparency
- **Template Mode:** Icon should be black on transparent background (macOS will invert for dark mode)

### App Icon
- **Size:** 1024x1024px source
- **Style:** Colorful, detailed, matches brand
- **Format:** .icns with multiple resolutions
- **Background:** Can be opaque or transparent

## Current Icons

### App Icon
- Colorful microphone design
- Professional gradient style
- Matches Nota brand

### Tray Icon
- Simplified microphone silhouette
- Monochrome for menu bar
- Adapts to light/dark mode automatically

## Notes

- All icons are stored in `/Users/daniilkozin/Downloads/Recorder/Nota-Swift/icons/`
- Tray icon uses template mode (isTemplate = true) for automatic dark mode adaptation
- App icon is referenced in Info.plist as "AppIcon"
- Icons are copied to app bundle during build process
