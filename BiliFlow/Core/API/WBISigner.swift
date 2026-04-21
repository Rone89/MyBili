import CryptoKit
import Foundation

actor WBISigner {
    static let shared = WBISigner()

    private let client = BiliAPIClient.shared
    private let mixinKeyTable: [Int] = [
        46, 47, 18, 2, 53, 8, 23, 32,
        15, 50, 10, 31, 58, 3, 45, 35,
        27, 43, 5, 49, 33, 9, 42, 19,
        29, 28, 14, 39, 12, 38, 41, 13,
    ]

    private var cachedDay: Int?
    private var cachedMixinKey: String?

    func sign(query: [String: String]) async throws -> [URLQueryItem] {
        let mixinKey = try await loadMixinKey()
        var params = query
        params["wts"] = String(Int(Date().timeIntervalSince1970))

        let sortedPairs = params
            .map { key, value in
                (key, value.replacingOccurrences(of: #"[!'()*]"#, with: "", options: .regularExpression))
            }
            .sorted { $0.0 < $1.0 }

        let queryString = sortedPairs
            .map { key, value in
                "\(key.biliQueryEncoded)=\(value.biliQueryEncoded)"
            }
            .joined(separator: "&")

        let digest = Insecure.MD5.hash(data: Data((queryString + mixinKey).utf8))
        let wRid = digest.map { String(format: "%02x", $0) }.joined()

        params["w_rid"] = wRid

        return params
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    private func loadMixinKey() async throws -> String {
        let today = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        if cachedDay == today, let cachedMixinKey {
            return cachedMixinKey
        }

        let url = URL(string: "https://api.bilibili.com/x/web-interface/nav")!
        let response: NavEnvelope = try await client.get(url)
        guard response.code == 0,
              let imgURL = response.data?.wbiImg?.imgUrl,
              let subURL = response.data?.wbiImg?.subUrl else {
            throw BiliAPIError.server(message: response.message)
        }

        let imgKey = Self.fileNameWithoutExtension(imgURL)
        let subKey = Self.fileNameWithoutExtension(subURL)
        let original = imgKey + subKey
        let mixedCharacters: [Character] = mixinKeyTable.compactMap { index in
            guard index < original.count else {
                return nil
            }
            return original[original.index(original.startIndex, offsetBy: index)]
        }

        let mixinKey = String(mixedCharacters)
        cachedDay = today
        cachedMixinKey = mixinKey
        return mixinKey
    }

    private static func fileNameWithoutExtension(_ rawValue: String) -> String {
        URL(string: rawValue)?
            .deletingPathExtension()
            .lastPathComponent ?? ""
    }
}

private extension String {
    var biliQueryEncoded: String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

private struct NavEnvelope: Decodable {
    let code: Int
    let message: String
    let data: NavData?
}

private struct NavData: Decodable {
    let wbiImg: NavWBIImage?
}

private struct NavWBIImage: Decodable {
    let imgUrl: String?
    let subUrl: String?
}
