import Foundation
import CloudKit

class Video {
    
    var id: String
    
    private var item: YTPlaylistItem
    var record: CKRecord?
    
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
        get { return record?["progress"] as? Double ?? 0 }
        set {
            let updatedRecord = record ?? CKRecord(recordType: "Video", recordID: CKRecordID(recordName: id))
            updatedRecord["progress"] = newValue as CKRecordValue
            UserData.sync(updatedRecord)
            record = updatedRecord
        }
    }
    
    var watched: Bool {
        get { return progress > 0 }
        set { progress = newValue ? 1 : 0 }
    }
}
