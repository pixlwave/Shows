import UIKit

class SearchController: UICollectionViewController {
    
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
extension SearchController {
 
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return 0 }
        
        return results.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let show = results[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell ?? SearchResultCell()
        cell.nameLabel.text = show.name
        cell.subscriptionStatusLabel.text = show.isSubscribed ? "Subscribed" : "Subscribe"
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


// MARK: UICollectionViewDelegate
extension SearchController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SearchResultCell else { return }
        let searchResult = results[indexPath.row]
        cell.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        
        Task {
            if !searchResult.isSubscribed {
                do {
                    try await YouTube.shared.subscribe(to: searchResult.snippet.channelId)
                    cell.subscriptionStatusLabel.text = searchResult.isSubscribed ? "Subscribed" : "Subscribe"
                    UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
                    YouTube.shared.sortSubscriptions()
                } catch {
                    print(error)
                }
            } else {
                YouTube.shared.unsubscribe(from: searchResult.snippet.channelId)
                cell.subscriptionStatusLabel.text = searchResult.isSubscribed ? "Subscribed" : "Subscribe"
                UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
                NotificationCenter.default.post(Notification(name: .subsUpdated))
            }
        }
    }
    
}


// MARK: UISearchResultsUpdating
extension SearchController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        //
    }
    
}


// MARK: UISearchBarDelegate
extension SearchController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return }
        
        Task {
            do {
                let results = try await YouTube.shared.search(for: query)
                self.results = results
                self.collectionView?.reloadData()
                if results.count > 0 {
                    self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            } catch {
                print(error)
            }
        }
    }
}
