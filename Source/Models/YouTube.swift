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
    
    static var subscriptions = [YTChannelItem]()
    
    static func loadSubscriptions() {
        subscriptions = [YTChannelItem]()
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
        
        for show in subscriptions {
            group.enter()
            reloadPlaylistItems(for: show) { group.leave() }
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
            sortSubscriptions()
        }))
    }
    
    static func search(for query: String, completionHandler: @escaping ([YTSearchResult]) -> Void) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(query)&type=channel&maxResults=15&key=\(key)") else { completionHandler([YTSearchResult]()); return }
        
        let task = session.dataTask(with: url) { data, response, error in
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
        
        task.resume()
    }
    
    static func subscribe(to id: String, completionHandler: @escaping () -> Void) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails&id=\(id)&key=\(key)") else { completionHandler(); return }
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let channelList = try jsonDecoder.decode(YTChannelListResponse.self, from: data)
                    guard let channelItem = channelList.items.first else { completionHandler(); return }
                    subscriptions.append(channelItem)
                    UserData.addSubscription(to: id)    // FIXME: This gets called on initial load. Needs getChannel()
                    reloadPlaylistItems(for: channelItem, completionHandler: completionHandler)
                } catch {
                    print("Error \(error)")
                    completionHandler()
                }
            } else {
                completionHandler()
            }
        }
        
        task.resume()
    }
    
    static func reloadSubscriptionInfo() {
        // TODO: Implement this
    }
    
    static func reloadPlaylistItems(for channel: YTChannelItem, completionHandler: @escaping () -> Void) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(channel.playlistID)&maxResults=50&key=\(key)") else { completionHandler(); return }
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let playlistItemList = try jsonDecoder.decode(YTPlaylistItemListResponse.self, from: data)
                    channel.videos = playlistItemList.items.map { Video(item: $0) }     // FIXME: this erases user data
                } catch {
                    print("Error \(error)")
                }
            }
            completionHandler()
        }
            
        task.resume()
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
