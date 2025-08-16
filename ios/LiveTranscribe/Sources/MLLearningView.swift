import SwiftUI

struct MLLearningView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @State private var showingLanguageCorrection = false
    @State private var showingLearningStats = false
    
    var body: some View {
        VStack(spacing: 16) {
            // ML Status Card
            mlStatusCard
            
            // Learning Progress Card
            learningProgressCard
            
            // Action Buttons
            actionButtons
            
            // Learning Stats (if enabled)
            if showingLearningStats {
                learningStatsCard
            }
        }
        .sheet(isPresented: $showingLanguageCorrection) {
            LanguageCorrectionView(viewModel: viewModel)
        }
    }
    
    // MARK: - ML Status Card
    private var mlStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                Text("AI Language Detection")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(viewModel.mlModelStatus.contains("ready") ? .green : .orange)
                    .frame(width: 8, height: 8)
            }
            
            Text(viewModel.mlModelStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !viewModel.predictionReasoning.isEmpty {
                Text("Reasoning: \(viewModel.predictionReasoning)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Learning Progress Card
    private var learningProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Learning Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.learningProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            ProgressView(value: viewModel.learningProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("The AI learns from your corrections to improve accuracy")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingLanguageCorrection = true }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Wrong Language?")
                }
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: { showingLearningStats.toggle() }) {
                HStack {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: { viewModel.resetLearning() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset")
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Learning Stats Card
    private var learningStatsCard: some View {
        let stats = viewModel.getLearningStats()
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Learning Statistics")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Corrections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.totalCorrections)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Accuracy Improvement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f%%", stats.accuracyImprovement * 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stats.accuracyImprovement > 0 ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Language Patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.activePatterns)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Context Patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.contextualPatterns)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut, value: showingLearningStats)
    }
}

struct LanguageCorrectionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLanguage = "Hindi"
    
    private let indianLanguages = [
        "Hindi", "Bengali", "Telugu", "Marathi", "Tamil",
        "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi",
        "Assamese", "Urdu", "Nepali", "Sindhi", "Sanskrit"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current Detection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Detection")
                        .font(.headline)
                    
                    HStack {
                        Text("Detected as:")
                            .foregroundColor(.secondary)
                        Text(viewModel.detectedLanguage)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Text: \"\(viewModel.transcribedText.prefix(100))...\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Language Correction
                VStack(alignment: .leading, spacing: 12) {
                    Text("Correct Language")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(indianLanguages, id: \.self) { language in
                            Button(action: { selectedLanguage = language }) {
                                HStack {
                                    Image(systemName: selectedLanguage == language ? "checkmark.circle.fill" : "circle")
                                    Text(language)
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                                .foregroundColor(selectedLanguage == language ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedLanguage == language ? Color.blue : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitCorrection) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Submit Correction")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Language Correction")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func submitCorrection() {
        viewModel.correctLanguageDetection(correctLanguage: selectedLanguage)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    MLLearningView(viewModel: TranscriptionViewModel())
}
