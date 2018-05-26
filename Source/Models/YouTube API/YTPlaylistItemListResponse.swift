import Foundation

struct YTPlaylistItemListResponse: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let prevPageToken: String?
    let pageInfo: YTPageInfo
    let items: [YTPlaylistItem]
}
