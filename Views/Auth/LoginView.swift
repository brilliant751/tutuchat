import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @FocusState private var focusedField: Field?

    private let actionColor = Color(red: 7/255, green: 193/255, blue: 96/255) // 微信绿

    private enum Field {
        case username, password
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("登录微信")
                        .font(.largeTitle.bold())
                    Text("使用微信号 / 邮箱 / 手机号登录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                VStack(spacing: 1) {
                    inputRow(
                        systemImage: "person.fill",
                        placeholder: "请输入账号",
                        text: $authVM.username,
                        focused: .username,
                        showsDivider: true
                    )
                    inputRow(
                        systemImage: "lock.fill",
                        placeholder: "请输入密码",
                        text: $authVM.password,
                        focused: .password,
                        isSecure: true,
                        showsDivider: false
                    )
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                if let error = authVM.errorMessage, !error.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.orange)
                            .font(.footnote)
                    }
                }

                Button(action: {
                    Task { await authVM.login() }
                }) {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(authVM.isLoading ? "正在登录..." : "登录")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(actionColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authVM.isLoading)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func inputRow(
        systemImage: String,
        placeholder: String,
        text: Binding<String>,
        focused: Field,
        isSecure: Bool = false,
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                if isSecure {
                    SecureField(placeholder, text: text)
                        .textContentType(.password)
                        .focused($focusedField, equals: focused)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: focused)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            if showsDivider {
                Divider()
                    .padding(.leading, 44)
            }
        }
    }
}
