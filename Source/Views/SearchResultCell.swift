import UIKit

class SearchResultCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subscriptionStatusLabel: UILabel!
    
    var thumbnailDataTask: Task<(), Error>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        thumbnailDataTask?.cancel()
    }
}
