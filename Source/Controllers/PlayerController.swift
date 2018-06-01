import UIKit
import WebKit

class PlayerController: UIViewController {
    
    var video: YTPlaylistItem?
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.isHidden = true
        webView.customUserAgent = "Shows App"
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        loadEmbedHTML()
    }
    
    override func viewDidLayoutSubviews() {
        let safeArea = view.safeAreaInsets
        webView.frame = CGRect(x: safeArea.left, y: safeArea.top, width: view.frame.width - safeArea.left - safeArea.right, height: view.frame.height - safeArea.top - safeArea.bottom)
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
		            'onReady': onPlayerReady
		        }
		    });
		}
		  
		// set quality to 720p and play video
		function onPlayerReady(event) {
		    player.setPlaybackQuality('hd720');
            event.target.playVideo();
		}
	</script>
</body>
</html>
"""
        return string
    }
    
}
