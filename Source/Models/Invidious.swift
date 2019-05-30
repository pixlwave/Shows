import Foundation

class Invidious {
    
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
            #warning("Implement this")
            // subscribe(to: id) { group.leave() }
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
    
    static func search(for query: String, completionHandler: @escaping ([Channel]) -> Void) {
        guard let url = channelSearchURL(for: query) else { completionHandler([Channel]()); return }
        
        queryAPI(with: url) { data, response, error in
            if let data = data {
                do {
                    let searchList = try jsonDecoder.decode([Channel].self, from: data)
                    completionHandler(searchList)
                } catch {
                    print("Error \(error)")
                    completionHandler([Channel]())
                }
            }
        }
    }
    
    static func subscribe(to channel: Channel, completionHandler: @escaping () -> Void) {
        subscriptions.append(channel)
        UserData.saveSubscription(to: channel.id)    // FIXME: This gets called on initial load. Needs getChannel()
        channel.reloadPlaylistItems(completionHandler: completionHandler)
    }
    
    static func unsubscribe(from searchResult: Channel) {
        subscriptions = subscriptions.filter {$0.id != searchResult.id }
        UserData.deleteSubscription(to: searchResult.id)
    }
    
    static func channelSearchURL(for query: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "invidio.us"
        urlComponents.path = "/api/v1/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "channel"),
        ]
        
        return urlComponents.url
    }
    
    static func channelItemListURL(for channelID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "invidio.us"
        urlComponents.path = "/api/v1/channels/\(channelID)"
        urlComponents.queryItems = [
            URLQueryItem(name: "sort_by", value: "newest")
        ]
        
        return urlComponents.url
    }
    
    static func playlistItemListURL(for playlistID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "invidio.us"
        urlComponents.path = "/api/v1/playlists/\(playlistID)"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "0")
        ]
        
        return urlComponents.url
    }
    
    static func channelVideosURL(for channelID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "invidio.us"
        urlComponents.path = "/api/v1/channels/\(channelID)/videos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "sort_by", value: "newest")
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
