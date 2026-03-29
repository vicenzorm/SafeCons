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
            contentView
                .navigationTitle("Conexões")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.isShowingCamera.toggle()
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundStyle(.green)
                        }
                    }
                }
        }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            scannerSheet
        }
        .alert("Alerta de Rádio", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorText = viewModel.errorMessage {
                Text(errorText)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if contacts.isEmpty {
            emptyStateView
        } else {
            contactsListView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("Nenhum túnel ativo.")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Escaneie o terminal de um contato para estabelecer um handshake físico.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var contactsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(contactsWithChat, id: \.contact.id) { item in
                    NavigationLink {
                        ChatView(
                            viewModel: ChatViewModel(
                                cryptoService: AppContainer.shared.cryptoService,
                                networkService: AppContainer.shared.networkService,
                                chat: item.chat
                            ),
                            chat: item.chat
                        )
                    } label: {
                        ContactCardView(
                            contact: item.contact,
                            colors: viewModel.generateCardColors(name: item.contact.name),
                            isOnline: viewModel.isPeerConnected(publicKey: item.contact.publicKey)
                        )
                    }
                    .buttonStyle(.plain)
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

    private var contactsWithChat: [(contact: User, chat: Chat)] {
        contacts.compactMap { contact in
            guard let chat = firstChatWithCurrentUser(for: contact) else {
                return nil
            }
            return (contact: contact, chat: chat)
        }
    }

    private var scannerSheet: some View {
        QRScannerView { scannedString in
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

    private func firstChatWithCurrentUser(for contact: User) -> Chat? {
        contact.chats.first { chat in
            chat.participants.contains { participant in
                participant.isMe
            }
        }
    }
}
