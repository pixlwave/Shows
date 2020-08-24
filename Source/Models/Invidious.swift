import Foundation
import OrderedSet

class Invidious: ObservableObject {
    
    static let shared = Invidious()
    
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let dateString = try decoder.singleValueContainer().decode(String.self)
            return Formatter.jsonDate.date(from: dateString) ?? Date()
        })
        return decoder
    }()
    
    @Published var subscriptions = OrderedSet<Channel>()
    
    func loadSubscriptions() {
        DispatchQueue.main.async { self.subscriptions = OrderedSet<Channel>() }
        let group = DispatchGroup()
        
        for id in UserData.subscriptionIDs {
            group.enter()
            loadSubscription(from: id) { group.leave() }
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
            self.sortSubscriptions()
        }))
    }
    
    func loadSubscription(from id: String, completionHandler: @escaping () -> Void) {
        guard let url = channelSearchURL(for: id) else { completionHandler(); return }
        
        queryAPI(with: url) { data, response, error in
            if let data = data {
                do {
                    if let channel = try self.jsonDecoder.decode([Channel].self, from: data).first {
                        self.subscribe(to: channel, completionHandler: completionHandler)
                    } else {
                        completionHandler()
                    }
                } catch {
                    print("Error \(error)")
                    completionHandler()
                }
            }
        }
    }
    
    func reload() {
        let group = DispatchGroup()
        
        for channel in subscriptions {
            group.enter()
            channel.reloadPlaylistItems { group.leave() }
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
            self.sortSubscriptions()
        }))
    }
    
    func search(for query: String, completionHandler: @escaping ([Channel]) -> Void) {
        guard let url = channelSearchURL(for: query) else { completionHandler([Channel]()); return }
        
        queryAPI(with: url) { data, response, error in
            if let data = data {
                do {
                    let searchList = try self.jsonDecoder.decode([Channel].self, from: data)
                    completionHandler(searchList)
                } catch {
                    print("Error \(error)")
                    completionHandler([Channel]())
                }
            }
        }
    }
    
    func subscribe(to channel: Channel, completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { self.subscriptions.append(channel) }  // ensure sure subscriptions is updated on the main thread
        UserData.saveSubscription(to: channel.id);  #warning("This gets called on initial load. Needs getChannel()")
        channel.reloadPlaylistItems(completionHandler: completionHandler)
    }
    
    func unsubscribe(from searchResult: Channel) {
        subscriptions = OrderedSet(sequence: subscriptions.filter {$0.id != searchResult.id })
        UserData.deleteSubscription(to: searchResult.id)
    }
    
    private func apiURLComponents() -> URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "invidio.us"
        return urlComponents
    }
    
    func channelSearchURL(for query: String) -> URL? {
        var urlComponents = apiURLComponents()
        urlComponents.path = "/api/v1/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "channel"),
        ]
        
        return urlComponents.url
    }
    
    func feedURL(for channelID: String) -> URL? {
        var urlComponents = apiURLComponents()
        urlComponents.path = "/feed/channel/\(channelID)"
        
        return urlComponents.url
    }
    
    func channelVideosURL(for channelID: String) -> URL? {
        var urlComponents = apiURLComponents()
        urlComponents.path = "/api/v1/channels/\(channelID)/videos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "sort_by", value: "newest")
        ]
        
        return urlComponents.url
    }
    
    func queryAPI(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.dataTask(with: url, completionHandler: completionHandler).resume()
    }
    
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        return try jsonDecoder.decode(type, from: data)
    }
    
    func sortSubscriptions() {
        let sorted = subscriptions.sorted { channel1, channel2 -> Bool in
            guard let date1 = channel1.nextVideo?.publishedAt else { return false }
            guard let date2 = channel2.nextVideo?.publishedAt else { return true }
            return date1.compare(date2) == .orderedDescending
        }
        
        subscriptions = OrderedSet(sequence: sorted)
        NotificationCenter.default.post(Notification(name: .subsUpdated))
    }
    
}
