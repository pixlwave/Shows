import UIKit

class ShowController: UICollectionViewController {
    
    var show: Channel?
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshShow), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .showUpdated, object: nil)
        collectionView?.invalidateIntrinsicContentSize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = show?.name
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.invalidateLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlayerSegue" {
            guard let destVC = segue.destination as? PlayerController else { return }
            guard let tappedCell = sender as? VideoCell else { return }
            guard let videoIndex = collectionView?.indexPath(for: tappedCell)?.row else { return }
            guard let video = show?.playlist[videoIndex] else { return }
            destVC.video = video
        }
    }
    
    @objc func refreshShow() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.show?.reloadPlaylistItems { }
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
    
}


// MARK: UICollectionViewControllerDataSource
extension ShowController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return show?.playlist.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let video = show?.playlist[indexPath.row] else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCell ?? VideoCell()
        cell.titleLabel.text = video.title
        cell.thumbnailImageView.image = nil
        cell.watchedLabel.isHidden = video.progress <= 0
        cell.publishedAtLabel.text = video.publishedString
        
        if let url = video.thumbnailURL {
            cell.thumbnailImageView.load(from: url)
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewDelegateFlowLayout
extension ShowController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return
            CGSize(width: 295, height: 95)
        }
        
        // FIXME: just compute this once until view size changes?
        let limit: CGFloat = 275
        let width = collectionView.safeAreaLayoutGuide.layoutFrame.width
        let numberOfColumns = (width / limit).rounded(.down)
        var cellWidth = (width / numberOfColumns) - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        if numberOfColumns > 1 { cellWidth -= flowLayout.minimumInteritemSpacing }
        return CGSize(width: cellWidth, height: (cellWidth / 32 * 9).rounded())
    }
}
