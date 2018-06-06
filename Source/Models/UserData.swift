import CloudKit

class UserData {
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    
    private(set) static var subscriptionIDs: [String] = [String]()
    private static var watchedList: [String] = [String]()
    
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
    
    static func addDefaultSubscriptions() {
        let defaultSubscriptionIDs = ["UCtinbF-Q-fVthA0qrFQTgXQ", "UCzz4CoEgSgWNs9ZAvRMhW2A", "UCPzFLpOblZEaIx2lpym1l1A", "UCUK0HBIBWgM2c4vsPhkYY4w", "UC3fg6pL63upkXCc0T203wVg", "UCknMR7NOY6ZKcVbyzOxQPhw", "UC3KEoMzNz8eYnwBC34RaKCQ", "UC4_m1_0MTTmnWo4tpB0O_7g", "UCbvIIQc5Jo9-jIXnkPe03oA", "UCwC0l6riU37de9Nn_cC7pxw", "UCKuHFYu3smtrl2AwwMOXOlg", "UCcM_6ay33BNpChknCrMCgig", "UCT_EEbG4JlI-ww9j2FGJ99A", "UC3DkFux8Iv-aYnTRWzwaiBA", "UCBJycsmduvYEL83R_U4JriQ", "UCp8mr0kjVyVAmvexLDqB60A"]
        for id in defaultSubscriptionIDs { addSubscription(to: id) }
    }
    
}
