import Foundation

struct YTSearchListResonse: Codable {
    let etag: String
    let nextPageToken: String?
    let prevPageToken: String?
    let pageInfo: YTPageInfo
    let items: [YTSearchResult]
}
