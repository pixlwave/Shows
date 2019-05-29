import Foundation
import CloudKit

class Channel {
    
    var id: String
    
    var result: ChannelSearchResult
    var userData: CKRecord?
    
    init(result: ChannelSearchResult) {
        self.id = result.authorId
        self.result = result
    }
    
    var name: String { return result.author }
    var thumbnailURL: URL? { return result.thumbnailURL }
    
    var playlist = [Video]()
    var nextVideo: Video? { return playlist.filter { $0.progress <= 0 }.first }
    
    func reloadPlaylistItems(completionHandler: @escaping () -> Void) {
        guard let url = Invidious.channelVideosURL(for: id) else { completionHandler(); return }
        
        Invidious.queryAPI(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let videoResults = try Invidious.decode([VideoResult].self, from: data)
                    self.playlist = videoResults.map { Video(result: $0) }
                    self.refreshUserData()
                } catch {
                    print("Error \(error)")
                }
            }
            completionHandler()
        }
    }
    
    func refreshUserData() {
        // download latest cloudkit records and attach to videos
        let recordIDs = self.playlist.map { CKRecordID(recordName: $0.id) }
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = { results, error in
            guard let results = results else { print("Fetch Error"); return }
            for video in self.playlist {
                let record = results.first(where: { $0.key.recordName == video.id })?.value ?? CKRecord(recordType: "VideoUserData", recordID: CKRecordID(recordName: video.id))
                video.userData = record
            }
            DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .showUpdated)) }
        }
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
}
