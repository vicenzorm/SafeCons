//
//  UserService.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//

import Foundation
import SwiftData

@MainActor
protocol UserServiceProtocol {
    func checkDeviceOwnership() throws -> Bool
    func createOwnProfile(name: String) async throws -> User
    func createContact(name: String, publicKey: Data) async throws -> User
    func fetchOwnUserData() throws -> User
    func fetchContact(publicKey: Data) throws-> User?
    func deleteContact(publicKey: Data) throws
    func nukeDB() throws
}

@MainActor
final class UserService: UserServiceProtocol {
    
    private let modelContext: ModelContext
    private let cryptoService: CryptoServiceProtocol
    
    init(modelContext: ModelContext, cryptoService: CryptoServiceProtocol) {
        self.modelContext = modelContext
        self.cryptoService = cryptoService
    }
    
    func checkDeviceOwnership() throws -> Bool {
        let predicate = #Predicate<User> { $0.isMe == true }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            throw error
        }
    }
    
    func createOwnProfile(name: String) async throws -> User {
        let (publicKey, _) = try cryptoService.generateKeyPair()
        let newUser = User(name: name.trimmingCharacters(in: .whitespacesAndNewlines), publicKey: publicKey, isMe: true)
        modelContext.insert(newUser)
        try modelContext.save()
        return newUser
    }
    
    func createContact(name: String, publicKey: Data) async throws -> User {
        let newContact = User(name: name, publicKey: publicKey, isMe: false)
        let ownUser = try self.fetchOwnUserData()
        let newChat = Chat()
        newChat.participants.append(contentsOf:[ownUser, newContact])
        
        modelContext.insert(newContact)
        modelContext.insert(newChat)
        
        try modelContext.save()
        return newContact
    }
    
    func fetchOwnUserData() throws -> User {
        let predicate = #Predicate<User> { $0.isMe == true }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let user = try modelContext.fetch(descriptor).first
            guard let user else { fatalError("No user found") }
            return user
        } catch {
            throw error
        }
    }
    
    func fetchContact(publicKey: Data) throws -> User? {
        let predicate = #Predicate<User> { $0.publicKey == publicKey }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    func deleteContact(publicKey: Data) throws {
        let predicate = #Predicate<User> { $0.publicKey == publicKey }
        let descriptor = FetchDescriptor(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        guard let userToDelete = results.first else { return }
        modelContext.delete(userToDelete)
        try modelContext.save()
    }
    
    func nukeDB() throws {
        let allChats = try modelContext.fetch(FetchDescriptor<Chat>())
        
        for chat in allChats {
            chat.participants.removeAll()
            modelContext.delete(chat)
        }
        
        let allMessages = try modelContext.fetch(FetchDescriptor<Message>())
        for msg in allMessages {
            modelContext.delete(msg)
        }
        
        let allUsers = try modelContext.fetch(FetchDescriptor<User>())
        for user in allUsers {
            modelContext.delete(user)
        }
        try modelContext.save()
    }
}
