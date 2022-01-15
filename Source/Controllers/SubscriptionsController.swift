import UIKit
import Combine

class SubscriptionsController: UICollectionViewController {
    
    var refreshControl = UIRefreshControl()
    var updateCancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshSubscriptions), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.height), animated: false)
        refreshControl.beginRefreshing()
        
        updateCancellable = NotificationCenter.default.publisher(for: .subsUpdated, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.reloadData()
            }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.invalidateLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSegue" {
            guard let destVC = segue.destination as? ShowController else { return }
            guard let tappedCell = sender as? ShowCell else { return }
            guard let channelIndex = collectionView?.indexPath(for: tappedCell)?.row else { return }
            destVC.show = YouTube.subscriptions[channelIndex]
        }
    }
    
    @objc func refreshSubscriptions() {
        Task {
            try? await YouTube.reload()
        }
    }
    
    @objc func reloadData() {
        collectionView?.reloadData()
        refreshControl.endRefreshing()
    }

    @IBAction func presentChannelOptions(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let tapLocation = sender.location(in: collectionView)
            guard let indexPath = collectionView?.indexPathForItem(at: tapLocation) else { return }
            let channel = YouTube.subscriptions[indexPath.row]
            guard let cell = self.collectionView?.cellForItem(at: indexPath) as? ShowCell else { return }
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let watchedAction = UIAlertAction(title: "Mark all as watched", style: .default) { action in
                // TODO: Implement this
            }
            actionSheet.addAction(watchedAction)
            
            let shareAction = UIAlertAction(title: "Share", style: .default) { action in
                guard let shareURL = URL(string: "https://youtube.com/channel/\(channel.id)") else { return }
                let shareSheet = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
                shareSheet.popoverPresentationController?.sourceView = cell
                shareSheet.popoverPresentationController?.sourceRect = cell.bounds
                shareSheet.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                self.present(shareSheet, animated: true)
            }
            actionSheet.addAction(shareAction)
            
            let unsubscribeAction = UIAlertAction(title: "Unsubscribe", style: .destructive) { action in
                YouTube.unsubscribe(from: channel.id)
                self.collectionView?.deleteItems(at: [indexPath])
            }
            actionSheet.addAction(unsubscribeAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(cancelAction)
            
            actionSheet.popoverPresentationController?.sourceView = cell
            actionSheet.popoverPresentationController?.sourceRect = cell.bounds
            actionSheet.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            present(actionSheet, animated: true)
        }
    }
}


// MARK: UICollectionViewDataSource
extension SubscriptionsController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return YouTube.subscriptions.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let show = YouTube.subscriptions[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as? ShowCell ?? ShowCell()
        cell.nameLabel.text = show.name
        cell.thumbnailImageView.image = nil
        
        if let url = show.thumbnailURL {
            cell.thumbnailDataTask = Task {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }
                cell.thumbnailImageView.image = image
            }
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewDelegateFlowLayout
extension SubscriptionsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return
            CGSize(width: 100, height: 115)
        }
        
        // FIXME: just compute this once until view size changes?
        let limit: CGFloat = 100
        let width = collectionView.safeAreaLayoutGuide.layoutFrame.width
        let numberOfColumns = (width / limit).rounded(.down)
        var cellWidth = (width / numberOfColumns) - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        if numberOfColumns > 1 { cellWidth -= flowLayout.minimumInteritemSpacing }
        return CGSize(width: cellWidth, height: cellWidth * 1.15)
    }
}
