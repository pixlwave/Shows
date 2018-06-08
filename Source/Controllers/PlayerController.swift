import UIKit
import WebKit

class PlayerController: UIViewController {
    
    var video: Video?
    
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
        userContentController.add(messageHandler, name: "videoPausedWithProgress")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.isHidden = true
        webView.customUserAgent = "Shows App"
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoBeganPlaying), name: .videoBeganPlaying, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPausedWithProgress), name: .videoPausedWithProgress, object: nil)
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
    
    @objc func videoPausedWithProgress(notification: Notification) {
        guard let progress = notification.userInfo?["progress"] as? Double else { return }
        video?.progress = progress
    }
    
    @IBAction func shareVideo(_ sender: UIBarButtonItem) {
        guard let video = video, let shareURL = URL(string: "https://youtu.be/\(video.id)") else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        shareSheet.popoverPresentationController?.barButtonItem = sender    // FIXME: centre sheet arrow on button
        present(shareSheet, animated: true)
    }
    
    func loadEmbedHTML() {
        guard let video = video else { return }
        let htmlString = html(for: video.id)
        
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
            if (event.data == YT.PlayerState.PLAYING) {
            	window.webkit.messageHandlers.videoBeganPlaying.postMessage(true);
            } else if (event.data == YT.PlayerState.PAUSED) {
            	window.webkit.messageHandlers.videoPausedWithProgress.postMessage(player.getCurrentTime() / player.getDuration());
            } else if (event.data == YTPlayerState.ENDED) {
                window.webkit.messageHandlers.videoPausedWithProgress.postMessage(1.0);
            }
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
        if message.name == "videoBeganPlaying" {
            DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .videoBeganPlaying)) }
        } else if message.name == "videoPausedWithProgress" {
            guard let progress = message.body as? Double else { return }
            DispatchQueue.main.async { NotificationCenter.default.post(name: .videoPausedWithProgress, object: nil, userInfo: ["progress": progress]) }
        }
    }
}
