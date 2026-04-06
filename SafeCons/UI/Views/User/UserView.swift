//
//  UserView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//

import SwiftUI

struct UserView: View {
    
    @Bindable var viewModel: UserViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                
                Text("Transmission Beacon")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Present this terminal to initiate a physical handshake (Out-of-Band).")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 24)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(
                        colors: viewModel.generateColorsForProfile(from: viewModel.userName),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .opacity(0.3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(spacing: 24) {
                    Text(viewModel.userName)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    if let qrCode = viewModel.qrCode {
                        Image(uiImage: qrCode)
                            .resizable()
                            .interpolation(.none)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(width: 220, height: 220)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.green)
                            Text("Creating QRCODE...")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: 220, height: 220)
                    }
                }
                .padding(.vertical, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            
            Button(role: .destructive) {
                viewModel.showResetConfirmation.toggle()
            } label: {
                Label("Factory Reset", systemImage: "flame.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 32)
            .alert("Self-Destruct Protocol", isPresented: $viewModel.showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Purge Terminal", role: .destructive) {
                    viewModel.factoryReset()
                }
            } message: {
                Text("This action will incinerate your P256 Private Key and wipe all radio history from the disk.\n\nDue to local-first encryption, recovering this data will be MATHEMATICALLY IMPOSSIBLE.\n\nDo you wish to proceed?")
            }
            Spacer()
            
        }
        .task {
            viewModel.loadMyProfile()
        }
    }
}

#Preview {
    let container = AppContainer.shared
    UserView(viewModel: UserViewModel(userService: container.userService, cryptoService: container.cryptoService, networkService: container.networkService))
}
