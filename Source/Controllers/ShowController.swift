import UIKit

class ShowController: UICollectionViewController {
    
    var show: YTChannelItem?
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshShow), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .showUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = show?.name
    }
    
    @objc func refreshShow() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.show?.refreshVideos()
        }
    }
    
    @objc func reloadData() {
        collectionView?.reloadData()
        refreshControl.endRefreshing()
    }
    
    @IBAction func showVideoOptions(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            let tapLocation = sender.location(in: collectionView)
            guard let indexPath = collectionView?.indexPathForItem(at: tapLocation) else { return }
            guard let video = show?.videos[indexPath.row] else { return }
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let watchedActionTitle = video.watched ? "Mark as unwatched" : "Mark as watched"
            let watchedAction = UIAlertAction(title: watchedActionTitle, style: .default) { action in
                video.watched = !video.watched
                if let cell = self.collectionView?.cellForItem(at: indexPath) as? VideoCell {
                    cell.watchedLabel.isHidden = !video.watched
                }
            }
            actionSheet.addAction(watchedAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(cancelAction)
            
            present(actionSheet, animated: true)
        }
    }
    
}


// MARK: UICollectionViewControllerDataSource
extension ShowController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return show?.videos.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let video = show?.videos[indexPath.row] else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCell ?? VideoCell()
        cell.titleLabel.text = video.snippet.title
        cell.thumbnailImageView.image = nil
        cell.watchedLabel.isHidden = !video.watched
        
        if let publishedString = Formatter.timeInterval.string(from: video.snippet.publishedAt, to: Date()) {
            cell.publishedAtLabel.text = publishedString + " ago"
        }
        
        if let url = video.thumbnailURL {
            cell.thumbnailImageView.load(from: url)
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewControllerDelegate
extension ShowController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let videoItem = show?.videos[indexPath.row] else { return }
        guard let url = URL(string: "https://youtu.be/\(videoItem.videoID)") else { return }
        videoItem.watched = true
        UIApplication.shared.open(url)
        // TODO: mark the video as watched a bit later.
        (collectionView.cellForItem(at: indexPath) as? VideoCell)?.watchedLabel.isHidden = false
    }
    
}
