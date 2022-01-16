import SwiftUI

struct VideoPlayer: UIViewControllerRepresentable {
    let video: Video
    
    func makeUIViewController(context: Context) -> PlayerController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PlayerController") as! PlayerController
        controller.video = video
        return controller
    }
    
    func updateUIViewController(_ uiView: PlayerController, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator { }
}
