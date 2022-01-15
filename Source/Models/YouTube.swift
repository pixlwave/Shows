import Foundation

class YouTube {
    
    private static let key = try! String(contentsOf: Bundle.main.url(forResource: "Key", withExtension: nil)!)
    private static let session = URLSession.shared
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let dateString = try decoder.singleValueContainer().decode(String.self)
            return Formatter.jsonDate.date(from: dateString) ?? Date()
        }
        return decoder
    }()
    
    enum APIError: Error {
        case invalidURL
        case unknownChannelID
        case apiResponse(HTTPURLResponse, String?)
        case unknown
    }
    
    static var subscriptions = [Channel]()
    
    static func loadSubscriptions() async throws {
        subscriptions = [Channel]()
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for id in UserData.subscriptionIDs {
                group.addTask {
                    try await subscribe(to: id)
                }
            }
        }
        
        sortSubscriptions()
    }
    
    static func reload() async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for channel in subscriptions {
                group.addTask {
                    try await channel.reloadPlaylistItems()
                }
            }
        }
        
        sortSubscriptions()
    }
    
    static func search(for query: String) async throws -> [YTSearchResult]  {
        guard let url = channelSearchURL(for: query) else { throw APIError.invalidURL }
        let searchList = try await queryAPI(with: url, as: YTSearchListResonse.self)
        return searchList.items
    }
    
    static func subscribe(to id: String) async throws {
        guard let url = channelItemListURL(for: id) else { throw APIError.invalidURL }
        let channelList = try await queryAPI(with: url, as: YTChannelListResponse.self)
        guard let channelItem = channelList.items.first else { throw APIError.unknownChannelID }
        let channel = Channel(item: channelItem)
        subscriptions.append(channel)
        #warning("This gets called on initial load. Needs getChannel()")
        UserData.saveSubscription(to: id)
        try await channel.reloadPlaylistItems()
    }
    
    static func unsubscribe(from id: String) {
        subscriptions = subscriptions.filter {$0.id != id }
        UserData.deleteSubscription(to: id)
    }
    
    static func channelSearchURL(for query: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.googleapis.com"
        urlComponents.path = "/youtube/v3/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "channel"),
            URLQueryItem(name: "maxResults", value: "15"),
            URLQueryItem(name: "key", value: key)
        ]
        
        return urlComponents.url
    }
    
    static func channelItemListURL(for channelID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.googleapis.com"
        urlComponents.path = "/youtube/v3/channels"
        urlComponents.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "id", value: channelID),
            URLQueryItem(name: "key", value: key)
        ]
        
        return urlComponents.url
    }
    
    static func playlistItemListURL(for playlistID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.googleapis.com"
        urlComponents.path = "/youtube/v3/playlistItems"
        urlComponents.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "playlistId", value: playlistID),
            URLQueryItem(name: "maxResults", value: "50"),
            URLQueryItem(name: "key", value: key)
        ]
        
        return urlComponents.url
    }
    
    static func queryAPI<T: Decodable>(with url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        guard httpResponse.statusCode == 200 else { throw APIError.apiResponse(httpResponse, String(data: data, encoding: .utf8)) }
        let decoded = try jsonDecoder.decode(T.self, from: data)
        return decoded
    }
    
    static func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        return try jsonDecoder.decode(type, from: data)
    }
    
    static func sortSubscriptions() {
        subscriptions.sort { channel1, channel2 -> Bool in
            guard let date1 = channel1.nextVideo?.publishedAt else { return false }
            guard let date2 = channel2.nextVideo?.publishedAt else { return true }
            return date1.compare(date2) == .orderedDescending
        }
        
        NotificationCenter.default.post(Notification(name: .subsUpdated))
    }
    
}
