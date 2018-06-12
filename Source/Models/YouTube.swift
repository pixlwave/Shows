import Foundation

class YouTube {
    
    private static let key = try! String(contentsOf: Bundle.main.url(forResource: "Key", withExtension: nil)!)
    private static let session = URLSession.shared
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let dateString = try decoder.singleValueContainer().decode(String.self)
            return Formatter.jsonDate.date(from: dateString) ?? Date()
        })
        return decoder
    }()
    
    static var subscriptions = [Channel]()
    
    static func loadSubscriptions() {
        subscriptions = [Channel]()
        let group = DispatchGroup()
        
        for id in UserData.subscriptionIDs {
            group.enter()
            subscribe(to: id) { group.leave() }
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
            sortSubscriptions()
        }))
    }
    
    static func reload() {
        let group = DispatchGroup()
        
        for channel in subscriptions {
            group.enter()
            channel.reloadPlaylistItems { group.leave() }
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
            sortSubscriptions()
        }))
    }
    
    static func search(for query: String, completionHandler: @escaping ([YTSearchResult]) -> Void) {
        guard let url = channelSearchURL(for: query) else { completionHandler([YTSearchResult]()); return }
        
        queryAPI(with: url) { data, response, error in
            if let data = data {
                do {
                    let searchList = try jsonDecoder.decode(YTSearchListResonse.self, from: data)
                    completionHandler(searchList.items)
                } catch {
                    print("Error \(error)")
                    completionHandler([YTSearchResult]())
                }
            }
        }
    }
    
    static func subscribe(to id: String, completionHandler: @escaping () -> Void) {
        guard let url = channelItemListURL(for: id) else { completionHandler(); return }
        
        queryAPI(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let channelList = try jsonDecoder.decode(YTChannelListResponse.self, from: data)
                    guard let channelItem = channelList.items.first else { completionHandler(); return }
                    let channel = Channel(item: channelItem)
                    subscriptions.append(channel)
                    UserData.saveSubscription(to: id)    // FIXME: This gets called on initial load. Needs getChannel()
                    channel.reloadPlaylistItems(completionHandler: completionHandler)
                } catch {
                    print("Error \(error)")
                    completionHandler()
                }
            } else {
                completionHandler()
            }
        }
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
    
    static func queryAPI(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.dataTask(with: url, completionHandler: completionHandler).resume()
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
