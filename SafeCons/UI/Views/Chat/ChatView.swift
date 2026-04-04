import SwiftUI

struct ChatView: View {
    
    @Bindable var viewModel: ChatViewModel
    var chat: Chat
    
    private var sortedMessages: [Message] {
        chat.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var contactName: String {
        chat.participants.first(where: { !$0.isMe })?.name ?? "safe connection"
    }
    
    private var canSendMessage: Bool {
        !viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.isTunnelActive
    }
    
    var body: some View {
        VStack {
            messagesList
            composerBar
        }
        .navigationTitle(contactName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(contactName)
                        .font(.headline)
                    RadioStatusView(isTunnelActive: viewModel.isTunnelActive)
                }
            }
        }
    }
    
    private var messagesList: some View {
        List {
            ForEach(sortedMessages) { message in
                MessageRow(
                    text: viewModel.decryptMessage(encryptedData: message.content, isEncrypted: message.isEncrypted),
                    isFromCurrentUser: message.sender?.isMe == true
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(.plain)
        .defaultScrollAnchor(.bottom)
    }
    
    private var composerBar: some View {
        HStack(spacing: 12) {
            Text(">")
                .font(.title3)
                .foregroundStyle(.green)
                .bold()
            
            TextField("Send package...", text: $viewModel.newMessage)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .onSubmit {
                    guard canSendMessage else { return }
                    viewModel.saveMessage()
                }
            
            Button {
                viewModel.saveMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(canSendMessage ? .green : .gray)
            }
            .disabled(!canSendMessage)
            .keyboardShortcut(.defaultAction)
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
