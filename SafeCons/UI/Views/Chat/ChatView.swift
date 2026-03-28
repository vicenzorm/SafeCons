import SwiftUI

struct ChatView: View {
    
    @Bindable var viewModel: ChatViewModel
    var chat: Chat
    
    var body: some View {
        VStack {
            List {
                ForEach(chat.messages.sorted { $0.timestamp < $1.timestamp }) { message in
                    HStack {
                        if let sender = message.sender {
                            if sender.isMe {
                                Spacer()
                                
                                Text(viewModel.decryptMessage(message: message, chat: chat))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                    )
                            } else {
                                Text(viewModel.decryptMessage(message: message, chat: chat))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Spacer()
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            .defaultScrollAnchor(.bottom)
            
            HStack(spacing: 12) {
                Text(">")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .bold()
                
                TextField("Transmitir pacote...", text: $viewModel.newMessage)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                
                Button {
                    viewModel.saveMessage(user: chat.participants.first(where: { $0.isMe })!, chat: chat)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            (viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             AppContainer.shared.networkService.radioState != .connected) ? .gray : .green
                        )
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || AppContainer.shared.networkService.radioState != .connected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle(chat.participants.first(where: { !$0.isMe })?.name ?? "Conexão Segura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(chat.participants.first(where: { !$0.isMe })?.name ?? "Contato")
                        .font(.headline)
                    RadioStatusView(state: AppContainer.shared.networkService.radioState)
                }
            }
        }
    }
}
