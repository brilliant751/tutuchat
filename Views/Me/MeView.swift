import SwiftUI

struct MeView: View {
    @StateObject private var vm = MeViewModel()
    @EnvironmentObject private var authVM: AuthViewModel

    private var nickname: String {
        authVM.session?.username ?? vm.nickname
    }

    private var wechatId: String {
        authVM.session?.username ?? vm.wechatId
    }

    var body: some View {
        NavigationStack {
            List {
                // 资料卡
                Section {
                    HStack(spacing: 12) {
                        Circle().fill(Color.gray.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(Text(String(nickname.prefix(1))).font(.title2))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nickname).font(.headline)
                            Text("微信号：\(wechatId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { /* 预留：个人资料编辑页 */ }
                    .padding(.vertical, 4)
                }

                // 菜单
                Section {
                    ForEach(vm.menus) { item in
                        NavigationLink(value: item.dest) {
                            HStack(spacing: 12) {
                                Image(systemName: item.sfSymbol)
                                    .frame(width: 24)
                                    .foregroundColor(.accentColor)
                                Text(item.title)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }

                if authVM.isSignedIn {
                    Section {
                        Button(role: .destructive) {
                            authVM.logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("退出登录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我")
            // 目的地
            .navigationDestination(for: MeViewModel.MenuItem.Dest.self) { dest in
                switch dest {
                case .album:    AlbumView()
                case .pay:      PayView()
                case .settings: SettingsView()
                case .about:    AboutView()
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 500)
        #endif
    }
}
