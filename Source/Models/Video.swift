import Foundation
import CloudKit

class Video {
    
    var id: String
    
    private var result: VideoResult
    var userData: CKRecord?
    
    init(result: VideoResult) {
        self.id = result.videoId
        self.result = result
    }
    
    var title: String { return result.title }
    var thumbnailURL: URL? { return result.thumbnailURL }
    var publishedAt: Date { return Date(timeIntervalSince1970: TimeInterval(result.published)) }
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
