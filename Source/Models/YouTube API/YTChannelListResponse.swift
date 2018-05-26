import Foundation

struct YTChannelListResponse: Codable {
    let kind: String
    let etag: String
    let pageInfo: YTPageInfo
    let items: [YTChannelItem]
}
