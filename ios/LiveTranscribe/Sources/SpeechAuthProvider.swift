import Foundation

// Token-based auth provider to avoid embedding subscription keys in the app binary.
// Provide a backend endpoint that returns { token, region } for Azure Speech.
struct SpeechToken: Decodable { let token: String; let region: String }

final class SpeechAuthProvider {
    static let shared = SpeechAuthProvider()
    private init() {}

    // Configure your token endpoint (e.g., Azure Function) in Info.plist or compile-time constant
    // Example placeholder:
    private let tokenEndpointKey = "SPEECH_TOKEN_ENDPOINT"

    var isConfigured: Bool { endpointURL != nil }

    private var endpointURL: URL? {
        // Read from Info.plist to keep secrets out of source
        if let url = Bundle.main.object(forInfoDictionaryKey: tokenEndpointKey) as? String { return URL(string: url) }
        return nil
    }

    func fetchToken() async throws -> (String, String) {
        guard let url = endpointURL else { throw NSError(domain: "SpeechAuth", code: 1) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) { throw NSError(domain: "SpeechAuth", code: http.statusCode) }
        let st = try JSONDecoder().decode(SpeechToken.self, from: data)
        return (st.token, st.region)
    }
}
