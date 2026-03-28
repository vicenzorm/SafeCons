//
//  Persistence.swift
//  SwiftStoreApp
//
//  Created by Vicenzo Másera on 26/08/25.
//

import SwiftUI
import SwiftData

@MainActor
class AppContainer {
    
    static var shared = AppContainer()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    let userService: UserServiceProtocol
    let cryptoService: CryptoServiceProtocol
    
    
    private init() {
        self.modelContainer = try! ModelContainer(for: User.self , Message.self , Chat.self)
        self.modelContext = modelContainer.mainContext
        
        let crypto = CryptoService()
        self.cryptoService = crypto
        
        self.userService = UserService(modelContext: modelContext, cryptoService: crypto)
    }
}
