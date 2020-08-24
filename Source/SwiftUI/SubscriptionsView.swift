import SwiftUI

struct SubscriptionsView: View {
    @ObservedObject var invidious = Invidious.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                    ForEach(invidious.subscriptions) { channel in
                        ChannelCell(channel: channel)
                    }
                }
                .padding(8)
            }
            .navigationTitle("Shows")
            .navigationBarItems(trailing: NavigationLink(destination: SearchView()) {
                Image(systemName: "plus")
            })
        }
    }
}

struct ChannelCell: View {
    let channel: Channel
    
    var body: some View {
        NavigationLink(destination: ShowView(channel: channel)) {
            VStack {
                Image("channel")
                    .resizable()
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
