import Foundation

class Cloud {
    
    private static var store = NSUbiquitousKeyValueStore.default
    
    static var watchedList: [String: Bool] = store.dictionary(forKey: "watched") as? [String: Bool] ?? [String: Bool]() {
        didSet {
            store.set(watchedList, forKey: "watched")
        }
    }
    
    static func reloadWatchedList() {
        if let newList = store.dictionary(forKey: "watched") as? [String: Bool] {
            watchedList = newList
        }
    }
    
    static func queryWatchedStatus(of videoID: String) -> Bool {
        return watchedList[videoID] ?? false
    }
    
    static func mark(_ videoID: String, as watched: Bool) {
        watchedList[videoID] = watched
    }
    
}
