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
    
    @IBAction func subscribeToShow(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? SearchResultCell else { return }
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        let searchResult = results[indexPath.row]
        guard !searchResult.subscribed else { return }
        
        YouTube.subscribe(to: searchResult.snippet.channelId) {
            DispatchQueue.main.async {
                sender.setTitle(searchResult.subscribed ? "Subscribed" : "Subscribe", for: .normal)
                YouTube.sortSubscriptions()
            }
        }
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
        cell.thumbnailImageView.image = nil

        if let url = video.thumbnailURL {
            cell.thumbnailImageView.load(from: url)
        }
        
        let subscribeButtonTitle = video.subscribed ? "Subscribed" : "Subscribe"
        cell.subscribeButton.setTitle(subscribeButtonTitle, for: .normal)
        
        return cell
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
            }
        }
    }
}
