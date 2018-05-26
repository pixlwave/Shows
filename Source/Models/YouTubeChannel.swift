import Foundation

class YouTubeChannel {
    let id: String
    var name: String?
    var thumbnailURL: URL?
    var playlistID: String?
    var videos = [YTPlaylistItem]()
    
    init(id: String) {
        self.id = id
    }
}
