import Foundation

class YTChannelItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    
    struct Snippet: Codable {
        let title: String
        let description: String
        let customUrl: String?
        let publishedAt: Date
        let thumbnails: [String: YTThumbnail]
    }
    
    struct ContentDetails: Codable {
        let relatedPlaylists: RelatedPlaylists
        
        struct RelatedPlaylists: Codable {
            let uploads: String
            let watchHistory: String
            let watchLater: String
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case etag
        case id
        case snippet
        case contentDetails
    }
    
    var name: String { return snippet.title }
    var playlistID: String { return contentDetails.relatedPlaylists.uploads }
    var thumbnailURL: URL? { return URL(string: snippet.thumbnails.first?.value.url ?? "")}
    var videos = [YTPlaylistItem]()
}
