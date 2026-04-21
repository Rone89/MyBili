import Foundation

final class BiliAPIClient: @unchecked Sendable {
    static let shared = BiliAPIClient()

    let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": Self.defaultUserAgent,
            "Accept": "application/json, text/plain, */*",
            "Referer": "https://www.bilibili.com",
        ]
        session = URLSession(configuration: configuration)
    }

    static let defaultUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"

    func get<T: Decodable>(
        _ url: URL,
        headers: [String: String] = [:],
        decoder: JSONDecoder = .bili
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BiliAPIError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BiliAPIError.invalidResponse
        }
    }
}

private extension JSONDecoder {
    static let bili: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

