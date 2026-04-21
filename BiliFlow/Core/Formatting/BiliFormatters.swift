import Foundation

enum BiliFormatters {
    static func countText(_ count: Int) -> String {
        switch count {
        case 1_000_000_000...:
            return String(format: "%.1fB", Double(count) / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", Double(count) / 1_000)
        default:
            return "\(count)"
        }
    }

    static func durationText(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%d:%02d", minutes, remainder)
    }

    static func publishedText(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
