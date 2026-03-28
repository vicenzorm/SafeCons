    //
    //  ChatsView.swift
    //  SafeCons
    //
    //  Created by Vicenzo Másera on 27/03/26.
    //

import SwiftData
import SwiftUI

struct ContactsView: View {
    
    @Query(filter: #Predicate<User> { $0.isMe == false }, sort: \.name) var contacts: [User]
    
    @Bindable var viewModel: ContactsViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        
                        Text("Nenhuma conexão segura.")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                } else {
                    List {
                        ForEach(contacts) { contact in
                            Text(contact.name)
                                .onTapGesture {
                                    print("indo para o \(contact.name)")
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCamera.toggle()
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingCamera) {
                QRScannerView() { scannedString in
                    viewModel.isShowingCamera.toggle()
                    Task {
                        do {
                            try await viewModel.addContact(scannedCode: scannedString)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
                .presentationDetents([.large])
                .navigationTitle("Connection Scan")
                .navigationBarTitleDisplayMode(.inline)
            }
            .alert("Alerta", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorText = viewModel.errorMessage {
                    Text(errorText)
                }
            }
        }
    }
}

