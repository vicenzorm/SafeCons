//
//  UserViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

@MainActor
protocol UserViewModelProtocol {
    var userName: String { get }
    var qrCode: UIImage? { get }
    var errorMessage: String? { get }
    
    func loadMyProfile()
}

@Observable
@MainActor
final class UserViewModel: UserViewModelProtocol {
    var userName: String = ""
    var qrCode: UIImage?
    var errorMessage: String?
    
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol) {
        self.userService = userService
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
    
}
