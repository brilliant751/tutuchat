import SwiftUI

struct MainTabView: View {
    @StateObject private var chatsVM = ChatsViewModel()
    
    var body: some View {
        TabView {
            ChatsView()
                .environmentObject(chatsVM)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("微信")
                }
                .badge(chatsVM.totalUnread)

            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("通讯录")
                }

            DiscoverView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("发现")
                }

            MeView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("我")
                }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }
}


