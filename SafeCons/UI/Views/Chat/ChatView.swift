    //
    //  ChatView.swift
    //  SafeCons
    //
    //  Created by Vicenzo Másera on 27/03/26.
    //
import SwiftUI

struct ChatView: View {
    
    @Bindable var viewModel: ChatViewModel
    var chat: Chat
    
    var body: some View {
        VStack{
            List {
                ForEach(chat.messages) { message in
                    HStack {
                        if let sender = message.sender {
                            if sender.isMe {
                                Spacer()
                                
                                Text(viewModel.decryptMessage(message: message, chat: chat))
                            } else {
                                Text(viewModel.decryptMessage(message: message, chat: chat))
                                
                                Spacer()
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(.plain)
            
            HStack {
                TextField("New message", text: $viewModel.newMessage)
                    .autocorrectionDisabled()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(Color(.systemGray6))
                    )
                Button {
                    viewModel.saveMessage(user: chat.participants.first(where: { $0.isMe })!, chat: chat)
                } label: {
                    Image(systemName: "paperplane")
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(chat.participants.first(where: { !$0.isMe })?.name ?? "Safe connection")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}
