import UIKit

class ShowSearchController: UICollectionViewController {
    
    var results = [YTSearchResult]()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Shows"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
}


// MARK: UICollectionViewDataSource
extension ShowSearchController {
 
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return 0 }
        
        return results.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let video = results[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell ?? SearchResultCell()
        cell.nameLabel.text = video.name
        cell.subscriptionStatusLabel.text = video.subscribed ? "Subscribed" : "Subscribe"
        cell.thumbnailImageView.image = nil

        if let url = video.thumbnailURL {
            cell.thumbnailImageView.load(from: url)
        }
        
        return cell
    }
    
}


// MARK: UICollectionViewDelegate
extension ShowSearchController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SearchResultCell else { return }
        let searchResult = results[indexPath.row]
        cell.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        
        if !searchResult.subscribed {
            YouTube.subscribe(to: searchResult.snippet.channelId) {
                DispatchQueue.main.async {
                    cell.subscriptionStatusLabel.text = searchResult.subscribed ? "Subscribed" : "Subscribe"
                    UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
                    YouTube.sortSubscriptions()
                }
            }
        } else {
            YouTube.unsubscribe(from: searchResult.snippet.channelId)
            cell.subscriptionStatusLabel.text = searchResult.subscribed ? "Subscribed" : "Subscribe"
            UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
            NotificationCenter.default.post(Notification(name: .subsUpdated))
        }
    }
    
}


// MARK: UISearchResultsUpdating
extension ShowSearchController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        //
    }
    
}


// MARK: UISearchBarDelegate
extension ShowSearchController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return }
        
        YouTube.search(for: query) { results in
            DispatchQueue.main.async {
                self.results = results
                self.collectionView?.reloadData()
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
}
