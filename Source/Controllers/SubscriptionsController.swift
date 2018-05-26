import UIKit

class SubscriptionsController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .subsUpdated, object: nil)
    }
    
    @objc func update() {
        collectionView?.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSegue" {
            guard let destVC = segue.destination as? ShowController else { return }
            guard let tappedCell = sender as? ShowCell else { return }
            guard let channelIndex = collectionView?.indexPath(for: tappedCell)?.row else { return }
            destVC.show = YouTube.subscriptions[channelIndex]
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
        
        if let url = show.thumbnailURL {
            cell.thumbnailImageView.load(from: url)
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewDelegate

extension SubscriptionsController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //
    }
    
}
