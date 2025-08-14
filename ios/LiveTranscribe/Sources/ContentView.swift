import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TranscriptionViewModel()

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
        .onAppear { vm.requestPermissions() }
    }
}

#Preview {
    ContentView()
}
