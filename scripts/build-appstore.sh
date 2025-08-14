#!/bin/bash
# Build and prepare iOS app for App Store submission
# Run this on macOS with Xcode installed

set -e

echo "📱 Building Live Transcribe for App Store Distribution"

# Configuration
PROJECT_NAME="LiveTranscribe"
SCHEME="LiveTranscribe"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build/AppStore"

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "❌ Homebrew not found. Please install XcodeGen manually."
        echo "Visit: https://github.com/yonaskolb/XcodeGen"
        exit 1
    fi
fi

if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Generate Xcode project
echo "🔧 Generating Xcode project..."
xcodegen generate

# Create build directory
mkdir -p build

# Verify configuration
echo "📋 Build configuration:"
echo "  Project: ${PROJECT_NAME}.xcodeproj"
echo "  Scheme: $SCHEME"
echo "  Configuration: $CONFIGURATION"
echo "  Archive Path: $ARCHIVE_PATH"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION"

# Build and archive
echo "📦 Building and archiving..."
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

# Create export options plist
echo "📄 Creating export options..."
cat > ./build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

# Export for App Store
echo "📤 Exporting for App Store..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "./build/ExportOptions.plist"

echo "✅ Build complete!"
echo ""
echo "📁 App Store package location:"
echo "  ${EXPORT_PATH}/${PROJECT_NAME}.ipa"
echo ""
echo "🚀 Next steps:"
echo "1. Open Xcode and go to Window > Organizer"
echo "2. Select the archive from: $ARCHIVE_PATH"
echo "3. Click 'Distribute App' and follow the App Store submission process"
echo ""
echo "💡 Alternatively, upload using Transporter app:"
echo "1. Open Transporter (available on Mac App Store)"
echo "2. Drag and drop: ${EXPORT_PATH}/${PROJECT_NAME}.ipa"
echo "3. Click 'Deliver'"
