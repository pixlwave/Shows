import CloudKit

class UserData {
    
    static var subscriptionIDs = Set<String>()
    
    private static var userDB = CKContainer.default().privateCloudDatabase
    private static let subscriptionsRecordID = CKRecord.ID(recordName: "Subscriptions")
    private static var subscriptionsRecord = CKRecord(recordType: "Subscriptions", recordID: subscriptionsRecordID)
    private static let notificationSubscription = CKQuerySubscription(recordType: "Subscriptions",
                                                                      predicate: NSPredicate(value: true),
                                                                      options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
    private static let notificationInfo = CKSubscription.NotificationInfo()
    
    static func listenForChanges() {
        notificationInfo.shouldSendContentAvailable = true
        notificationSubscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [notificationSubscription], subscriptionIDsToDelete: nil)
        operation.completionBlock = {
            print("Complete")
        }
        
        userDB.add(operation)
    }
    
    static func reloadSubscriptions() {
        Task {
            do {
                let record = try await userDB.record(for: subscriptionsRecordID)
                subscriptionIDs = Set<String>(record["subscriptionIDs"] as? [String] ?? [])
                subscriptionsRecord = record
                try await YouTube.shared.loadSubscriptions()
            } catch {
                print("Subscription Fetch Error")
                print(error)
            }
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
