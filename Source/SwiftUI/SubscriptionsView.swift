import SwiftUI

struct SubscriptionsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                    ChannelCell()
                    ChannelCell()
                    ChannelCell()
                    ChannelCell()
                    ChannelCell()
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
    var body: some View {
        NavigationLink(destination: ShowView()) {
            VStack {
                Image("channel")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .mask(Circle())
                    .padding(.horizontal, 5)
                Text("Channel")
                    .font(.caption2)
                    .foregroundColor(.primary)
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
