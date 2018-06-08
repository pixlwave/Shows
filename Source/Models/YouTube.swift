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
    
    static func channelSearchURL(for query: String) -> URL? {
        return URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(query)&type=channel&maxResults=15&key=\(key)")
    }
    
    static func channelItemListURL(for channelID: String) -> URL? {
        return URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails&id=\(channelID)&key=\(key)")
    }
    
    static func playlistItemListURL(for playlistID: String) -> URL? {
        return URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&maxResults=50&key=\(key)")
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
