import CloudKit

class UserData {
    
    static var subscriptionIDs = Set<String>()
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    private static let subscriptionsRecordID = CKRecordID(recordName: "Subscriptions")
    private static var subscriptionsRecord = CKRecord(recordType: "Subscriptions", recordID: subscriptionsRecordID)
    
    static func reloadSubscriptions() {
        userDB.fetch(withRecordID: subscriptionsRecordID) { record, error in
            guard let record = record else { print("Subscription Fetch Error"); return }
            subscriptionIDs = Set<String>(record["subscriptionIDs"] as? [String] ?? [String]())
            subscriptionsRecord = record
            
            YouTube.loadSubscriptions()
        }
    }
    
    static func saveSubscription(to channelID: String) {
        subscriptionIDs.insert(channelID)
        subscriptionsRecord["subscriptionIDs"] = Array(subscriptionIDs) as CKRecordValue
        
        save(subscriptionsRecord)
    }
    
    static func deleteSubscription(to channelID: String) {
        subscriptionIDs.remove(channelID)
        subscriptionsRecord["subscriptionIDs"] = Array(subscriptionIDs) as CKRecordValue
        
        save(subscriptionsRecord)
    }
    
    static func save(_ record: CKRecord) {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        userDB.add(operation)
    }
    
}
