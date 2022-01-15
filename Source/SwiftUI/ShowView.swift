import SwiftUI

struct ShowView: View {
    let channel: Channel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 275))]) {
                ForEach(channel.playlist) { video in
                    VideoCellUI(video: video)
                }
            }
            .padding(8)
        }
        .navigationBarTitle("Show", displayMode: .inline)
    }
}

struct VideoCellUI: View {
    let video: Video
    
    var body: some View {
        HStack {
            Image("video")
                .resizable()
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
