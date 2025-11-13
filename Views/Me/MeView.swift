import SwiftUI

struct MeView: View {
    @StateObject private var vm = MeViewModel()

    var body: some View {
        NavigationStack {
            List {
                // 资料卡
                Section {
                    HStack(spacing: 12) {
                        Circle().fill(Color.gray.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(Text(String(vm.nickname.prefix(1))).font(.title2))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.nickname).font(.headline)
                            Text("微信号：\(vm.wechatId)")
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
