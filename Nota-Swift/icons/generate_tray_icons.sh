#!/bin/bash

# Generate tray icons from source image
# Usage: ./generate_tray_icons.sh

SOURCE_IMAGE="Remove_background-1768397997157.png"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Source image not found: $SOURCE_IMAGE"
    echo "Please ensure the source image is in the icons directory"
    exit 1
fi

echo "🎨 Generating tray icons from $SOURCE_IMAGE..."

# Generate different sizes for tray icon
sips -z 18 18 "$SOURCE_IMAGE" --out tray-18x18.png
echo "✅ Created tray-18x18.png"

sips -z 22 22 "$SOURCE_IMAGE" --out tray-22x22.png
echo "✅ Created tray-22x22.png"

sips -z 36 36 "$SOURCE_IMAGE" --out tray-36x36.png
echo "✅ Created tray-36x36.png (Retina)"

# Copy full resolution as fallback
cp "$SOURCE_IMAGE" tray-icon.png
echo "✅ Created tray-icon.png (full resolution)"

echo ""
echo "🎉 All tray icons generated successfully!"
echo ""
echo "Generated files:"
echo "  - tray-18x18.png (18x18px - standard)"
echo "  - tray-22x22.png (22x22px - alternative)"
echo "  - tray-36x36.png (36x36px - Retina)"
echo "  - tray-icon.png (1024x1024px - fallback)"
echo ""
echo "These icons will be used in the menu bar tray."
