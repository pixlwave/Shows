import SwiftUI

struct SubscriptionsView: View {
    @ObservedObject var youtube = YouTube.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                    ForEach(youtube.subscriptions) { channel in
                        ChannelCell(channel: channel)
                    }
                }
                .refreshable { try? await youtube.reload() }
                .padding(8)
            }
            .navigationTitle("Shows")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct ChannelCell: View {
    let channel: Channel
    
    var body: some View {
        NavigationLink(destination: ShowView(channel: channel)) {
            VStack {
                AsyncImage(url: channel.thumbnailURL) { image in
                    image.resizable()
                } placeholder: {
                    Image("channel").resizable()

                }
                .aspectRatio(1, contentMode: .fit)
                .mask(Circle())
                .padding(.horizontal, 5)
                
                Text(channel.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.bottom)
            }
        }
    }
}

struct SubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionsView()
    }
}
