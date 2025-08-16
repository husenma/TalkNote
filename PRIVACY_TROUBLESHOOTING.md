# TalkNote Privacy & Permissions Troubleshooting Guide

## Privacy Permission Issues

### Problem: "This app has crashed because it attempted to access privacy-sensitive data without a usage description"

**Root Causes:**
1. Info.plist not properly embedded in the app bundle
2. Xcode not recognizing the Info.plist file
3. Permission keys not properly formatted

**Solutions:**

### 1. Verify Info.plist Location
- Ensure `Info.plist` is in the correct location: `ios/LiveTranscribe/Info.plist`
- In Xcode project settings, verify Info.plist path is correctly set
- Check that Info.plist is included in the app bundle

### 2. Clean Build Process
```bash
# In Xcode:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Delete Derived Data: Xcode → Preferences → Locations → Derived Data → Delete
3. Restart Xcode
4. Build and run again
```

### 3. Verify Info.plist Keys
The Info.plist MUST contain these exact keys:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>TalkNote needs access to your microphone to record your voice for real-time transcription and translation between multiple languages. Your audio is processed securely and only used for translation purposes.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>TalkNote uses speech recognition to accurately convert your spoken words into text for translation between Indian languages and English. This enables seamless communication across language barriers.</string>
```

### 4. Xcode Project Configuration
1. Select your project in Xcode navigator
2. Select your app target
3. Go to Info tab
4. Verify these keys exist with proper descriptions:
   - Privacy - Microphone Usage Description
   - Privacy - Speech Recognition Usage Description

## App Not Appearing in iPhone Settings

### Problem: App doesn't show up in iPhone Settings → Privacy → Microphone/Speech Recognition

**Causes:**
1. App hasn't requested permissions yet
2. Info.plist keys missing or malformed
3. App bundle identifier conflicts

**Solutions:**

### 1. Request Permissions Programmatically
The app now includes automatic permission requests on startup. If this doesn't work:
```swift
// Manual permission request in ContentView.swift
AVAudioSession.sharedInstance().requestRecordPermission { granted in
    print("Microphone: \(granted)")
}

SFSpeechRecognizer.requestAuthorization { status in
    print("Speech: \(status)")
}
```

### 2. Check Bundle Identifier
- Ensure bundle identifier is unique: `com.talknote.app` (or your custom ID)
- Avoid conflicts with existing apps

### 3. iOS Settings Reset (Last Resort)
- Settings → General → Reset → Reset Location & Privacy
- This will reset all app permissions and force re-requests

## UI Language Dropdown Issues

### Problem: Language selection dropdown not working properly

**Improvements Made:**
1. Enhanced visual feedback with animated chevron
2. Better touch targets and padding
3. Proper state management with `@State`
4. Added more language options with flag emojis

**Troubleshooting:**
- If dropdown still doesn't work, try tapping slightly above/below the dropdown area
- Ensure device has iOS 16.0+ for proper Menu support
- Check that `supportedLanguages` array is properly populated

## Deployment Checklist

### Before Building:
1. ✅ Info.plist contains required privacy keys
2. ✅ Bundle identifier is unique
3. ✅ App version and build numbers are set
4. ✅ Clean build folder
5. ✅ All Swift files compile without errors

### Testing Permissions:
1. ✅ Delete app from device/simulator
2. ✅ Fresh install and launch
3. ✅ Permission prompts appear immediately
4. ✅ App appears in Settings → Privacy after permission requests
5. ✅ Audio recording works after granting permissions

### UI Testing:
1. ✅ Language dropdowns work properly
2. ✅ Permission status indicators update correctly
3. ✅ Microphone button responds to permission state
4. ✅ Permission onboarding screen appears for new users

## Common Xcode Issues

### Issue: "Command SwiftCompile failed with a nonzero exit code"
**Solution:** Clean build folder, delete derived data, restart Xcode

### Issue: Info.plist changes not taking effect
**Solution:** 
1. Clean build
2. Delete app from device/simulator
3. Fresh install

### Issue: Simulator vs Device behavior differences
**Solution:** Always test on real device for permission-related features

## Support Information

If issues persist:
1. Check iOS version compatibility (requires iOS 16.0+)
2. Verify Xcode version (14.0+ recommended)
3. Test on multiple devices/iOS versions
4. Check Console.app for detailed error messages

The app now includes comprehensive debugging through `PermissionDebugger` which logs detailed permission states to help identify issues.
