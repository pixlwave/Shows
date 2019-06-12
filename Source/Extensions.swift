import UIKit

extension Notification.Name {
    static let subsUpdated = Notification.Name("subsUpdated")
    static let showUpdated = Notification.Name("showUpdated")
    static let videoBeganPlaying = Notification.Name("videoBeganPlaying")
    static let videoPausedWithProgress = Notification.Name("videoPausedWithProgress")
}

extension Formatter {
    
    static let jsonDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let timeInterval: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
    
}
