import Foundation
import CloudKit

class Channel {
    
    var id: String
    
    private var item: YTChannelItem
    var userData: CKRecord?
    
    init(item: YTChannelItem) {
        self.id = item.id
        self.item = item
    }
    
    var name: String { return item.snippet.title }
    var thumbnailURL: URL? { return URL(string: item.snippet.thumbnails.medium.url)}
    var playlistID: String { return item.contentDetails.relatedPlaylists.uploads }
    
    var playlist = [Video]()
    var nextVideo: Video? { return playlist.filter { $0.progress <= 0 }.first }
    
    func reloadPlaylistItems(completionHandler: @escaping () -> Void) {
        guard let url = YouTube.playlistItemListURL(for: playlistID) else { completionHandler(); return }
        
        YouTube.queryAPI(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let playlistItemList = try YouTube.decode(YTPlaylistItemListResponse.self, from: data)
                    self.playlist = playlistItemList.items.map { Video(item: $0) }
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
