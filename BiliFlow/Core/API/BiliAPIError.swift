import Foundation

enum BiliAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(message: String)
    case missingData
    case unsupportedIdentifier

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to build the request URL."
        case .invalidResponse:
            return "The server returned data that could not be parsed."
        case let .server(message):
            return message.isEmpty ? "The server returned an error." : message
        case .missingData:
            return "The request succeeded but no usable data was returned."
        case .unsupportedIdentifier:
            return "The selected video is missing both aid and bvid."
        }
    }
}
