import Foundation

class YTChannelItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    
    enum CodingKeys: String, CodingKey {
        case etag
        case id
        case snippet
        case contentDetails
    }
    
    struct Snippet: Codable {
        let title: String
        let description: String
        let customUrl: String?
        let publishedAt: Date
        let thumbnails: YTThumbnails
    }
    
    struct ContentDetails: Codable {
        let relatedPlaylists: RelatedPlaylists
        
        struct RelatedPlaylists: Codable {
            let uploads: String
            let watchHistory: String
            let watchLater: String
        }
    }
    
    var name: String { return snippet.title }
    var thumbnailURL: URL? { return URL(string: snippet.thumbnails.medium.url)}
    var playlistID: String { return contentDetails.relatedPlaylists.uploads }
    
    var videos = [YTPlaylistItem]()
    var nextVideo: YTPlaylistItem? { return videos.filter { !$0.watched }.first }
}
