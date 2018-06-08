import Foundation
import CloudKit

class Video {
    
    var id: String
    
    private var item: YTPlaylistItem
    var userData: CKRecord?
    
    init(item: YTPlaylistItem) {
        self.id = item.snippet.resourceId.videoId
        self.item = item
    }
    
    var title: String { return item.snippet.title }
    var thumbnailURL: URL? { return URL(string: item.snippet.thumbnails.medium.url) }
    var publishedAt: Date { return item.snippet.publishedAt }
    var publishedString: String {
        guard let formattedTimeInterval = Formatter.timeInterval.string(from: item.snippet.publishedAt, to: Date()) else { return "" }
        return formattedTimeInterval + " ago"
    }
    
    var progress: Double {
        get { return userData?["progress"] as? Double ?? 0 }
        set {
            let record = userData ?? CKRecord(recordType: "VideoUserData", recordID: CKRecordID(recordName: id))
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
