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
    private let networkService: NetworkServiceProtocol
    
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.networkService = networkService
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
        cryptoService
            .generateIdentityColors(from: name)
            .map { color(fromHex: $0) }
    }

    private func color(fromHex hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let rgb = UInt64(sanitized, radix: 16) else {
            return .gray
        }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
    
    func factoryReset() {
        do {
            try userService.nukeDB()
            
            KeychainManager.delete()
            
            networkService.disconnectAllPeers()
            
            fatalError("Terminal Reseted")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
