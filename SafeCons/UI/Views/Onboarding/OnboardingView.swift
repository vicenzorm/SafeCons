//
//  OnboardingView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//

import SwiftUI

struct OnboardingView: View {
    
    @Bindable var viewModel: OnboardingViewModel
    var onProfileCreated: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "key.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SafeCons Terminal")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text("Welcome. The app operates 100% offline.\nTo forge your cryptographic keys (P256) inside the Secure Enclave, enter your designated callsign below:")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Spacer()
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
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            HStack(spacing: 12) {
                Text(">")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .bold()
                
                if viewModel.isCreatingProfile {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Radio callsign", text: $viewModel.userName)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .disabled(viewModel.isCreatingProfile)
                        .onSubmit {
                            guard viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCreatingProfile else { return }
                            onProfileCreated()
                        }
                }
                
                Button {
                    viewModel.createProfile {
                        onProfileCreated()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            (viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             viewModel.isCreatingProfile) ? .gray : .green
                        )
                }
                .disabled(viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCreatingProfile)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(userService: AppContainer.shared.userService)) {
        print("Perfil gerado.")
    }
}
