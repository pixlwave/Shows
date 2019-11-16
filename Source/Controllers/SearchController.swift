import UIKit

class SearchController: UICollectionViewController {
    
    var results = [Channel]()
    let searchController = UISearchController(searchResultsController: nil)
    lazy var dataSource = createDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Shows"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
    }
    
    func createDataSource() -> UICollectionViewDiffableDataSource<Int, Channel> {
        return UICollectionViewDiffableDataSource<Int, Channel>(collectionView: collectionView) { collectionView, indexPath, channel -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell ?? SearchResultCell()
            
            cell.nameLabel.text = channel.name
            cell.subscriptionStatusLabel.text = channel.subscribed ? "Subscribed" : "Subscribe"
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
        return UICollectionViewCompositionalLayout { section, layoutEnvironment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))
            let count = Int(layoutEnvironment.container.effectiveContentSize.width / 250)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Channel>()
        
        if let query = searchController.searchBar.text, !query.isEmpty {
            snapshot.appendSections([0])
            snapshot.appendItems(results)
        }
        
        dataSource.apply(snapshot)
    }
    
}


// MARK: UICollectionViewDelegate
extension SearchController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SearchResultCell else { return }
        let searchResult = results[indexPath.row]
        cell.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        
        if !searchResult.subscribed {
            Invidious.subscribe(to: searchResult) {
                DispatchQueue.main.async {
                    cell.subscriptionStatusLabel.text = searchResult.subscribed ? "Subscribed" : "Subscribe"
                    UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
                    Invidious.sortSubscriptions()
                }
            }
        } else {
            Invidious.unsubscribe(from: searchResult)
            cell.subscriptionStatusLabel.text = searchResult.subscribed ? "Subscribed" : "Subscribe"
            UIView.animate(withDuration: 0.1) { cell.backgroundColor = UIColor.clear }
            NotificationCenter.default.post(Notification(name: .subsUpdated))
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
        
        Invidious.search(for: query) { results in
            DispatchQueue.main.async {
                self.results = results
                self.applySnapshot()
                if results.count > 0 {
                    self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            }
        }
    }
}
