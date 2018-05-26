import Foundation

struct YTChannelItem: Codable {
    let kind: String
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
//        let defaultLanguage: String
//        let localized: [String: String]
//          "title": string
//          "description": string
//        let country: String
    }
    
    struct ContentDetails: Codable {
        let relatedPlaylists: RelatedPlaylists
        
        struct RelatedPlaylists: Codable {
            let uploads: String
            let watchHistory: String
            let watchLater: String
        }
    }
}
