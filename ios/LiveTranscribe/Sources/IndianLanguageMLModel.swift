import Foundation
import CoreML
import NaturalLanguage
import CreateML

@MainActor
class IndianLanguageMLModel: ObservableObject {
    
    // MARK: - Pre-trained Models
    private var languageClassifier: NLModel?
    private var indicBertModel: MLModel?
    private var multilinguaLModel: MLModel?
    
    // MARK: - Model URLs and Configurations
    private let modelConfigs = [
        "indic-bert": ModelConfig(
            name: "indic-bert",
            url: "https://huggingface.co/ai4bharat/indic-bert/resolve/main/pytorch_model.bin",
            description: "AI4Bharat IndicBERT for Indian language understanding",
            languages: ["hi", "bn", "te", "ta", "mr", "gu", "kn", "ml", "or", "pa", "as", "ur"]
        ),
        "multilingual-e5": ModelConfig(
            name: "multilingual-e5",
            url: "https://huggingface.co/intfloat/multilingual-e5-large/resolve/main/pytorch_model.bin",
            description: "Multilingual E5 model with strong Indian language support",
            languages: ["hi", "bn", "te", "ta", "mr", "gu", "kn", "ml", "or", "pa", "as", "ur", "sa", "ne"]
        ),
        "whisper-hindi": ModelConfig(
            name: "whisper-hindi",
            url: "https://huggingface.co/openai/whisper-large-v3/resolve/main/pytorch_model.bin",
            description: "OpenAI Whisper with enhanced Hindi support",
            languages: ["hi", "ur", "bn", "ta", "te", "mr"]
        )
    ]
    
    @Published var modelDownloadProgress: [String: Float] = [:]
    @Published var modelStatus: [String: ModelStatus] = [:]
    @Published var isInitialized = false
    
    init() {
        Task {
            await initializeModels()
        }
    }
    
    // MARK: - Model Initialization
    private func initializeModels() async {
        await updateStatus("Initializing Indian Language ML Models...")
        
        // Initialize built-in NaturalLanguage framework
        await initializeNaturalLanguageModel()
        
        // Download and initialize pre-trained models
        await downloadPretrainedModels()
        
        await MainActor.run {
            self.isInitialized = true
        }
    }
    
    private func initializeNaturalLanguageModel() async {
        do {
            // Use built-in NaturalLanguage framework without custom constraints
            // We'll use NLLanguageRecognizer for basic language detection
            // and enhance it with our ML models
            await updateStatus("Natural Language recognizer initialized")
            
        } catch {
            await updateStatus("Failed to initialize NL model: \(error.localizedDescription)")
        }
    }
    
    private func downloadPretrainedModels() async {
        for (modelName, config) in modelConfigs {
            await downloadModel(name: modelName, config: config)
        }
    }
    
    private func downloadModel(name: String, config: ModelConfig) async {
        await MainActor.run {
            self.modelStatus[name] = .downloading
            self.modelDownloadProgress[name] = 0.0
        }
        
        do {
            // Check if model exists locally first
            let modelPath = getLocalModelPath(for: name)
            if FileManager.default.fileExists(atPath: modelPath.path) {
                await loadLocalModel(name: name, path: modelPath)
                return
            }
            
            // Download model from Hugging Face
            let downloadedPath = try await downloadModelFromURL(config.url, for: name)
            await convertAndLoadModel(name: name, path: downloadedPath)
            
            await MainActor.run {
                self.modelStatus[name] = .ready
                self.modelDownloadProgress[name] = 1.0
            }
            
        } catch {
            await MainActor.run {
                self.modelStatus[name] = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Language Detection with ML
    func detectLanguageWithML(text: String) async -> LanguageDetectionResult {
        var results: [String: Float] = [:]
        
        // Use Natural Language framework
        if let nlResult = await detectWithNaturalLanguage(text: text) {
            results.merge(nlResult) { (_, new) in new }
        }
        
        // Use IndicBERT model
        if let indicResult = await detectWithIndicBERT(text: text) {
            results.merge(indicResult) { (current, new) in (current + new) / 2 }
        }
        
        // Use Multilingual E5 model
        if let e5Result = await detectWithMultilingualE5(text: text) {
            results.merge(e5Result) { (current, new) in (current + new) / 2 }
        }
        
        // Find best match
        let sortedResults = results.sorted { $0.value > $1.value }
        let topLanguage = sortedResults.first?.key ?? "hi"
        let confidence = sortedResults.first?.value ?? 0.5
        
        return LanguageDetectionResult(
            language: topLanguage,
            confidence: confidence,
            allScores: results,
            modelUsed: getActiveModels()
        )
    }
    
    // MARK: - Individual Model Predictions
    private func detectWithNaturalLanguage(text: String) async -> [String: Float]? {
        // Use built-in NLLanguageRecognizer without custom classifier
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        var results: [String: Float] = [:]
        
        for (language, confidence) in hypotheses {
            let langCode = mapNLLanguageToCode(language)
            results[langCode] = Float(confidence)
        }
        
        return results
    }
    
    private func detectWithIndicBERT(text: String) async -> [String: Float]? {
        guard let model = indicBertModel else { return nil }
        
        do {
            // Tokenize text for BERT input
            let tokenizedInput = tokenizeForBERT(text: text)
            let input = try MLDictionaryFeatureProvider(dictionary: tokenizedInput)
            let prediction = try model.prediction(from: input)
            
            return extractLanguageScores(from: prediction)
            
        } catch {
            await updateStatus("IndicBERT prediction failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func detectWithMultilingualE5(text: String) async -> [String: Float]? {
        guard let model = multilinguaLModel else { return nil }
        
        do {
            let embeddings = try await generateEmbeddings(text: text, model: model)
            return classifyFromEmbeddings(embeddings)
            
        } catch {
            await updateStatus("Multilingual E5 prediction failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Text Processing Utilities
    private func tokenizeForBERT(text: String) -> [String: Any] {
        // Simplified BERT tokenization for Indian languages
        let tokens = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(512) // BERT max sequence length
        
        let inputIds = tokens.map { tokenToId($0) }
        let attentionMask = Array(repeating: 1, count: inputIds.count)
        
        return [
            "input_ids": inputIds,
            "attention_mask": attentionMask,
            "token_type_ids": Array(repeating: 0, count: inputIds.count)
        ]
    }
    
    private func tokenToId(_ token: String) -> Int {
        // Simplified token-to-ID mapping for Indian languages
        // In production, use proper tokenizer like SentencePiece
        return abs(token.hashValue) % 30000
    }
    
    private func generateEmbeddings(text: String, model: MLModel) async throws -> [Float] {
        let input = try MLDictionaryFeatureProvider(dictionary: ["text": text])
        let prediction = try model.prediction(from: input)
        
        if let embeddings = prediction.featureValue(for: "embeddings")?.multiArrayValue {
            return embeddings.dataPointer.assumingMemoryBound(to: Float.self)
                .withMemoryRebound(to: Float.self, capacity: embeddings.count) { pointer in
                    Array(UnsafeBufferPointer(start: pointer, count: embeddings.count))
                }
        }
        
        return []
    }
    
    private func classifyFromEmbeddings(_ embeddings: [Float]) -> [String: Float] {
        // Use cosine similarity with pre-computed language embeddings
        let languageEmbeddings = getLanguageEmbeddings()
        var scores: [String: Float] = [:]
        
        for (language, langEmbedding) in languageEmbeddings {
            let similarity = cosineSimilarity(embeddings, langEmbedding)
            scores[language] = similarity
        }
        
        return scores
    }
    
    // MARK: - Helper Functions
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    private func getLanguageEmbeddings() -> [String: [Float]] {
        // Pre-computed embeddings for Indian languages
        // In production, these would be loaded from trained models
        return [
            "hi": Array(repeating: 0.1, count: 768), // Hindi
            "bn": Array(repeating: 0.2, count: 768), // Bengali
            "te": Array(repeating: 0.3, count: 768), // Telugu
            "ta": Array(repeating: 0.4, count: 768), // Tamil
            "mr": Array(repeating: 0.5, count: 768), // Marathi
            "gu": Array(repeating: 0.6, count: 768), // Gujarati
            "kn": Array(repeating: 0.7, count: 768), // Kannada
            "ml": Array(repeating: 0.8, count: 768), // Malayalam
            "ur": Array(repeating: 0.9, count: 768)  // Urdu
        ]
    }
    
    private func mapNLLanguageToCode(_ language: NLLanguage) -> String {
        switch language {
        case .hindi: return "hi"
        case .urdu: return "ur"
        case .bengali: return "bn"
        case .tamil: return "ta"
        case .telugu: return "te"
        case .gujarati: return "gu"
        case .kannada: return "kn"
        case .malayalam: return "ml"
        case .marathi: return "mr"
        case .punjabi: return "pa"
        case .oriya: return "or"
        case .assamese: return "as"
        case .nepali: return "ne"
        default: return "en"
        }
    }
    
    private func getActiveModels() -> [String] {
        return modelStatus.compactMap { key, status in
            if case .ready = status { return key }
            return nil
        }
    }
    
    private func updateStatus(_ message: String) async {
        print("IndianLanguageML: \(message)")
    }
    
    // MARK: - Model Management
    private func getLocalModelPath(for modelName: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(modelName).mlmodelc")
    }
    
    private func downloadModelFromURL(_ url: String, for modelName: String) async throws -> URL {
        // Simplified download - in production use proper HTTP client with progress tracking
        guard let modelURL = URL(string: url) else {
            throw MLModelError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: modelURL)
        let localPath = getLocalModelPath(for: modelName)
        
        try data.write(to: localPath)
        return localPath
    }
    
    private func loadLocalModel(name: String, path: URL) async {
        do {
            let model = try MLModel(contentsOf: path)
            
            switch name {
            case "indic-bert":
                indicBertModel = model
            case "multilingual-e5":
                multilinguaLModel = model
            default:
                break
            }
            
            await MainActor.run {
                self.modelStatus[name] = .ready
            }
            
        } catch {
            await MainActor.run {
                self.modelStatus[name] = .error(error.localizedDescription)
            }
        }
    }
    
    private func convertAndLoadModel(name: String, path: URL) async {
        // Convert downloaded PyTorch models to CoreML format
        // This is a complex process - simplified here
        await loadLocalModel(name: name, path: path)
    }
    
    private func createCustomLanguageModel() throws -> MLModel? {
        // Simplified approach - return nil for now
        // In production, this would load a pre-trained language classification model
        return nil
    }
    
    private func extractLanguageScores(from prediction: MLFeatureProvider) -> [String: Float] {
        // Extract language classification scores from model output
        var scores: [String: Float] = [:]
        
        let supportedLanguages = ["hi", "bn", "te", "ta", "mr", "gu", "kn", "ml", "ur"]
        
        for (index, language) in supportedLanguages.enumerated() {
            if let outputArray = prediction.featureValue(for: "classLabel")?.multiArrayValue {
                let score = outputArray[index].floatValue
                scores[language] = score
            }
        }
        
        return scores
    }
}

// MARK: - Supporting Types

struct ModelConfig {
    let name: String
    let url: String
    let description: String
    let languages: [String]
}

enum ModelStatus {
    case notDownloaded
    case downloading
    case ready
    case error(String)
}

struct LanguageDetectionResult {
    let language: String
    let confidence: Float
    let allScores: [String: Float]
    let modelUsed: [String]
}

enum MLModelError: Error {
    case invalidURL
    case modelNotFound
    case downloadFailed
    case conversionFailed
}

extension NLLanguage {
    static let bengali = NLLanguage("bn")
    static let telugu = NLLanguage("te")
    static let gujarati = NLLanguage("gu")
    static let kannada = NLLanguage("kn")
    static let malayalam = NLLanguage("ml")
    static let marathi = NLLanguage("mr")
    static let punjabi = NLLanguage("pa")
    static let oriya = NLLanguage("or")
    static let assamese = NLLanguage("as")
    static let nepali = NLLanguage("ne")
}
