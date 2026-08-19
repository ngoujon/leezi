import Foundation

enum OllamaError: Error, LocalizedError {
    case badResponse
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .badResponse: return "Réponse invalide d'Ollama Cloud."
        case .http(let code, let body): return "Erreur Ollama Cloud (\(code)) : \(body)"
        }
    }
}

/// Client minimal pour l'API Ollama Cloud (https://ollama.com).
struct OllamaClient {
    var apiKey: String = Secrets.ollamaCloudAPIKey
    var model: String = "gpt-oss:20b-cloud"

    func chat(systemPrompt: String, userText: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://ollama.com/api/chat")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OllamaError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw OllamaError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw OllamaError.badResponse
        }
        return content
    }
}
