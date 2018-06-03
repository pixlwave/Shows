import CloudKit

class UserData {
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    
    static var watchedList: [String] = [String]()
    
    static func reloadWatchedList() {
        let query = CKQuery(recordType: "YouTubeVideo", predicate: NSPredicate(value: true))
        userDB.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else { print("Error: \(error)"); return }
            let newList = records.map { $0.recordID.recordName }
            watchedList = newList
        }
    }
    
    static func queryWatchedStatus(of videoID: String) -> Bool {
        return watchedList.contains(videoID)
    }
    
    static func mark(_ videoID: String, as watched: Bool) {
        let videoRecordID = CKRecordID(recordName: videoID)
        if watched == true {
            watchedList.append(videoID)
            
            let videoRecord = CKRecord(recordType: "YouTubeVideo", recordID: videoRecordID)
            userDB.save(videoRecord) { video, error in
                if let error = error { print("Error \(error)"); return }
                print("Success: \(videoID) Saved")
            }
        } else {
            if let index = watchedList.index(of: videoID) { watchedList.remove(at: index) }
            
            userDB.delete(withRecordID: videoRecordID) { record, error in
                if let error = error { print("Error \(error)"); return }
                print("Success: \(videoID) Deleted")
            }
        }
    }
    
}
