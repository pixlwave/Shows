import Foundation
import CloudKit

class YTChannelItem: Codable {
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    
    enum CodingKeys: String, CodingKey {
        case etag
        case id
        case snippet
        case contentDetails
    }
    
    struct Snippet: Codable {
        let title: String
        let description: String
        let customUrl: String?
        let publishedAt: Date
        let thumbnails: YTThumbnails
    }
    
    struct ContentDetails: Codable {
        let relatedPlaylists: RelatedPlaylists
        
        struct RelatedPlaylists: Codable {
            let uploads: String
            let watchHistory: String
            let watchLater: String
        }
    }
    
    var name: String { return snippet.title }
    var thumbnailURL: URL? { return URL(string: snippet.thumbnails.medium.url)}
    var playlistID: String { return contentDetails.relatedPlaylists.uploads }
    
    var videos = [Video]()
    var nextVideo: Video? { return videos.filter { $0.progress <= 0 }.first }
    
    func refreshVideos() {
        YouTube.reloadPlaylistItems(for: self) {
            let recordIDs = self.videos.map { CKRecordID(recordName: $0.id) }
            let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
            operation.fetchRecordsCompletionBlock = { results, error in
                guard let results = results else { print("Fetch Error"); return }
                for video in self.videos {
                    let record = results.first(where: { $0.key.recordName == video.id })?.value ?? CKRecord(recordType: "Video", recordID: CKRecordID(recordName: video.id))
                    video.record = record
                }
                DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .showUpdated)) }
            }
            CKContainer.default().privateCloudDatabase.add(operation)
        }
    }
}
