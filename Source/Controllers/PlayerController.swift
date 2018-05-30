import UIKit
import WebKit

class PlayerController: UIViewController {
    
    var video: YTPlaylistItem?
    var loaded = false
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let video = video else { return }
        guard let url = URL(string: "https://www.youtube-nocookie.com/embed/\(video.videoID)") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
}
