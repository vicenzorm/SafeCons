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
        VStack(spacing: 32) {
            
            VStack {

                Image(systemName: "key.viewfinder")
                
                Text("SafeCons")
                
                Text("Bem-vindo(a)! Gere suas chaves para iniciar o app")
                
            }
            .padding(.horizontal)
            if !viewModel.isCreatingProfile {
            
                VStack {
                    
                    TextField("Como quer ser chamado?", text: $viewModel.userName)
                        .autocorrectionDisabled()
                        .disabled(viewModel.isCreatingProfile)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(Color(.systemGray6))
                        )
                }
                .padding(.horizontal)
                
            } else {
                ProgressView()
            }
            
            Button {
                viewModel.createProfile {
                    
                    onProfileCreated()
                }
            } label: {
                Text("Criar conta")
            }
            .disabled(viewModel.userName.isEmpty || viewModel.isCreatingProfile)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
            
            Spacer()
            
        }
    }
    
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(userService: AppContainer.shared.userService)) {
        
    }
}
