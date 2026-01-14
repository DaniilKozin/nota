#!/bin/bash

# Nota Version Management Script
# Manages version numbers across all project files

VERSION_FILE="VERSION"
CURRENT_VERSION=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Read current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
else
    CURRENT_VERSION="2.1.0"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
fi

# Function to update version in files
update_version() {
    local new_version=$1
    
    echo -e "${YELLOW}📝 Updating version to ${new_version}...${NC}"
    
    # Update VERSION file
    echo "$new_version" > "$VERSION_FILE"
    
    # Update Package.swift (if needed)
    # Currently Package.swift doesn't have version, but we can add it
    
    # Update Info.plist template in create_app_bundle.sh
    sed -i '' "s/<string>[0-9]\+\.[0-9]\+\.[0-9]\+<\/string>/<string>${new_version}<\/string>/g" create_app_bundle.sh
    
    # Update DMG name in create_dmg.sh
    local short_version=$(echo $new_version | cut -d. -f1,2)
    sed -i '' "s/DMG_NAME=\"Nota-v[0-9]\+\.[0-9]\+/DMG_NAME=\"Nota-v${short_version}/g" create_dmg.sh
    sed -i '' "s/VOLUME_NAME=\"Nota v[0-9]\+\.[0-9]\+/VOLUME_NAME=\"Nota v${short_version}/g" create_dmg.sh
    
    echo -e "${GREEN}✅ Version updated to ${new_version}${NC}"
    echo ""
    echo "Updated files:"
    echo "  • VERSION"
    echo "  • create_app_bundle.sh (Info.plist)"
    echo "  • create_dmg.sh (DMG name)"
}

# Function to bump version
bump_version() {
    local bump_type=$1
    local major minor patch
    
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    
    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}❌ Invalid bump type: $bump_type${NC}"
            echo "Use: major, minor, or patch"
            exit 1
            ;;
    esac
    
    local new_version="${major}.${minor}.${patch}"
    update_version "$new_version"
}

# Main script
case "${1:-}" in
    get)
        echo "$CURRENT_VERSION"
        ;;
    set)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Error: Version number required${NC}"
            echo "Usage: $0 set <version>"
            exit 1
        fi
        update_version "$2"
        ;;
    bump)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Error: Bump type required${NC}"
            echo "Usage: $0 bump <major|minor|patch>"
            exit 1
        fi
        bump_version "$2"
        ;;
    *)
        echo "Nota Version Manager"
        echo "===================="
        echo ""
        echo "Current version: ${GREEN}${CURRENT_VERSION}${NC}"
        echo ""
        echo "Usage:"
        echo "  $0 get                  - Show current version"
        echo "  $0 set <version>        - Set specific version (e.g., 2.2.0)"
        echo "  $0 bump major           - Bump major version (2.1.0 → 3.0.0)"
        echo "  $0 bump minor           - Bump minor version (2.1.0 → 2.2.0)"
        echo "  $0 bump patch           - Bump patch version (2.1.0 → 2.1.1)"
        echo ""
        echo "Examples:"
        echo "  $0 bump minor           # 2.1.0 → 2.2.0"
        echo "  $0 set 3.0.0            # Set to 3.0.0"
        ;;
esac
