import Foundation

// Replace with your Azure Translator resource values
struct Secrets {
    static var translatorKey: String { AzureConfig.translatorKey }
    static var translatorRegion: String { AzureConfig.translatorRegion }
}
