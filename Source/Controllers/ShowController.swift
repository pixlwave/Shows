import UIKit
import AVKit
import XCDYouTubeKit

class ShowController: UICollectionViewController {
    
    var show: Channel?
    
    lazy var dataSource = createDataSource()
    
    var refreshControl = UIRefreshControl()
    var playerController: AVPlayerViewController?
    weak var playingVideoCell: VideoCell?
    weak var playingVideo: Video?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        refreshControl.addTarget(self, action: #selector(refreshShow), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .showUpdated, object: nil)
        reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlayerSegue" {
            guard
                let playerVC = segue.destination as? AVPlayerViewController,
                let cell = sender as? VideoCell,
                let videoIndex = collectionView?.indexPath(for: cell)?.row,
                let video = show?.playlist[videoIndex]
            else { return }
            
            XCDYouTubeClient.default().getVideoWithIdentifier(video.id) { video, error in
                guard let video = video, let item = video.standardQualityItem() else { return }
                playerVC.player = AVPlayer(playerItem: item)
                playerVC.player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
                playerVC.player?.play()
            }
            
            playerVC.entersFullScreenWhenPlaybackBegins = true
            playerVC.delegate = self
            playingVideoCell = cell
            playingVideo = video
        }
    }
    
    func createDataSource() -> UICollectionViewDiffableDataSource<Int, Video> {
        return UICollectionViewDiffableDataSource<Int, Video>(collectionView: collectionView) { collectionView, indexPath, video -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCell ?? VideoCell()
            
            cell.titleLabel.text = video.title
            cell.thumbnailImageView.image = nil
            cell.watchedLabel.isHidden = video.progress <= 0
            cell.publishedAtLabel.text = video.publishedString
            
            if let url = video.thumbnailURL {
                cell.thumbnailDataTask = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async { cell.thumbnailImageView.image = image }
                }
                cell.thumbnailDataTask?.resume()
            }
            
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
            
            let minimumWidth: CGFloat = 275
            let count = Int(layoutEnvironment.container.effectiveContentSize.width / minimumWidth)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.3 / CGFloat(count)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = item.contentInsets
            
            return section
        }
    }
    
    @objc func refreshShow() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.show?.reloadPlaylistItems { }
        }
    }
    
    @objc func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Video>()
        snapshot.appendSections([0])
        snapshot.appendItems(show?.playlist ?? [Video]())
        dataSource.apply(snapshot)
        refreshControl.endRefreshing()
    }
    
    @IBAction func presentVideoOptions(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            let tapLocation = sender.location(in: collectionView)
            guard let indexPath = collectionView?.indexPathForItem(at: tapLocation) else { return }
            guard let video = show?.playlist[indexPath.row] else { return }
            let cell = self.collectionView?.cellForItem(at: indexPath) as? VideoCell

            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let watchedActionTitle = video.progress > 0 ? "Mark as unwatched" : "Mark as watched"
            let watchedAction = UIAlertAction(title: watchedActionTitle, style: .default) { action in
                video.watched = !video.watched
                cell?.watchedLabel.isHidden = !video.watched
            }
            actionSheet.addAction(watchedAction)
            
            let shareAction = UIAlertAction(title: "Share", style: .default) { action in
                guard let shareURL = URL(string: "https://youtu.be/\(video.id)") else { return }
                let shareSheet = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
                shareSheet.popoverPresentationController?.sourceView = cell
                shareSheet.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
                shareSheet.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                self.present(shareSheet, animated: true)
            }
            actionSheet.addAction(shareAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(cancelAction)
            
            actionSheet.popoverPresentationController?.sourceView = cell
            actionSheet.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
            actionSheet.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            present(actionSheet, animated: true)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate", let rate = change?[.newKey] as? Float, rate == 0, let player = object as? AVPlayer {
            guard let item = player.currentItem else { return }
            let progress = item.currentTime().seconds / item.duration.seconds
            playingVideo?.progress = progress
            playingVideoCell?.watchedLabel.isHidden = progress <= 0
        }
    }
    
}


// MARK: AVPlayerViewControllerDelegate
extension ShowController: AVPlayerViewControllerDelegate {
    
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        playerController = playerViewController
    }
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        //
    }
}
