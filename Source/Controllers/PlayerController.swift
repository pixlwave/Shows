import UIKit
import WebKit

class PlayerController: UIViewController {
    
    var video: YTPlaylistItem?
    
    @IBOutlet weak var videoLoadingIndicator: UIActivityIndicatorView!
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.allowsInlineMediaPlayback = false
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let userContentController = WKUserContentController()
        let messageHandler = WebKitMessageHandler()
        userContentController.add(messageHandler, name: "videoBeganPlaying")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.isHidden = true
        webView.customUserAgent = "Shows App"
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoBeganPlaying), name: .videoBeganPlaying, object: nil)
        view.addSubview(webView)
        loadEmbedHTML()
    }
    
    override func viewDidLayoutSubviews() {
        let safeArea = view.safeAreaInsets
        webView.frame = CGRect(x: safeArea.left, y: safeArea.top, width: view.frame.width - safeArea.left - safeArea.right, height: view.frame.height - safeArea.top - safeArea.bottom)
    }
    
    @objc func videoBeganPlaying() {
        videoLoadingIndicator.stopAnimating()
    }
    
    @IBAction func shareVideo(_ sender: UIBarButtonItem) {
        guard let video = video, let shareURL = URL(string: "https://youtu.be/\(video.videoID)") else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
    
    func loadEmbedURL() {
        guard let video = video else { return }
        guard let url = URL(string: "https://www.youtube-nocookie.com/embed/\(video.videoID)?vq=hd720&rel=0&showinfo=0") else { return }

        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        webView.load(request)
    }
    
    func loadEmbedHTML() {
        guard let video = video else { return }
        let htmlString = html(for: video.videoID)
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func html(for videoID: String) -> String {
        let string = """
<html>
<head><meta name="viewport" content="width=1280"></head>
<body>
    <div id="player"></div>
    
    <script>
        // get youtube iframe api
        var tag = document.createElement('script');
        
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        
        // create 720p player
        var player;
        function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
                width: '1280',
                height: '720',
                videoId: '\(videoID)',
                playerVars: {rel: 0, showinfo: 0},
                events: {
                    'onReady': onPlayerReady,
                    'onStateChange': onPlayerStateChange
                }
            });
        }
        
        // set quality to 720p and play video
        function onPlayerReady(event) {
            player.setPlaybackQuality('hd720');
            event.target.playVideo();
        }
        
        function onPlayerStateChange(event) {
            if (event.data == YT.PlayerState.PLAYING) window.webkit.messageHandlers.videoBeganPlaying.postMessage(true);
        }
    </script>
</body>
</html>
"""
        return string
    }
    
}


// MARK: WKScriptMessageHandler
class WebKitMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .videoBeganPlaying)) }
    }
}
