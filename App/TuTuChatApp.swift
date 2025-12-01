//
//  TuTuChatApp.swift
//  TuTuChat
//
//  Created by brilliant751 on 2025/11/12.
//

import SwiftUI

@main
struct TuTuChatApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        if authVM.isSignedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
