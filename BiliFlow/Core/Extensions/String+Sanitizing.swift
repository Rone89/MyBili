import Foundation

extension String {
    var bilibiliNormalizedURL: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return nil
        }

        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }

        if trimmed.hasPrefix("http://") {
            return URL(string: "https://" + trimmed.dropFirst("http://".count))
        }

        return URL(string: trimmed)
    }

    var strippingHTML: String {
        guard let data = data(using: .utf8) else {
            return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }

        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) {
            return attributed.string.replacingOccurrences(of: "\n\n", with: "\n")
        }

        return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

