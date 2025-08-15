import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TranscriptionViewModel()
    @State private var correctionText: String = ""
    @State private var showingCorrectionSheet: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                // 🧠 Learning Stats Display
                if !vm.learningStats.isEmpty {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        Text(vm.learningStats)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Main transcription display
                ScrollView {
                    Text(vm.displayText.isEmpty ? "Tap the microphone to start transcription..." : vm.displayText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundColor(vm.displayText.isEmpty ? .secondary : .primary)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 🧠 Feedback Buttons (when not transcribing)
                if !vm.isTranscribing && !vm.displayText.isEmpty {
                    HStack(spacing: 16) {
                        Button(action: { vm.markAsCorrect() }) {
                            Label("Correct", systemImage: "checkmark.circle")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { vm.markAsIncorrect() }) {
                            Label("Incorrect", systemImage: "x.circle")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingCorrectionSheet = true }) {
                            Label("Fix", systemImage: "pencil.circle")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Main controls
                HStack {
                    Button(action: { vm.toggle() }) {
                        Label(vm.isTranscribing ? "Stop" : "Start", 
                              systemImage: vm.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.correctionMode)
                    
                    Spacer()
                    
                    Picker("Target Language", selection: $vm.targetLanguage) {
                        ForEach(vm.supportedTargets, id: \.self) { lang in
                            Text(getLanguageName(lang)).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
            }
            .navigationTitle("TalkNote 🧠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        vm.displayText = ""
                        vm.resetLearningData()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear { 
            vm.requestPermissions() 
        }
        .sheet(isPresented: $showingCorrectionSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Provide Correction")
                        .font(.headline)
                    
                    Text("Original:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(vm.displayText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("Corrected Text:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $correctionText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Fix Transcription")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingCorrectionSheet = false
                            correctionText = ""
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Apply") {
                            vm.provideCorrection(correctionText)
                            showingCorrectionSheet = false
                            correctionText = ""
                        }
                        .disabled(correctionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .onAppear {
            correctionText = vm.displayText
        }
    }
    
    private func getLanguageName(_ code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English", "es": "Spanish", "fr": "French", "de": "German",
            "hi": "Hindi", "bn": "Bengali", "ta": "Tamil", "te": "Telugu",
            "mr": "Marathi", "gu": "Gujarati", "kn": "Kannada",
            "ar": "Arabic", "ru": "Russian", "ja": "Japanese", "ko": "Korean",
            "zh-Hans": "Chinese"
        ]
        return languageNames[code] ?? code.uppercased()
    }
}

#Preview {
    ContentView()
}
