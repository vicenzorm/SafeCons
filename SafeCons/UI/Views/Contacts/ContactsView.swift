//
//  ContactsView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import SwiftData
import SwiftUI

struct ContactsView: View {
    @Query(filter: #Predicate<User> { $0.isMe == false }, sort: \.name) private var contacts: [User]
    @Bindable var viewModel: ContactsViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    EmptyRadarView()
                } else {
                    contactsList
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { viewModel.isShowingCamera.toggle() } label: {
                        Image(systemName: "qrcode.viewfinder").foregroundStyle(.green)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCamera) { scannerSheet }
        .alert("Radio alert", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorText = viewModel.errorMessage { Text(errorText) }
        }
    }
    
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(contacts) { contact in
                    if let chat = contact.activeChat {
                        NavigationLink {
                            ChatView(viewModel: viewModel.makeChatViewModel(chat: chat), chat: chat)
                        } label: {
                            ContactCardView(
                                contact: contact,
                                colors: viewModel.generateCardColors(name: contact.name),
                                isOnline: viewModel.isPeerConnected(publicKey: contact.publicKey)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeContact(contact: contact)
                            } label: {
                                Label("Delete Contact", systemImage: "trash.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            print("Central Terminal: Manual radar sweep initiated by user.")
            viewModel.refreshScan()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    
    private var scannerSheet: some View {
        QRScannerView { scannedString in
            viewModel.isShowingCamera.toggle()
            Task {
                try? await viewModel.addContact(scannedCode: scannedString)
            }
        }
        .presentationDetents([.large])
        .navigationTitle("Connection Scan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
