import SwiftUI

struct ShowView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 275))]) {
                VidCell()
                VidCell()
                VidCell()
                VidCell()
                VidCell()
            }
            .padding(8)
        }
        .navigationBarTitle("Show", displayMode: .inline)
    }
}

struct VidCell: View {
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
                        .opacity(0.75),
                    alignment: .bottom
                )
            VStack(alignment: .leading) {
                Text("Video Name")
                Spacer()
                Text("12 hours ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 85)
    }
}

struct ShowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShowView()
        }
    }
}
