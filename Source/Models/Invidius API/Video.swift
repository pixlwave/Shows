import Foundation
import CloudKit

#warning("Consider whether this should be a struct?")
class Video: Codable {
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
    
    var userData: CKRecord? = nil
    
    enum CodingKeys: String, CodingKey {
        case title
        case videoId
        case author
        case authorId
        case authorUrl
        
        case videoThumbnails
        case description
        case descriptionHtml
        
        case viewCount
        case published
        case publishedText
        case lengthSeconds
        case paid
        case premium
    }
    
    var thumbnailURL: URL? {
        let thumbnail = videoThumbnails.filter { $0.width > 200 }.sorted { $0.width < $1.width }.first
        return URL(string: thumbnail?.url ?? "")
    }
    var publishedAt: Date { return Date(timeIntervalSince1970: TimeInterval(published)) }
    var publishedString: String {
        guard let formattedTimeInterval = Formatter.timeInterval.string(from: publishedAt, to: Date()) else { return "" }
        return formattedTimeInterval + " ago"
    }
    
    var progress: Double {
        get { return userData?["progress"] as? Double ?? 0 }
        set {
            let record = userData ?? CKRecord(recordType: "VideoUserData", recordID: CKRecord.ID(recordName: videoId))
            record["progress"] = newValue as CKRecordValue
            UserData.save(record)
            userData = record
        }
    }
    
    var watched: Bool {
        get { return progress > 0 }
        set { progress = newValue ? 1 : 0 }
    }
}
