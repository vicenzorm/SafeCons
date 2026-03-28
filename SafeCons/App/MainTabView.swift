//
//  MainTabView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//


import SwiftUI

struct MainTabView: View {
    
    let container = AppContainer.shared
    
    var body: some View {
        TabView {
            Tab("Contacts", systemImage: "bubble.left.and.bubble.right.fill") {
                NavigationStack {
                    ContactsView(viewModel: ContactsViewModel(userService: container.userService))
                }
            }
            
            Tab("Connect", systemImage: "qrcode.viewfinder") {
                NavigationStack {
                    UserView(viewModel: UserViewModel(userService: container.userService))
                }
            }
        }
        .tint(.accentColor) 
    }
}

#Preview {
    MainTabView()
}
