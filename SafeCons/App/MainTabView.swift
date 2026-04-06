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
                    ContactsView(viewModel: ContactsViewModel(userService: container.userService, cryptoService: container.cryptoService, networkService: container.networkService, messageRepository: container.messageRepository, presenceManager: container.presenceManager))
                }
            }
            
            Tab("Intercom", systemImage: "sensor.tag.radiowaves.forward") {
                NavigationStack {
                    IntercomView(viewModel: IntercomViewModel(requestManager: container.requestManager, connectionOrchestrator: container.connectionOrchestrator))
                }
            }
            .badge(container.requestManager.pendingRequests.count)
            
            Tab("Connect", systemImage: "qrcode.viewfinder") {
                NavigationStack {
                    UserView(viewModel: UserViewModel(userService: container.userService, cryptoService: container.cryptoService, networkService: container.networkService))
                }
            }
        }
        .tint(.accentColor)
    }
}

