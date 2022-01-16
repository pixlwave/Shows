import SwiftUI

struct SearchView: View {
    @State var searchQuery = ""
    @State var searchTask: Task<(), Error>?
    
    @State var results = [YTSearchResult]()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 20) {
                ForEach(results) { result in
                    SearchCell(result: result)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchQuery)
        .onChange(of: searchQuery, perform: search)
    }
    
    func search(_ query: String) {
        #warning("This request should be debounced.")
        if let task = searchTask {
            task.cancel()
            searchTask = nil
        }
        
        Task {
            let results = try await YouTube.shared.search(for: query)
            guard !Task.isCancelled else { return }
            self.results = results
        }
    }
}

struct SearchCell: View {
    let result: YTSearchResult
    
    var body: some View {
        HStack {
            AsyncImage(url: result.thumbnailURL) { image in
                image.resizable()
            } placeholder: {
                Image("channel").resizable()
            }
            .aspectRatio(1, contentMode: .fit)
            .mask(Circle())
            .padding(.trailing)
            
            VStack(alignment: .leading) {
                Text(result.name)
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
