# 🆓 COMPLETELY FREE iOS App Store Deployment Guide

## 💰 Total Cost: €0 (assuming you have Apple Developer account)

### What's FREE:
✅ **GitHub Actions**: 2000 minutes/month macOS runners  
✅ **Azure Free Tier**: 5 hours speech + 2M translations/month  
✅ **Netlify**: 125k function calls/month  
✅ **Building & Testing**: Unlimited on GitHub  

## 🚀 3-Step FREE Deployment:

### Step 1: Push to GitHub (FREE)
```bash
# Initialize git if not done
git init
git add .
git commit -m "Live Transcribe iOS App"

# Create repository on github.com, then:
git remote add origin https://github.com/YOURUSERNAME/live-transcribe-iphone.git
git push -u origin main
```

### Step 2: Deploy FREE Backend
Choose one:

#### Option A: Azure Free Tier (Recommended)
```powershell
# Create free Azure account at portal.azure.com
# No credit card required for free tier
.\scripts\deploy-azure-function.ps1
```

#### Option B: Netlify Functions (Alternative)
1. Create account at netlify.com (free)
2. Connect your GitHub repo
3. Netlify will auto-deploy the backend from `netlify/` folder

### Step 3: Configure GitHub Secrets (FREE)
In your GitHub repository → Settings → Secrets and variables → Actions:

**Required for backend:**
- `SPEECH_TOKEN_ENDPOINT`: Your Azure/Netlify function URL

**Required for App Store (when ready):**
- `BUNDLE_ID`: Your unique bundle ID (e.g., `com.yourname.livetranscribe`)
- `DEVELOPMENT_TEAM`: Your Apple Developer Team ID
- `CERTIFICATES_P12`: Base64 encoded iOS Distribution certificate
- `CERTIFICATES_P12_PASSWORD`: Certificate password

**Optional (for auto-upload):**
- `APPSTORE_KEY_ID`: App Store Connect API Key ID
- `APPSTORE_ISSUER_ID`: App Store Connect Issuer ID  
- `APPSTORE_API_KEY`: App Store Connect API Key (.p8 file content)

## 📱 What Happens Next:

### Automatic on Every Push:
1. **Test Build**: Builds and tests on iOS Simulator (FREE)
2. **App Store Build**: Creates IPA when certificates are available
3. **Auto-Upload**: Uploads to App Store Connect if API keys set

### Getting Your App Store Ready:

#### 1. Get iOS Distribution Certificate (FREE on Mac)
```bash
# If you have Mac access:
# 1. Open Keychain Access
# 2. Certificate Assistant → Request Certificate from Certificate Authority
# 3. Upload to Apple Developer portal
# 4. Download iOS Distribution certificate
# 5. Export as .p12 file
# 6. Convert to base64: base64 -i certificate.p12 | pbcopy
```

#### 2. No Mac? Use GitHub Codespaces (FREE)
```bash
# In GitHub Codespaces (free tier):
# Generate certificate signing request and manage certificates online
```

#### 3. Alternative: Certificate as a Service
- Use services like **Bitrise** or **Codemagic** free tiers
- They can generate certificates for you

## 🔧 Troubleshooting:

### Build Fails?
- Check GitHub Actions logs
- Simulator builds should always work
- Device builds need proper certificates

### Backend Issues?
- Azure free tier has monthly limits
- Netlify alternative included as backup
- Both provide function endpoints for token service

### No Mac for Certificates?
- Use GitHub Codespaces free tier (Linux/macOS)
- Use online certificate generators
- Ask someone with Mac to generate for you

## 📊 Free Tier Limits:

### GitHub Actions (Monthly):
- 2000 minutes macOS runners
- Enough for 100+ builds

### Azure Free:
- 5 hours speech recognition
- 2M characters translation
- 1M function requests

### Netlify Free:
- 125k function invocations
- 100GB bandwidth

## 🎯 Your Action Plan:

### Today (5 minutes):
1. Push code to GitHub
2. Trigger build to test (automatic)

### This Week:
1. Deploy backend (Azure free or Netlify)
2. Get iOS Distribution certificate
3. Add secrets to GitHub
4. Trigger App Store build

### Result:
- Fully automated iOS App Store deployment
- €0 ongoing costs (within free tiers)
- Professional CI/CD pipeline

## 🚨 Important Notes:

1. **Free tiers reset monthly** - perfect for indie development
2. **Certificate generation requires Mac** - but GitHub Codespaces can work
3. **App Store review is separate** - focus on getting the build uploaded first

## 🎉 Success Metrics:
- ✅ Green build in GitHub Actions
- ✅ Backend function responding
- ✅ IPA file generated
- ✅ Upload to App Store Connect

**Ready to start?** Push your code to GitHub and watch the magic happen! The workflow I created will automatically build and test your app on every push.
