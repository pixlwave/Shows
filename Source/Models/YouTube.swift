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
    
    static var subscriptions: [YouTubeChannel] = [
        YouTubeChannel(id: "UCtinbF-Q-fVthA0qrFQTgXQ"),
        YouTubeChannel(id: "UCzz4CoEgSgWNs9ZAvRMhW2A"),
        YouTubeChannel(id: "UCPzFLpOblZEaIx2lpym1l1A"),
        YouTubeChannel(id: "UCUK0HBIBWgM2c4vsPhkYY4w"),
        YouTubeChannel(id: "UC3fg6pL63upkXCc0T203wVg"),
        YouTubeChannel(id: "UCknMR7NOY6ZKcVbyzOxQPhw"),
        YouTubeChannel(id: "UC3KEoMzNz8eYnwBC34RaKCQ"),
        YouTubeChannel(id: "UC4_m1_0MTTmnWo4tpB0O_7g"),
        YouTubeChannel(id: "UCbvIIQc5Jo9-jIXnkPe03oA"),
        YouTubeChannel(id: "UCwC0l6riU37de9Nn_cC7pxw"),
        YouTubeChannel(id: "UCKuHFYu3smtrl2AwwMOXOlg"),
        YouTubeChannel(id: "UCcM_6ay33BNpChknCrMCgig"),
        YouTubeChannel(id: "UCT_EEbG4JlI-ww9j2FGJ99A"),
        YouTubeChannel(id: "UC3DkFux8Iv-aYnTRWzwaiBA"),
        YouTubeChannel(id: "UCBJycsmduvYEL83R_U4JriQ"),
        YouTubeChannel(id: "UCp8mr0kjVyVAmvexLDqB60A")
    ]
    
    static func reload() {
        for show in subscriptions { update(show) }
    }
    
    static func update(_ channel: YouTubeChannel) {
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails&id=\(channel.id)&key=\(key)") else { return }
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let channelList = try jsonDecoder.decode(YTChannelListResponse.self, from: data)
                    guard let channelItem = channelList.items.first else { return }
                    let playlistID = channelItem.contentDetails.relatedPlaylists.uploads
                    let channelName = channelItem.snippet.title
                    
                    channel.playlistID = playlistID
                    channel.name = channelName
                    channel.thumbnailURL = URL(string: channelItem.snippet.thumbnails.first?.value.url ?? "")
                    playlistItems(for: channel)    // TODO: This should be somewhere else?
                } catch {
                    print("Error \(error)")
                }
            }
        }
        
        task.resume()
    }
    
    static func playlistItems(for channel: YouTubeChannel) {
        guard let playlistID = channel.playlistID else { return }
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&maxResults=20&key=\(key)") else { return }
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
