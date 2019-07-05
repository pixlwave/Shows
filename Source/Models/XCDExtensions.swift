import XCDYouTubeKit

extension XCDYouTubeVideoQuality {
    static let dashH264Formats = [137, 136, 135, 134, 133]
    static let dashAACFormats = [141, 140, 139]
}

extension XCDYouTubeVideo {
    
    private func dashH264URLs() -> [Int: URL]? {
        let urls = streamURLs.filter {
            guard let key = $0.key as? Int else { return false }
            return XCDYouTubeVideoQuality.dashH264Formats.contains(key)
        }
        
        return urls as? [Int: URL]
    }
    
    private func dashAACURLs() -> [Int: URL]? {
        let urls = streamURLs.filter {
            guard let key = $0.key as? Int else { return false }
            return XCDYouTubeVideoQuality.dashAACFormats.contains(key)
        }
        
        return urls as? [Int: URL]
    }
    
    func bestH264StreamURL() -> URL? {
        guard let urls = dashH264URLs() else { return nil }
        
        #warning("This currently chooses 133 (240p) over 22 (720p)")
        for tag in XCDYouTubeVideoQuality.dashH264Formats {
            if let url = urls[tag] { return url }
        }
        
        return nil
    }
    
    func bestAACStreamURL() -> URL? {
        guard let urls = dashAACURLs() else { return nil }
        
        for tag in XCDYouTubeVideoQuality.dashAACFormats {
            if let url = urls[tag] { return url }
        }
        
        return nil
    }
    
    func bestQualityItem() -> AVPlayerItem? {
        guard let videoURL = bestH264StreamURL(), let audioURL = bestAACStreamURL() else { return standardQualityItem() }
        let composition = AVMutableComposition()
        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)
        
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        guard
            let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first,
            let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first
        else { return standardQualityItem() }
        
        do {
            #warning("FIXME: Both assets report a duration that's twice their length")
            try videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoAssetTrack, at: .zero)
            try audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: audioAsset.duration), of: audioAssetTrack, at: .zero)
        } catch {
            print("Composition error: \(error)")
            return standardQualityItem()
        }
        
        return AVPlayerItem(asset: composition)
    }
    
    func standardQualityItem() -> AVPlayerItem? {
        if let url = streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] {
            return AVPlayerItem(url: url)
        } else if let url = streamURLs[XCDYouTubeVideoQuality.medium360.rawValue] {
            return AVPlayerItem(url: url)
        } else {
            return nil
        }
    }
    
}
