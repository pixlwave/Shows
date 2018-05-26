import UIKit

extension Notification.Name {
    static let subsUpdated = Notification.Name("subsUpdated")
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

extension UIImage {
    static let imageCache = NSCache<NSString, UIImage>()
    
    static func image(for url: URL) -> UIImage? {
        if let image = imageCache.object(forKey: url.absoluteString as NSString) {
            return image
        } else {
            guard let data = try? Data(contentsOf: url) else { return nil }
            guard let image = UIImage(data: data) else { return nil }
            imageCache.setObject(image, forKey: url.absoluteString as NSString)
            return image
        }
    }
}

extension UIImageView {
    func load(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage.image(for: url)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}
