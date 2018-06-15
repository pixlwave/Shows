import UIKit

struct YTThumbnails: Codable {
    let low: Thumbnail
    let medium: Thumbnail
    let high: Thumbnail
    let standard: Thumbnail?
    let maxres: Thumbnail?
    
    enum CodingKeys: String, CodingKey {
        case low = "default"
        case medium
        case high
        case standard
        case maxres
    }
    
    struct Thumbnail: Codable {
        let url: String
        let width: UInt?
        let height: UInt?
        
        enum CodingKeys: String, CodingKey {
            case url
            case width
            case height
        }
        
        var image: UIImage?
    }
}
