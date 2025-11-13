import SwiftUI

struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("朋友圈") {
                    MomentsView()
                }
            }
            .navigationTitle("发现")
        }
    }
}
