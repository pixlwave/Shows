import SwiftUI

struct SearchView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 20) {
                SearchCell()
                SearchCell()
                SearchCell()
                SearchCell()
                SearchCell()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchCell: View {
    var body: some View {
        HStack {
            Image("channel")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .mask(Circle())
                .padding(.trailing)
            
            VStack(alignment: .leading) {
                Text("Channel Title")
                    .font(.headline)
                Text("Subscribe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 80)
    }
}


struct SeachView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchView()
        }
    }
}
