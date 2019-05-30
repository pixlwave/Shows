import Foundation
import CloudKit

#warning("Consider whether this should be a struct?")
class Video: Codable {
    let title: String
    let id: String
    let channel: String
    let channelID: String
    let channelURL: String
    
    let thumbnails: [Thumbnail]
    let description: String
    let descriptionHTML: String
    
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
        case id = "videoId"
        case channel = "author"
        case channelID = "authorId"
        case channelURL = "authorUrl"
        
        case thumbnails = "videoThumbnails"
        case description
        case descriptionHTML = "descriptionHtml"
        
        case viewCount
        case published
        case publishedText
        case lengthSeconds
        case paid
        case premium
    }
    
    var thumbnailURL: URL? {
        let thumbnail = thumbnails.filter { $0.width > 200 }.sorted { $0.width < $1.width }.first
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
            let record = userData ?? CKRecord(recordType: "VideoUserData", recordID: CKRecord.ID(recordName: id))
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
