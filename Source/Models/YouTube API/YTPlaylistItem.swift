import Foundation

struct YTPlaylistItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
    
    struct Snippet: Codable {
        let publishedAt: Date
        let channelId: String
        let title: String
        let description: String
        let thumbnails: [String: YTThumbnail]
        let channelTitle: String
        let playlistId: String
        let position: UInt
        let resourceId: ResourceID
        
        struct ResourceID: Codable {
            let videoId: String
        }
    }
    
    var thumbnailURL: URL? { return URL(string: snippet.thumbnails.first?.value.url ?? "") }
}
