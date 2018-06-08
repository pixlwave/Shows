import CloudKit

class UserData {
    
    static var subscriptionIDs = [String]()
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    private static let subscriptionsRecordID = CKRecordID(recordName: "Subscriptions")
    private static var subscriptionsRecord = CKRecord(recordType: "Subscriptions", recordID: subscriptionsRecordID)
    
    static func reloadSubscriptions() {
        userDB.fetch(withRecordID: subscriptionsRecordID) { record, error in
            guard let record = record else { print("Subscription Fetch Error"); return }
            subscriptionIDs = record["subscriptionIDs"] as? [String] ?? [String]()
            
            YouTube.loadSubscriptions()
        }
    }
    
    static func addSubscription(to channelID: String) {
        subscriptionIDs.append(channelID)
        subscriptionsRecord["subscriptionIDs"] = subscriptionIDs as CKRecordValue
        
        sync(subscriptionsRecord)
    }
    
    static func sync(_ record: CKRecord) {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        userDB.add(operation)
    }
    
}
