import UIKit

class SubscriptionsController: UICollectionViewController {
    
    enum Section: Int, Hashable {
        case main
    }
    
    lazy var dataSource = createDataSource()
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshSubscriptions), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.height), animated: false)
        refreshControl.beginRefreshing()
        
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .subsUpdated, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSegue" {
            guard
                let destVC = segue.destination as? ShowController,
                let tappedCell = sender as? ShowCell,
                let channelIndex = collectionView?.indexPath(for: tappedCell)?.row
            else { return }
                
            destVC.show = Invidious.subscriptions[channelIndex]
            destVC.navigationItem.title = Invidious.subscriptions[channelIndex].name
        }
    }
    
    func createDataSource() -> UICollectionViewDiffableDataSource<Section, Channel> {
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, channel -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as? ShowCell ?? ShowCell()
            cell.nameLabel.text = channel.name
            cell.thumbnailImageView.image = nil
            
            if let url = channel.thumbnailURL {
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
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(125))
            let minimumWidth: CGFloat = 100
            let count = Int(layoutEnvironment.container.effectiveContentSize.width / minimumWidth)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = item.contentInsets
            
            return section
        }
    }
    
    @objc func refreshSubscriptions() {
        DispatchQueue.global(qos: .userInitiated).async {
            Invidious.reload()
        }
    }
    
    @objc func reloadData() {
        let snapshot = NSDiffableDataSourceSnapshot<Section, Channel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Invidious.subscriptions)
        dataSource.apply(snapshot)
        refreshControl.endRefreshing()
    }

    @IBAction func presentChannelOptions(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let tapLocation = sender.location(in: collectionView)
            guard let indexPath = collectionView?.indexPathForItem(at: tapLocation) else { return }
            let channel = Invidious.subscriptions[indexPath.row]
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
                Invidious.unsubscribe(from: channel)
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
