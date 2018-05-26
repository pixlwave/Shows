import Foundation

struct YTChannelListResponse: Codable {
    let etag: String
    let pageInfo: YTPageInfo
    let items: [YTChannelItem]
}
