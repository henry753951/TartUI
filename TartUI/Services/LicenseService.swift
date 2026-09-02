import Foundation

actor LicenseService {
    enum ServiceError: LocalizedError {
        case invalidResponse
        case unreadableText

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                String(localized: "GitHub did not return a license document.")
            case .unreadableText:
                String(localized: "The license document could not be read.")
            }
        }
    }

    private let session: URLSession
    private var cache: [LicenseDocument.ID: String] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func text(for document: LicenseDocument, reload: Bool = false) async throws -> String {
        if !reload, let cached = cache[document.id] {
            return cached
        }

        let (data, response) = try await session.data(from: document.rawLicenseURL)
        guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
            throw ServiceError.invalidResponse
        }
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            throw ServiceError.unreadableText
        }
        cache[document.id] = text
        return text
    }
}
