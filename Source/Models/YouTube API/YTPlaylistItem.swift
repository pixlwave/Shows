import Foundation

struct YTPlaylistItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
//    let contentDetails: ContentDetails
//    let status: PlaylistItemStatus
    
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
            let kind: String
            let videoId: String
        }
    }
    
    struct ContentDetails: Codable {
        let videoId: String
        let startAt: String
        let endAt: String
        let note: String
        let videoPublishedAt: Date
    }
    
    struct PlaylistItemStatus: Codable {
        let privacyStatus: String
    }
}
