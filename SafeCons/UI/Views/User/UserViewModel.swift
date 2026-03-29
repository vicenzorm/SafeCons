//
//  UserViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins
import CryptoKit

@MainActor
protocol UserViewModelProtocol {
    var userName: String { get }
    var qrCode: UIImage? { get }
    var errorMessage: String? { get }
    
    var showResetConfirmation: Bool { get set }
    
    func loadMyProfile()
    func generateColorsForProfile(from name: String) -> [Color]
    func factoryReset()
}

@Observable
@MainActor
final class UserViewModel: UserViewModelProtocol {
    var userName: String = ""
    var qrCode: UIImage?
    var errorMessage: String?
    var showResetConfirmation: Bool = false
    
    private let userService: UserServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
    }
    
    func loadMyProfile() {
        do {
            let user =  try userService.fetchOwnUserData()
            self.userName = user.name
            
            let qrPayload = QRCodePayload(name: user.name, publicKey: user.publicKey)
            
            let jsonData = try JSONEncoder().encode(qrPayload)
            
            self.qrCode = generateQRCode(data: jsonData)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func generateQRCode(data: Data) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.setValue(data, forKey: "inputMessage")
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func generateColorsForProfile(from name: String) -> [Color] {
        cryptoService.generateIdentityColors(from: name)
    }
    
    func factoryReset() {
        do {
            try userService.nukeDB()
            
            KeychainManager.delete()
            
            AppContainer.shared.networkService.disconnectAllPeers()
            
            fatalError("Terminal Reseted")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
