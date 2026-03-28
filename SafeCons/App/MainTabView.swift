//
//  MainTabView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//


import SwiftUI

struct MainTabView: View {
    
    @Bindable var container: AppContainer
    
    var body: some View {
        TabView {
            Tab("Contacts", systemImage: "bubble.left.and.bubble.right.fill") {
                NavigationStack {
                    ContactsView(viewModel: ContactsViewModel(userService: container.userService))
                }
            }
            
            Tab("Intercom", systemImage: "sensor.tag.radiowaves.forward") {
                NavigationStack {
                    IntercomView()
                }
            }
            .badge(container.requestManager.pendingRequests.count)
            
            Tab("Connect", systemImage: "qrcode.viewfinder") {
                NavigationStack {
                    UserView(viewModel: UserViewModel(userService: container.userService))
                }
            }
        }
        .tint(.accentColor)
    }
}

