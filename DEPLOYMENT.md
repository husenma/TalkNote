# Live Transcribe iOS App - App Store Deployment Guide

## Prerequisites
- macOS with Xcode 14+ installed
- Active Apple Developer account ($99/year)
- Azure account for the Speech token service

## Step-by-Step App Store Deployment

### 1. Deploy Azure Backend (Token Service)

**Option A: Using Azure CLI (Recommended)**
```bash
# Make script executable
chmod +x scripts/deploy-azure-function.sh

# Run deployment script
./scripts/deploy-azure-function.sh
```

**Option B: Manual Azure Portal Setup**
1. Create a new Function App (Linux, Node.js 20)
2. Create a Speech Services resource
3. Deploy the function code from `azure/functions/`
4. Set app settings: `SPEECH_KEY` and `SPEECH_REGION`
5. Get the function URL with key

### 2. Configure iOS App

1. **Update Info.plist**
   ```bash
   # Replace with your actual function URL
   /usr/libexec/PlistBuddy -c "Set :SPEECH_TOKEN_ENDPOINT https://your-func.azurewebsites.net/api/speechToken?code=YOUR_KEY" ios/LiveTranscribe/Info.plist
   ```

2. **Update Bundle ID and Team**
   Edit `project.yml`:
   - Replace `com.yourcompany.LiveTranscribe` with your unique bundle ID
   - Replace `YOUR_TEAM_ID` with your Apple Developer Team ID

### 3. Apple Developer Account Setup

1. **App ID Registration**
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Create new App ID with your bundle identifier
   - Enable required capabilities (none specific needed for this app)

2. **Distribution Certificate**
   - Create iOS Distribution certificate
   - Download and install in Keychain

3. **Provisioning Profile**
   - Create App Store Distribution provisioning profile
   - Associate with your App ID and Distribution certificate

### 4. Build for App Store

```bash
# Make build script executable
chmod +x scripts/build-appstore.sh

# Run the build
./scripts/build-appstore.sh
```

This script will:
- Generate Xcode project using XcodeGen
- Build and archive for Release
- Export IPA for App Store submission

### 5. App Store Connect Setup

1. **Create App Record**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create new app with your bundle ID
   - Fill in app metadata:
     - Name: "Live Transcribe"
     - Subtitle: "Real-time speech translation"
     - Category: Productivity
     - Keywords: "transcribe,translation,speech,voice,accessibility"

2. **App Information**
   - Description: Focus on real-time translation and accessibility
   - Screenshots: Required for all supported device sizes
   - Privacy Policy URL: Required (create and host one)

3. **Pricing and Availability**
   - Set pricing (Free recommended initially)
   - Select countries/regions

### 6. Upload to App Store

**Option A: Using Xcode Organizer**
1. Open Xcode
2. Window > Organizer
3. Select your archive
4. Click "Distribute App" > "App Store Connect"
5. Follow the upload wizard

**Option B: Using Transporter**
1. Download Transporter from Mac App Store
2. Drag your IPA file (`build/AppStore/LiveTranscribe.ipa`)
3. Click "Deliver"

### 7. Submit for Review

1. In App Store Connect:
   - Go to your app
   - Select the uploaded build
   - Complete all required fields
   - Submit for review

2. **Review Guidelines Compliance**
   - Privacy: Clearly explain microphone usage
   - Functionality: Ensure app works without Azure endpoints (fallback)
   - Content: Verify all translations are appropriate

### 8. Post-Submission

- **Review Process**: Usually 24-48 hours
- **Metadata Updates**: Can be changed anytime
- **New Builds**: Increment `CURRENT_PROJECT_VERSION` in `project.yml`

## Troubleshooting

### Build Issues
- **Code Signing**: Ensure certificates and provisioning profiles are valid
- **Bundle ID Mismatch**: Verify Bundle ID matches App Store Connect
- **Missing Entitlements**: Check if microphone usage description is present

### Azure Function Issues
- **401 Errors**: Check function key in URL
- **500 Errors**: Verify `SPEECH_KEY` and `SPEECH_REGION` app settings
- **Network**: Ensure function URL is accessible from iOS devices

### App Store Rejection
- **Privacy**: Add privacy policy URL
- **Functionality**: Ensure app works in airplane mode (show appropriate message)
- **Metadata**: Match screenshots with actual app functionality

## Maintenance

### Updating the App
1. Increment version in `project.yml`
2. Build and upload new version
3. Submit update for review

### Monitoring
- Check Azure Function logs for usage patterns
- Monitor App Store Connect for crash reports
- Update Speech/Translator keys as needed

## Cost Considerations

- **Apple Developer**: $99/year
- **Azure Speech**: Pay-per-use (first 5 hours free monthly)
- **Azure Functions**: Consumption plan (first 1M requests free)
- **Estimated monthly cost**: $5-20 for moderate usage

## Support

For issues:
1. Check build logs in Xcode
2. Review Azure Function logs in Azure Portal
3. Test token endpoint manually with curl
4. Verify iOS permissions in device Settings
