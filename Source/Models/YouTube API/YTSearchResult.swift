import Foundation

struct YTSearchResult: Codable {
    let etag: String
    let id: ID
    let snippet: Snippet

    struct ID: Codable {
        let kind: String
        let videoId: String?
        let channelId: String?
        let playlistId: String?
    }
    struct Snippet: Codable {
        let publishedAt: Date
        let channelId: String
        let title: String
        let description: String
        let thumbnails: YTThumbnails
        let channelTitle: String
    }
    
    var name: String { return snippet.channelTitle }
    var thumbnailURL: URL? { return URL(string: snippet.thumbnails.medium.url) }
    var subscribed: Bool { return YouTube.subscriptions.contains { $0.id == snippet.channelId } }
}
