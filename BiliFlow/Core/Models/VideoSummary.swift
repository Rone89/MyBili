import Foundation

struct VideoSummary: Identifiable, Hashable, Sendable {
    let aid: Int?
    let bvid: String?
    let cid: Int?
    let title: String
    let coverURL: URL?
    let authorName: String
    let authorMid: Int?
    let areaName: String?
    let durationText: String
    let viewText: String
    let danmakuText: String

    var id: String {
        if let bvid {
            return bvid
        }
        if let aid {
            return "av\(aid)"
        }
        return UUID().uuidString
    }

    var identifier: VideoIdentifier {
        VideoIdentifier(aid: aid, bvid: bvid)
    }

    var webURL: URL? {
        if let bvid {
            return URL(string: "https://www.bilibili.com/video/\(bvid)")
        }
        if let aid {
            return URL(string: "https://www.bilibili.com/video/av\(aid)")
        }
        return nil
    }
}

