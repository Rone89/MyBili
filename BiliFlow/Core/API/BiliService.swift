import Foundation

struct BiliService: Sendable {
    static let shared = BiliService()

    private let client = BiliAPIClient.shared
    private let signer = WBISigner.shared

    private enum Host: String {
        case api = "https://api.bilibili.com"
        case app = "https://app.bilibili.com"
        case search = "https://s.search.bilibili.com"
    }

    func fetchRecommendedVideos(refreshIndex: Int = 0) async throws -> [VideoSummary] {
        let queryItems = [
            URLQueryItem(name: "build", value: "2001100"),
            URLQueryItem(name: "c_locale", value: "zh_CN"),
            URLQueryItem(name: "channel", value: "master"),
            URLQueryItem(name: "column", value: "4"),
            URLQueryItem(name: "device", value: "pad"),
            URLQueryItem(name: "device_name", value: "android"),
            URLQueryItem(name: "device_type", value: "0"),
            URLQueryItem(name: "disable_rcmd", value: "0"),
            URLQueryItem(name: "flush", value: "5"),
            URLQueryItem(name: "fnval", value: "976"),
            URLQueryItem(name: "fnver", value: "0"),
            URLQueryItem(name: "force_host", value: "2"),
            URLQueryItem(name: "fourk", value: "1"),
            URLQueryItem(name: "guidance", value: "0"),
            URLQueryItem(name: "https_url_req", value: "0"),
            URLQueryItem(name: "idx", value: "\(refreshIndex)"),
            URLQueryItem(name: "mobi_app", value: "android_hd"),
            URLQueryItem(name: "network", value: "wifi"),
            URLQueryItem(name: "platform", value: "android"),
            URLQueryItem(name: "player_net", value: "1"),
            URLQueryItem(name: "pull", value: refreshIndex == 0 ? "true" : "false"),
            URLQueryItem(name: "qn", value: "32"),
            URLQueryItem(name: "recsys_mode", value: "0"),
            URLQueryItem(name: "s_locale", value: "zh_CN"),
            URLQueryItem(name: "voice_balance", value: "0"),
        ]

        let url = try buildURL(host: .app, path: "/x/v2/feed/index", queryItems: queryItems)
        let response: AppFeedEnvelope = try await client.get(
            url,
            headers: [
                "app-key": "android_hd",
                "session_id": "11111111",
                "env": "prod",
                "bili-http-engine": "cronet",
                "fp_local": String(repeating: "1", count: 64),
                "fp_remote": String(repeating: "1", count: 64),
            ]
        )

        guard response.code == 0, let items = response.data?.items else {
            throw BiliAPIError.server(message: response.message)
        }

        return items.compactMap { item in
            guard item.goto == "av" || item.cardGoto == "av" else {
                return nil
            }

            let title = (item.title ?? "").strippingHTML
            guard !title.isEmpty else {
                return nil
            }

            return VideoSummary(
                aid: item.args?.aid ?? Int(item.param ?? ""),
                bvid: nil,
                cid: item.playerArgs?.cid,
                title: title,
                coverURL: item.cover?.bilibiliNormalizedURL,
                authorName: item.args?.upName ?? item.descButton?.text ?? "Unknown creator",
                authorMid: item.args?.upID,
                areaName: item.args?.tname,
                durationText: item.coverRightText ?? "--:--",
                viewText: item.coverLeftText1 ?? "--",
                danmakuText: item.coverLeftText2 ?? "--",
            )
        }
    }

    func fetchHotVideos(page: Int, pageSize: Int = 20) async throws -> [VideoSummary] {
        let url = try buildURL(
            host: .api,
            path: "/x/web-interface/popular",
            queryItems: [
                URLQueryItem(name: "pn", value: "\(page)"),
                URLQueryItem(name: "ps", value: "\(pageSize)"),
            ]
        )

        let response: PopularEnvelope = try await client.get(url)
        guard response.code == 0, let items = response.data?.list else {
            throw BiliAPIError.server(message: response.message)
        }

        return items.map { item in
            VideoSummary(
                aid: item.aid,
                bvid: item.bvid,
                cid: item.cid,
                title: item.title.strippingHTML,
                coverURL: item.pic.bilibiliNormalizedURL,
                authorName: item.owner.name,
                authorMid: item.owner.mid,
                areaName: item.tname,
                durationText: BiliFormatters.durationText(seconds: item.duration),
                viewText: BiliFormatters.countText(item.stat.view),
                danmakuText: BiliFormatters.countText(item.stat.danmaku),
            )
        }
    }

    func fetchSearchDiscovery() async throws -> SearchDiscovery {
        async let defaultKeywordTask: SearchDefaultEnvelope = client.get(
            try buildURL(host: .api, path: "/x/web-interface/wbi/search/default")
        )
        async let hotWordsTask: SearchHotEnvelope = client.get(
            try buildURL(host: .search, path: "/main/hotword")
        )

        let (defaultKeywordResponse, hotWordsResponse) = try await (defaultKeywordTask, hotWordsTask)

        let defaultKeyword = defaultKeywordResponse.data?.showName
        let hotKeywords = hotWordsResponse.list.prefix(20).map {
            SearchHotKeyword(id: $0.id, text: $0.keyword)
        }

        return SearchDiscovery(defaultKeyword: defaultKeyword, hotKeywords: Array(hotKeywords))
    }

    func fetchSearchSuggestions(term: String) async throws -> [SearchSuggestion] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        let url = try buildURL(
            host: .search,
            path: "/main/suggest",
            queryItems: [
                URLQueryItem(name: "term", value: trimmed),
                URLQueryItem(name: "main_ver", value: "v1"),
                URLQueryItem(name: "highlight", value: trimmed),
            ]
        )

        let response: SearchSuggestEnvelope = try await client.get(url)
        guard response.code == 0 else {
            throw BiliAPIError.server(message: "Failed to load search suggestions.")
        }

        return response.result?.tag?.prefix(8).compactMap {
            let value = ($0.value ?? $0.term ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else {
                return nil
            }
            return SearchSuggestion(text: value)
        } ?? []
    }

    func searchVideos(keyword: String, page: Int) async throws -> SearchResultPage {
        let queryItems = try await signer.sign(query: [
            "search_type": "video",
            "keyword": keyword,
            "page": "\(page)",
            "page_size": "20",
            "platform": "pc",
            "web_location": "1430654",
        ])

        let url = try buildURL(host: .api, path: "/x/web-interface/wbi/search/type", queryItems: queryItems)
        let response: SearchVideoEnvelope = try await client.get(
            url,
            headers: [
                "Origin": "https://search.bilibili.com",
                "Referer": "https://search.bilibili.com/video?keyword=\(keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword)",
            ]
        )

        guard response.code == 0, let data = response.data else {
            throw BiliAPIError.server(message: response.message)
        }

        let items = (data.result ?? [])
            .filter { $0.type == "video" }
            .map { item in
                VideoSummary(
                    aid: item.aid,
                    bvid: item.bvid?.isEmpty == false ? item.bvid : nil,
                    cid: nil,
                    title: (item.title ?? "").strippingHTML,
                    coverURL: item.pic?.bilibiliNormalizedURL,
                    authorName: (item.author ?? "").strippingHTML,
                    authorMid: item.mid,
                    areaName: item.typename,
                    durationText: item.duration ?? "--:--",
                    viewText: BiliFormatters.countText(item.play ?? 0),
                    danmakuText: BiliFormatters.countText(item.videoReview ?? item.danmaku ?? 0),
                )
            }

        return SearchResultPage(
            items: items,
            currentPage: data.page ?? page,
            totalPages: max(data.numPages ?? page, page)
        )
    }

    func fetchVideoDetail(identifier: VideoIdentifier) async throws -> VideoDetail {
        var queryItems: [URLQueryItem] = []

        if let bvid = identifier.bvid {
            queryItems.append(URLQueryItem(name: "bvid", value: bvid))
        } else if let aid = identifier.aid {
            queryItems.append(URLQueryItem(name: "aid", value: "\(aid)"))
        } else {
            throw BiliAPIError.unsupportedIdentifier
        }

        let url = try buildURL(host: .api, path: "/x/web-interface/view", queryItems: queryItems)
        let response: VideoDetailEnvelope = try await client.get(url)

        guard response.code == 0, let data = response.data else {
            throw BiliAPIError.server(message: response.message)
        }

        return VideoDetail(
            aid: data.aid,
            bvid: data.bvid,
            cid: data.cid,
            title: data.title.strippingHTML,
            descriptionText: data.desc?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? data.desc! : "No description is available for this video yet.",
            coverURL: data.pic.bilibiliNormalizedURL,
            ownerName: data.owner.name,
            ownerMid: data.owner.mid,
            ownerFaceURL: data.owner.face?.bilibiliNormalizedURL,
            areaName: data.tname,
            durationText: BiliFormatters.durationText(seconds: data.duration),
            publishedAt: data.pubdate.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            viewText: BiliFormatters.countText(data.stat.view),
            danmakuText: BiliFormatters.countText(data.stat.danmaku),
            likeText: BiliFormatters.countText(data.stat.like),
            coinText: BiliFormatters.countText(data.stat.coin),
            favoriteText: BiliFormatters.countText(data.stat.favorite),
            shareText: BiliFormatters.countText(data.stat.share),
        )
    }

    func fetchRelatedVideos(bvid: String) async throws -> [VideoSummary] {
        let url = try buildURL(
            host: .api,
            path: "/x/web-interface/archive/related",
            queryItems: [URLQueryItem(name: "bvid", value: bvid)]
        )

        let response: RelatedEnvelope = try await client.get(url)
        guard response.code == 0 else {
            throw BiliAPIError.server(message: response.message)
        }

        return (response.data ?? []).map { item in
            VideoSummary(
                aid: item.aid,
                bvid: item.bvid,
                cid: item.cid,
                title: item.title.strippingHTML,
                coverURL: item.pic.bilibiliNormalizedURL,
                authorName: item.owner.name,
                authorMid: item.owner.mid,
                areaName: item.tname,
                durationText: BiliFormatters.durationText(seconds: item.duration),
                viewText: BiliFormatters.countText(item.stat.view),
                danmakuText: BiliFormatters.countText(item.stat.danmaku),
            )
        }
    }

    private func buildURL(host: Host, path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: host.rawValue) else {
            throw BiliAPIError.invalidURL
        }

        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw BiliAPIError.invalidURL
        }

        return url
    }
}

private struct AppFeedEnvelope: Decodable {
    let code: Int
    let message: String
    let data: AppFeedData?
}

private struct AppFeedData: Decodable {
    let items: [AppFeedItem]
}

private struct AppFeedItem: Decodable {
    let cardGoto: String?
    let goto: String?
    let param: String?
    let cover: String?
    let title: String?
    let args: AppFeedArgs?
    let playerArgs: AppFeedPlayerArgs?
    let coverLeftText1: String?
    let coverLeftText2: String?
    let coverRightText: String?
    let descButton: AppFeedDescButton?
}

private struct AppFeedArgs: Decodable {
    let upID: Int?
    let upName: String?
    let tname: String?
    let aid: Int?
}

private struct AppFeedPlayerArgs: Decodable {
    let aid: Int?
    let cid: Int?
}

private struct AppFeedDescButton: Decodable {
    let text: String?
}

private struct PopularEnvelope: Decodable {
    let code: Int
    let message: String
    let data: PopularData?
}

private struct PopularData: Decodable {
    let list: [PopularVideo]
}

private struct PopularVideo: Decodable {
    let aid: Int
    let bvid: String
    let cid: Int
    let title: String
    let pic: String
    let tname: String?
    let duration: Int
    let owner: VideoOwner
    let stat: VideoStat
}

private struct VideoOwner: Decodable {
    let mid: Int
    let name: String
    let face: String?
}

private struct VideoStat: Decodable {
    let view: Int
    let danmaku: Int
    let like: Int
    let coin: Int
    let favorite: Int
    let share: Int
}

private struct SearchDefaultEnvelope: Decodable {
    let code: Int
    let message: String
    let data: SearchDefaultData?
}

private struct SearchDefaultData: Decodable {
    let showName: String?
}

private struct SearchHotEnvelope: Decodable {
    let code: Int
    let list: [SearchHotItem]
}

private struct SearchHotItem: Decodable {
    let id: Int
    let keyword: String
}

private struct SearchSuggestEnvelope: Decodable {
    let code: Int
    let result: SearchSuggestResult?
}

private struct SearchSuggestResult: Decodable {
    let tag: [SearchSuggestTag]?
}

private struct SearchSuggestTag: Decodable {
    let value: String?
    let term: String?
}

private struct SearchVideoEnvelope: Decodable {
    let code: Int
    let message: String
    let data: SearchVideoData?
}

private struct SearchVideoData: Decodable {
    let page: Int?
    let numPages: Int?
    let result: [SearchVideoItem]?
}

private struct SearchVideoItem: Decodable {
    let type: String?
    let aid: Int?
    let bvid: String?
    let author: String?
    let mid: Int?
    let typename: String?
    let title: String?
    let pic: String?
    let play: Int?
    let videoReview: Int?
    let danmaku: Int?
    let duration: String?
}

private struct VideoDetailEnvelope: Decodable {
    let code: Int
    let message: String
    let data: VideoDetailData?
}

private struct VideoDetailData: Decodable {
    let aid: Int
    let bvid: String
    let cid: Int
    let title: String
    let desc: String?
    let pic: String
    let tname: String?
    let duration: Int
    let pubdate: Int?
    let owner: VideoOwner
    let stat: VideoStat
}

private struct RelatedEnvelope: Decodable {
    let code: Int
    let message: String
    let data: [RelatedVideo]?
}

private struct RelatedVideo: Decodable {
    let aid: Int
    let bvid: String
    let cid: Int?
    let title: String
    let pic: String
    let tname: String?
    let duration: Int
    let owner: VideoOwner
    let stat: VideoStat
}
