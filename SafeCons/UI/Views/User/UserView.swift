//
//  UserView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import SwiftUI

struct UserView: View {
    
    var viewModel: UserViewModel
    
    var body: some View {
        VStack {
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
            
            Text(viewModel.userName)
            
            if let qrCode = viewModel.qrCode {
                
                Image(uiImage: qrCode)
                    .resizable()
                    .interpolation(.none)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(width: 250, height: 250)
                
            } else {
                ProgressView("Loading QRCODE...")
            }
        }
        .task {
            viewModel.loadMyProfile()
        }
    }
}
