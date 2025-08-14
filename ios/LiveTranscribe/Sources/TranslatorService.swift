import Foundation

struct AzureConfig {
    static var translatorKey: String = "<SET-TRANSLATOR-KEY>"
    static var translatorRegion: String = "<SET-REGION>" // e.g., westeurope, eastus
}

enum TranslatorError: Error { case missingConfig, http(Int), invalid }

final class TranslatorService {
    func translate(text: String, from: String, to: String) async throws -> String {
        guard !AzureConfig.translatorKey.hasPrefix("<SET-") else { return text }
        guard !text.isEmpty else { return text }

        let detectLang = from == "auto" || from.isEmpty
        let fromLang: String
        if detectLang {
            fromLang = try await detectLanguage(of: text) ?? "auto"
        } else {
            fromLang = from
        }
        if fromLang.starts(with: to) || to == "en" && fromLang == "en" { return text }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.cognitive.microsofttranslator.com"
        components.path = "/translate"
        components.queryItems = [
            URLQueryItem(name: "api-version", value: "3.0"),
            URLQueryItem(name: "to", value: to)
        ]

        guard let url = components.url else { throw TranslatorError.invalid }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue(AzureConfig.translatorKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        req.addValue(AzureConfig.translatorRegion, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [["Text": text]])

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) { throw TranslatorError.http(http.statusCode) }

        struct Item: Decodable { struct Tran: Decodable { let text: String }
            let translations: [Tran] }
        let decoded = try JSONDecoder().decode([Item].self, from: data)
        return decoded.first?.translations.first?.text ?? text
    }

    private func detectLanguage(of text: String) async throws -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.cognitive.microsofttranslator.com"
        components.path = "/detect"
        components.queryItems = [ URLQueryItem(name: "api-version", value: "3.0") ]
        guard let url = components.url else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue(AzureConfig.translatorKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        req.addValue(AzureConfig.translatorRegion, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [["Text": text]])
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) { return nil }
        struct Det: Decodable { let language: String? }
        let decoded = try JSONDecoder().decode([Det].self, from: data)
        return decoded.first?.language
    }
}
