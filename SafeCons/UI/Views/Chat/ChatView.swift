import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    var chat: Chat

    private var sortedMessages: [Message] {
        chat.messages.sorted { $0.timestamp < $1.timestamp }
    }

    private var otherParticipantName: String {
        chat.participants.first(where: { !$0.isMe })?.name ?? "Conexão Segura"
    }

    private var canSendMessage: Bool {
        !viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.isTunnelActive
    }

    var body: some View {
        VStack {
            messageList
            composerView
        }
        .navigationTitle(otherParticipantName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(otherParticipantName)
                        .font(.headline)
                    RadioStatusView(isTunnelActive: viewModel.isTunnelActive)
                }
            }
        }
    }

    private var messageList: some View {
        List {
            ForEach(sortedMessages) { message in
                messageRow(for: message)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(.plain)
        .defaultScrollAnchor(.bottom)
    }

    private func messageRow(for message: Message) -> some View {
        HStack {
            if let sender = message.sender {
                if sender.isMe {
                    Spacer()
                    messageBubble(for: message, isMine: true)
                } else {
                    messageBubble(for: message, isMine: false)
                    Spacer()
                }
            }
        }
    }

    private func messageBubble(for message: Message, isMine: Bool) -> some View {
        Text(viewModel.decryptMessage(message: message, chat: chat))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isMine ? Color.green.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isMine ? .green : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMine ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }

    private var composerView: some View {
        HStack(spacing: 12) {
            Text(">")
                .font(.title3)
                .foregroundStyle(.green)
                .bold()

            TextField("Transmitir pacote...", text: $viewModel.newMessage)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)

            Button {
                if let me = chat.participants.first(where: { $0.isMe }) {
                    viewModel.saveMessage(user: me, chat: chat)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(canSendMessage ? .green : .gray)
            }
            .disabled(!canSendMessage)
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
}
