import Foundation
import CloudKit

#warning("Consider whether this should be a struct?")
class Channel: Codable {
    let type: String
    let author: String
    let authorId: String
    let authorUrl: String
    
    let authorThumbnails: [Thumbnail]
    let subCount: Int
    let videoCount: Int
    let description: String
    let descriptionHtml: String
    
    struct Thumbnail: Codable {
        let url: String
        let width: Int
        let height: Int
    }
    
    var userData: CKRecord?
    
    enum CodingKeys: String, CodingKey {
        case type
        case author
        case authorId
        case authorUrl
        
        case authorThumbnails
        case subCount
        case videoCount
        case description
        case descriptionHtml
    }
    
    var name: String { return author }
    var subscribed: Bool { return Invidious.subscriptions.contains { $0.authorId == authorId } }
    var thumbnailURL: URL? {
        let thumbnail = authorThumbnails.filter { $0.width > 200 }.sorted { $0.width < $1.width }.first
        return URL(string: thumbnail?.url ?? "")
    }
    
    var playlist = [Video]()
    var nextVideo: Video? { return playlist.filter { $0.progress <= 0 }.first }
    
    func reloadPlaylistItems(completionHandler: @escaping () -> Void) {
        guard let url = Invidious.channelVideosURL(for: authorId) else { completionHandler(); return }
        
        Invidious.queryAPI(with: url) { (data, response, error) in
            if let data = data {
                do {
                    self.playlist = try Invidious.decode([Video].self, from: data)
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
        let recordIDs = self.playlist.map { CKRecord.ID(recordName: $0.videoId) }
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = { results, error in
            guard let results = results else { print("Fetch Error"); return }
            for video in self.playlist {
                let record = results.first(where: { $0.key.recordName == video.videoId })?.value ?? CKRecord(recordType: "VideoUserData", recordID: CKRecord.ID(recordName: video.videoId))
                video.userData = record
            }
            DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .showUpdated)) }
        }
        CKContainer.default().privateCloudDatabase.add(operation)
    }
}
