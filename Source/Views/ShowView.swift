import SwiftUI

struct ShowView: View {
    let channel: Channel
    
    @State private var playingVideo: Video?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 275))]) {
                ForEach(channel.playlist) { video in
                    Button { playingVideo = video } label: {
                        VideoCell(video: video)
                    }
                    .buttonStyle(.plain)
                }
            }
            .refreshable { try? await channel.reloadPlaylistItems() }
            .padding(8)
        }
        .navigationBarTitle("Show", displayMode: .inline)
        .fullScreenCover(item: $playingVideo) {
            // update the cell?
        } content: { video in
            NavigationView {
                VideoPlayer(video: video)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { playingVideo = nil } label: {
                                Image(systemName: "xmark")
                            }
                        }
                        
                        ToolbarItem(placement: .primaryAction) {
                            Button { share(video) } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
            }
            .environment(\.colorScheme, .dark)
        }
    }
    
    func share(_ video: Video) {
        guard
            let viewController = UIApplication.shared.windows.last?.rootViewController,
            let shareURL = URL(string: "https://youtu.be/\(video.id)")
        else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        viewController.present(shareSheet, animated: true)
    }
}

struct VideoCell: View {
    @ObservedObject var video: Video
    
    var body: some View {
        HStack {
            AsyncImage(url: video.thumbnailURL) { image in
                image.resizable()
            } placeholder: {
                Image("video").resizable()
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay(
                Text("Watched")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .opacity(video.watched ? 0.75 : 0.0),
                alignment: .bottom
            )
            
            VStack(alignment: .leading) {
                Text(video.title)
                    .lineLimit(3)
                Spacer()
                Text("12 hours ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 87)
    }
}


//struct ShowView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ShowView(channel: Channel(item: YTChannelItem())
//        }
//    }
//}
