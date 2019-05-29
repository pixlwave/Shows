import Foundation

struct ChannelSearchResult: Codable {
    let type: String
    let author: String
    let authorId: String
    let authorUrl: String
    
    let authorThumbnails: [Thumbnail]
    let subCount: Int
    let videoCount: Int
    let description: String
    let descriptionHtml: String
    
    struct Thumbnail: Codable {
        let url: String
        let width: Int
        let height: Int
    }
    
    var name: String { return author }
    var subscribed: Bool { return Invidious.subscriptions.contains { $0.id == authorId } }
    var thumbnailURL: URL? {
        #warning("Pick a better sized thumbnail")
        let thumbnail = authorThumbnails.sorted { $0.width > $1.width }.first
        return URL(string: thumbnail?.url ?? "")
    }
}
