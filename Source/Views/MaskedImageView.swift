import UIKit

class MaskedImageView: UIImageView {
    
    let maskLayer = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        maskLayer.fillColor = UIColor.black.cgColor
        layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        maskLayer.path = UIBezierPath(ovalIn: bounds).cgPath
    }
    
}
