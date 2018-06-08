import CloudKit

class UserData {
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    
    private(set) static var subscriptionIDs: [String] = [String]()
    private static var watchProgressCache: [String: Double] = [String: Double]()
    
    static func listenForChanges() {
        saveSubcription(of: "YouTubeVideo", to: userDB)
        saveSubcription(of: "YouTubeChannel", to: userDB)
    }
    
    static func saveSubcription(of recordType: String, to database: CKDatabase) {
        let subscription = CKQuerySubscription(recordType: recordType, predicate: NSPredicate(value: true), options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        subscription.notificationInfo?.title = recordType
        database.save(subscription) { subscription, error in
            if let error = error { print("Error \(error)"); return }
            print("Success: registered \(recordType) subscription")
        }
    }
    
    static func reloadSubscriptions() {
        let query = CKQuery(recordType: "YouTubeChannel", predicate: NSPredicate(value: true))
        userDB.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else { print("Error: \(error)"); return }
            let newSubscriptionIDs = records.map { $0.recordID.recordName }
            subscriptionIDs = newSubscriptionIDs
            YouTube.loadSubscriptions()
        }
    }
    
    static func addSubscription(to channelID: String) {
        subscriptionIDs.append(channelID)
        
        let channelRecord = CKRecord(recordType: "YouTubeChannel", recordID: CKRecordID(recordName: channelID))
        userDB.save(channelRecord) { video, error in
            if let error = error { print("Error \(error)"); return }
            print("Success: \(channelID) Saved")
        }
    }
    
    static func reloadWatchedList() {
        let query = CKQuery(recordType: "YouTubeVideo", predicate: NSPredicate(value: true))
        userDB.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else { print("Error: \(error)"); return }
            var newList = [String: Double]()
            for record in records { newList[record.recordID.recordName] = record["progress"] as? Double ?? 0 }
            watchProgressCache = newList
        }
    }
    
    static func queryProgress(of videoID: String) -> Double {
        return watchProgressCache[videoID] ?? 0
    }
    
    static func set(_ progress: Double, for videoID: String) {
        let videoRecordID = CKRecordID(recordName: videoID)
        
        if progress > 0 {
            watchProgressCache[videoID] = progress
    
            userDB.fetch(withRecordID: videoRecordID) { record, error in
                if let error = error { print("Error \(error)"); return }
                
            }
            
            let videoRecord = CKRecord(recordType: "YouTubeVideo", recordID: videoRecordID)
            videoRecord["progress"] = progress as CKRecordValue
            userDB.save(videoRecord) { video, error in
                if let error = error { print("Error \(error)"); return }
                print("Success: \(videoID) Saved")
            }
        } else {
            if watchProgressCache.contains(where: { $0.key == videoID }) { watchProgressCache.removeValue(forKey: videoID) }
            
            userDB.delete(withRecordID: videoRecordID) { record, error in
                if let error = error { print("Error \(error)"); return }
                print("Success: \(videoID) Deleted")
            }
        }
    }
    
    static func addDefaultSubscriptions() {
        let defaultSubscriptionIDs = ["UCtinbF-Q-fVthA0qrFQTgXQ", "UCzz4CoEgSgWNs9ZAvRMhW2A", "UCPzFLpOblZEaIx2lpym1l1A", "UCUK0HBIBWgM2c4vsPhkYY4w", "UC3fg6pL63upkXCc0T203wVg", "UCknMR7NOY6ZKcVbyzOxQPhw", "UC3KEoMzNz8eYnwBC34RaKCQ", "UC4_m1_0MTTmnWo4tpB0O_7g", "UCbvIIQc5Jo9-jIXnkPe03oA", "UCwC0l6riU37de9Nn_cC7pxw", "UCKuHFYu3smtrl2AwwMOXOlg", "UCcM_6ay33BNpChknCrMCgig", "UCT_EEbG4JlI-ww9j2FGJ99A", "UC3DkFux8Iv-aYnTRWzwaiBA", "UCBJycsmduvYEL83R_U4JriQ", "UCp8mr0kjVyVAmvexLDqB60A"]
        for id in defaultSubscriptionIDs { addSubscription(to: id) }
    }
    
}
