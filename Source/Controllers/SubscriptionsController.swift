import UIKit

class SubscriptionsController: UICollectionViewController {
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshSubscriptions), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .subsUpdated, object: nil)
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
        DispatchQueue.global(qos: .userInitiated).async {
            YouTube.reload()
        }
    }
    
    @objc func reloadData() {
        collectionView?.reloadData()
        refreshControl.endRefreshing()
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
            cell.thumbnailImageView.load(from: url)
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewDelegateFlowLayout
extension SubscriptionsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return
            CGSize(width: 100, height: 110)
        }
        
        // FIXME: just compute this once until view size changes?
        let limit: CGFloat = 100
        let width = collectionView.safeAreaLayoutGuide.layoutFrame.width
        let numberOfColumns = (width / limit).rounded(.down)
        var cellWidth = (width / numberOfColumns) - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        if numberOfColumns > 1 { cellWidth -= flowLayout.minimumInteritemSpacing }
        return CGSize(width: cellWidth, height: cellWidth * 1.1)
    }
}
