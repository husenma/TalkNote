#!/bin/bash

# TalkNote Project Verification Script
# This script verifies all components are properly configured

echo "🔍 TalkNote iOS App Verification"
echo "================================"

# Check if we're in the right directory
if [ ! -f "project.yml" ]; then
    echo "❌ Error: Run this script from the project root directory"
    exit 1
fi

echo ""
echo "📁 Project Structure Check:"

# Check iOS files
if [ -f "ios/LiveTranscribe/Package.swift" ]; then
    echo "✅ Swift Package configuration found"
else
    echo "❌ Missing Swift Package configuration"
fi

if [ -f "ios/LiveTranscribe/Info.plist" ]; then
    echo "✅ Info.plist found"
    
    # Check for required privacy keys
    if grep -q "NSMicrophoneUsageDescription" ios/LiveTranscribe/Info.plist; then
        echo "✅ Microphone usage description present"
    else
        echo "❌ Missing microphone usage description"
    fi
    
    if grep -q "NSSpeechRecognitionUsageDescription" ios/LiveTranscribe/Info.plist; then
        echo "✅ Speech recognition usage description present"
    else
        echo "❌ Missing speech recognition usage description"
    fi
else
    echo "❌ Missing Info.plist"
fi

echo ""
echo "🎯 Core iOS Components:"

core_files=(
    "ios/LiveTranscribe/Sources/App.swift"
    "ios/LiveTranscribe/Sources/ContentView.swift"
    "ios/LiveTranscribe/Sources/TranscriptionViewModel.swift"
    "ios/LiveTranscribe/Sources/AudioEngine.swift"
    "ios/LiveTranscribe/Sources/AzureSpeechService.swift"
    "ios/LiveTranscribe/Sources/TranslatorService.swift"
    "ios/LiveTranscribe/Sources/ReinforcementLearningEngine.swift"
    "ios/LiveTranscribe/Sources/SecurityManager.swift"
    "ios/LiveTranscribe/Sources/DesignSystem.swift"
    "ios/LiveTranscribe/Sources/PermissionManager.swift"
    "ios/LiveTranscribe/Sources/StartupPermissionManager.swift"
    "ios/LiveTranscribe/Sources/PermissionOnboardingView.swift"
)

for file in "${core_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $(basename "$file")"
    else
        echo "❌ Missing: $(basename "$file")"
    fi
done

echo ""
echo "🔧 Azure Infrastructure:"

if [ -f "azure/functions/package.json" ]; then
    echo "✅ Azure Functions configuration"
else
    echo "❌ Missing Azure Functions"
fi

if [ -f "netlify/functions/speech-token.js" ]; then
    echo "✅ Netlify Functions backup"
else
    echo "❌ Missing Netlify Functions"
fi

echo ""
echo "📖 Documentation:"

docs=(
    "README.md"
    "DEPLOYMENT.md"
    "APP_STORE_SUBMISSION.md"
    "PRIVACY_POLICY.md"
    "PRIVACY_TROUBLESHOOTING.md"
    "FREE_DEPLOYMENT_GUIDE.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "✅ $doc"
    else
        echo "❌ Missing: $doc"
    fi
done

echo ""
echo "🚀 Build Scripts:"

if [ -f "scripts/build-appstore.sh" ]; then
    echo "✅ App Store build script"
    if [ -x "scripts/build-appstore.sh" ]; then
        echo "✅ Build script is executable"
    else
        echo "⚠️  Build script needs execute permissions: chmod +x scripts/build-appstore.sh"
    fi
else
    echo "❌ Missing App Store build script"
fi

echo ""
echo "🎉 Verification Complete!"
echo ""
echo "Next Steps:"
echo "1. Open ios/LiveTranscribe in Xcode"
echo "2. Set your team and bundle identifier"
echo "3. Build and test on device"
echo "4. Follow DEPLOYMENT.md for App Store submission"
echo ""
echo "For troubleshooting, see: PRIVACY_TROUBLESHOOTING.md"
