import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @StateObject private var vm = TranscriptionViewModel()
    @State private var permissionsGranted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                Text(vm.displayText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            HStack {
                Button(action: { vm.toggle() }) {
                    Label(vm.isTranscribing ? "Stop" : "Start", systemImage: vm.isTranscribing ? "stop.circle" : "mic.circle")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Picker("Target", selection: $vm.targetLanguage) {
                    ForEach(vm.supportedTargets, id: \.self) { lang in
                        Text(lang.uppercased()).tag(lang)
                    }
                }.pickerStyle(.menu)
            }.padding()
        }
        .onAppear {
            requestPermissions()
        }
    }
    
    private func requestPermissions() {
        // Request microphone permission first
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // Then request speech recognition permission
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        self.permissionsGranted = (status == .authorized)
                        if self.permissionsGranted {
                            vm.requestPermissions()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
