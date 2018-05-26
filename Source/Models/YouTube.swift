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
    static let defaultSubscriptionIDs = [
        "UCtinbF-Q-fVthA0qrFQTgXQ",
        "UCzz4CoEgSgWNs9ZAvRMhW2A",
        "UCPzFLpOblZEaIx2lpym1l1A",
        "UCUK0HBIBWgM2c4vsPhkYY4w",
        "UC3fg6pL63upkXCc0T203wVg",
        "UCknMR7NOY6ZKcVbyzOxQPhw",
        "UC3KEoMzNz8eYnwBC34RaKCQ",
        "UC4_m1_0MTTmnWo4tpB0O_7g",
        "UCbvIIQc5Jo9-jIXnkPe03oA",
        "UCwC0l6riU37de9Nn_cC7pxw",
        "UCKuHFYu3smtrl2AwwMOXOlg",
        "UCcM_6ay33BNpChknCrMCgig",
        "UCT_EEbG4JlI-ww9j2FGJ99A",
        "UC3DkFux8Iv-aYnTRWzwaiBA",
        "UCBJycsmduvYEL83R_U4JriQ",
        "UCp8mr0kjVyVAmvexLDqB60A"
    ]
    
    static func reload() {
        for show in subscriptions { reloadPlaylistItems(for: show) }
    }
    
    static func subscribe(to id: String) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails&id=\(id)&key=\(key)") else { return }
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let channelList = try jsonDecoder.decode(YTChannelListResponse.self, from: data)
                    guard let channelItem = channelList.items.first else { return }
                    reloadPlaylistItems(for: channelItem)
                    subscriptions.append(channelItem)
                } catch {
                    print("Error \(error)")
                }
            }
        }
        
        task.resume()
    }
    
    static func reloadSubscriptionInfo() {
        // TODO: Implement this
    }
    
    static func reloadPlaylistItems(for channel: YTChannelItem) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(channel.playlistID)&maxResults=20&key=\(key)") else { return }
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let playlistItemList = try jsonDecoder.decode(YTPlaylistItemListResponse.self, from: data)
                    print("Success")
                    channel.videos = playlistItemList.items
                    sortSubscriptions()
                } catch {
                    print("Error \(error)")
                }
            }
        }
        
        task.resume()
    }
    
    static func sortSubscriptions() {
        subscriptions.sort { channel1, channel2 -> Bool in
            guard let date1 = channel1.videos.first?.snippet.publishedAt else { return false }
            guard let date2 = channel2.videos.first?.snippet.publishedAt else { return true }
            return date1.compare(date2) == .orderedDescending
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(Notification(name: .subsUpdated))
        }
    }
    
}
