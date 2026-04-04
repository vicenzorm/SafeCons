//
//  MessageRepository.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation

protocol MessageRepositoryProtocol {
    func saveMessage(senderId: UUID, chatId: UUID, content: Data, isEncrypted: Bool) throws
}
