# Live Transcribe iPhone App

A real-time speech transcription and translation iOS application that automatically detects languages and translates to English.

## Features

- 🎤 **Real-time Speech Recognition** - Continuous audio capture and transcription
- 🌍 **Automatic Language Detection** - Detects spoken language automatically
- 🔄 **Live Translation** - Real-time translation to English
- 🧠 **AI-Powered Learning** - Uses Azure Cognitive Services for continuous improvement
- 📱 **iOS Native** - Built with Swift and SwiftUI
- 🔊 **High Accuracy** - Designed to capture every word with minimal loss

## Architecture

### Core Components
1. **Audio Manager** - Handles microphone input and audio processing
2. **Speech Service** - Interfaces with Azure Speech Services
3. **Translation Service** - Handles language detection and translation
4. **UI Components** - SwiftUI interface for real-time display
5. **Data Models** - Core data structures for transcription and translation

### Services Used
- Apple Speech framework (fallback) for streaming transcription
- Azure Speech SDK (preferred) for auto language detection + streaming translation
- Azure Translator (REST) for fallback translation

## Requirements

- macOS with Xcode 14+ (builds iOS apps)
- iOS 15.0+
- Azure Translator resource (key + region)
- Microphone and Speech permissions (declared in Info.plist)
 - Optional CI on macOS runner via GitHub Actions + XcodeGen

## Setup Instructions

1. Clone this repository
2. On macOS, open Xcode and create a new iOS App project named "LiveTranscribe" (SwiftUI, iOS 15+)
3. In the project navigator, add the contents of `ios/LiveTranscribe/Sources` to the app target
4. Replace the project's `Info.plist` with `ios/LiveTranscribe/Info.plist` (or merge the microphone/speech keys)
5. Configure Azure Translator keys in `ios/LiveTranscribe/Sources/TranslatorService.swift` (AzureConfig) for fallback
6. Add the Azure Speech SDK to your Xcode project via Swift Package Manager or CocoaPods (module: MicrosoftCognitiveServicesSpeech)
7. Deploy a minimal backend that returns a Speech token (recommended: Azure Function)
    - `GET /api/speechToken` -> `{ "token": "<speechToken>", "region": "<speechRegion>" }`
    - Put this URL into `Info.plist` as `SPEECH_TOKEN_ENDPOINT`
8. Select a physical device and run

### CI from Windows using GitHub Actions
This repo includes `.github/workflows/ios-ci.yml` and `project.yml` for XcodeGen. Push to `main` or open a PR and the macOS runner will:
- Install XcodeGen
- Generate the Xcode project
- Build and run tests on iOS Simulator

You can review build results under the Actions tab in GitHub.

## Configuration

Set the Azure Translator values in `TranslatorService.swift` (fallback path):
```swift
struct AzureConfig {
    static var translatorKey: String = "<SET-TRANSLATOR-KEY>"
    static var translatorRegion: String = "<SET-REGION>" // e.g., eastus, westeurope
}
```

Optional: Replace Apple Speech with Azure Speech SDK for auto language detection and custom models.

### Secure token flow for Azure Speech
- Never embed subscription keys in the app.
- Use an Azure Function/App Service to mint short-lived tokens using your Speech subscription.
- iOS app retrieves token via `SPEECH_TOKEN_ENDPOINT` and sets it on the recognizer.

Minimal Azure Function (C#) outline:
- Reads `SPEECH_KEY` and `SPEECH_REGION` from app settings.
- Calls `https://{region}.api.cognitive.microsoft.com/sts/v1.0/issueToken` with key.
- Returns `{ token, region }`.

## Azure Function (Node.js) included
This repo includes a minimal Node.js v4 Azure Function at `azure/functions/speech-token` that returns `{ token, region }`.

Configure in Azure:
- App Settings: `SPEECH_KEY` and `SPEECH_REGION`
- Auth level is `function` by default; you can switch to `anonymous` if fronted by your own auth gateway.

Deploy options:
- Azure Functions Core Tools
- Azure Portal -> Deploy from GitHub

### GitHub Actions secrets
Set the following repository secrets so CI can wire the iOS build:
- `SPEECH_TOKEN_ENDPOINT` e.g., `https://<your-func>.azurewebsites.net/api/speechToken?code=<function-key>`
- Optional: `TRANSLATOR_KEY`, `TRANSLATOR_REGION` (if you later script injection)

The workflow step updates `Info.plist` with `SPEECH_TOKEN_ENDPOINT` so the app uses token auth at runtime.

## Privacy

This app requires microphone access. Transcription may use Apple Speech; translation uses Azure Translator via HTTPS.

## License

MIT License - See LICENSE file for details
