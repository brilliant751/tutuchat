import SwiftUI
import Combine

struct ContactsView: View {
    @StateObject private var vm = ContactsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // 顶部 4 个入口
                Section {
                    ForEach(vm.shortcuts, id: \.self) { item in
                        NavigationLink(item) {
                            ShortcutDetailView(title: item)
                        }
                    }
                }

                // 好友列表
                Section("联系人") {
                    ForEach(vm.contacts) { c in
                        NavigationLink(value: c.id) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.gray.opacity(0.2))
                                    Text(String(c.name.prefix(1)))
                                        .font(.system(size: 18, weight: .medium))
                                }
                                .frame(width: 44, height: 44)

                                Text(c.name)
                                    .font(.system(size: 16))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("通讯录")
            .navigationDestination(for: String.self) { cid in
                // 二级页面（联系人详情占位）
                ContactDetailView(contact:
                    vm.contacts.first(where: { $0.id == cid })!
                )
            }
        }
    }
}

// 占位：顶级 4 个入口的二级页
struct ShortcutDetailView: View {
    let title: String
    var body: some View {
        Text("\(title)（占位页）")
            .font(.title3)
            .padding()
            .navigationTitle(title)
    }
}

// 占位：联系人详情
struct ContactDetailView: View {
    let contact: Contact
    var body: some View {
        VStack(spacing: 16) {
            Circle().fill(Color.gray.opacity(0.2))
                .frame(width: 72, height: 72)
                .overlay(Text(String(contact.name.prefix(1))).font(.title2))
            Text(contact.name).font(.title3)
            Spacer()
        }
        .padding()
        .navigationTitle("个人信息")
    }
}
