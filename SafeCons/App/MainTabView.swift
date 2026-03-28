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
            
            Tab("Connect", systemImage: "qrcode.viewfinder") {
                NavigationStack {
                    UserView(viewModel: UserViewModel(userService: container.userService))
                }
            }
        }
        .tint(.accentColor)
        .alert("Tentativa de Conexão", isPresented: $container.requestManager.isShowingRequest) {
            
            Button("Recusar", role: .cancel) {
                container.requestManager.clear()
            }
            
            Button("Aceitar") {
                Task {
                    await container.acceptPendingConnection()
                }
            }
            
        } message: {
            Text("Um dispositivo com criptografia válida está tentando estabelecer uma conexão segura e te enviou uma mensagem. Deseja aceitar?")
        }
    }
}

