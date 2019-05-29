import Foundation

struct VideoResult: Codable {
    let title: String
    let videoId: String
    let author: String
    let authorId: String
    let authorUrl: String
    
    let videoThumbnails: [Thumbnail]
    let description: String
    let descriptionHtml: String
    
    let viewCount: Int
    let published: Int
    let publishedText: String
    let lengthSeconds: Int
    let paid: Bool
    let premium: Bool
    
    struct Thumbnail: Codable {
        let quality: String
        let url: String
        let width: Int
        let height: Int
    }
    
    var thumbnailURL: URL? {
        let thumbnail = videoThumbnails.filter { $0.width > 200 }.sorted { $0.width < $1.width }.first
        return URL(string: thumbnail?.url ?? "")
    }
}
