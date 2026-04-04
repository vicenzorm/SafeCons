import Foundation
@testable import SafeCons

final class MockMessageRepository: MessageRepositoryProtocol {
    struct StoredMessage: Equatable {
        let senderId: UUID
        let chatId: UUID
        let content: Data
        let isEncrypted: Bool
    }

    private(set) var receivedMessages: [StoredMessage] = []

    func saveMessage(senderId: UUID, chatId: UUID, content: Data, isEncrypted: Bool) throws {
        let message = StoredMessage(
            senderId: senderId,
            chatId: chatId,
            content: content,
            isEncrypted: isEncrypted
        )
        receivedMessages.append(message)
    }

    func reset() {
        receivedMessages.removeAll()
    }
}
