# TalkNote - Live Speech Transcription iOS App

A real-time speech transcription and translation iOS application that automatically detects languages and translates to English.

## Features

- 🎤 **Real-time Speech Recognition** - Continuous audio capture and transcription
- 🌍 **Automatic Language Detection** - Detects spoken language automatically
- 🔄 **Live Translation** - Real-time translation to English
- 📱 **iOS Native** - Built with Swift and SwiftUI
- 🔊 **High Accuracy** - Designed to capture every word with minimal loss

## Requirements

- iOS 15.0+
- iPhone with microphone
- Microphone and Speech permissions

## Installation

1. Clone this repository
2. Open `ios/LiveTranscribe/Package.swift` in Xcode
3. Build and run on your iOS device

## Configuration

To enable translation features, configure Azure Translator keys in `TranslatorService.swift`:
```swift
struct AzureConfig {
    static var translatorKey: String = "YOUR_TRANSLATOR_KEY"
    static var translatorRegion: String = "YOUR_REGION" // e.g., eastus, westeurope
}
```

## Privacy

This app requires microphone access for speech recognition. All processing is done locally on your device when possible, with optional cloud translation services.

## License

MIT License - See LICENSE file for details
