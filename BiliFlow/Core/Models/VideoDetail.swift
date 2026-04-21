import Foundation

struct VideoDetail: Hashable, Sendable {
    let aid: Int
    let bvid: String
    let cid: Int
    let title: String
    let descriptionText: String
    let coverURL: URL?
    let ownerName: String
    let ownerMid: Int
    let ownerFaceURL: URL?
    let areaName: String?
    let durationText: String
    let publishedAt: Date?
    let viewText: String
    let danmakuText: String
    let likeText: String
    let coinText: String
    let favoriteText: String
    let shareText: String

    var webURL: URL? {
        URL(string: "https://www.bilibili.com/video/\(bvid)")
    }
}

