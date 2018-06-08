import Foundation

class YTPlaylistItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
    
    enum CodingKeys: String, CodingKey {
        case etag
        case id
        case snippet
    }
    
    struct Snippet: Codable {
        let publishedAt: Date
        let channelId: String
        let title: String
        let description: String
        let thumbnails: YTThumbnails
        let channelTitle: String
        let playlistId: String
        let position: UInt
        let resourceId: ResourceID
        
        struct ResourceID: Codable {
            let videoId: String
        }
    }
}
