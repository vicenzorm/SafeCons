//
//  RootView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//

import SwiftUI

struct RootView: View {
    @Bindable var container: AppContainer
    
    @State private var isChecking: Bool = true
    @State private var hasProfile: Bool = false
    
    var body: some View {
        Group {
            if isChecking {
                ProgressView("Descriptografando acesso...")
            } else if hasProfile {
                MainTabView(container: container)
            } else {
                OnboardingView(viewModel: OnboardingViewModel(userService: container.userService)) {
                    withAnimation {
                        hasProfile = true
                    }
                }
            }
        }
        .task {
            do {
                isChecking = true
                let ownershipStatus = try container.userService.checkDeviceOwnership()
                hasProfile = ownershipStatus
                isChecking = false
            } catch {
                isChecking = false
                print(error)
            }
        }
    }
}

