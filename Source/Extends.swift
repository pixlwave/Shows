import UIKit

extension Notification.Name {
    static let subsUpdated = Notification.Name("subsUpdated")
    static let showUpdated = Notification.Name("showUpdated")
    static let videoBeganPlaying = Notification.Name("videoBeganPlaying")
    static let videoPausedWithProgress = Notification.Name("videoPausedWithProgress")
}

extension Formatter {
    
    #warning("This is not working correctly for some dates")
    static let jsonDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
}
