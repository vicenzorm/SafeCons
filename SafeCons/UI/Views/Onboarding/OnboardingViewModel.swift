//
//  OnboardingViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation
import Observation

@MainActor
protocol OnboardingViewModelProtocol {
    var userName: String { get set }
    var isCreatingProfile: Bool { get }
    var errorMessage: String? { get }
    
    func createProfile(onSuccess: @escaping () -> Void)
}

@MainActor
@Observable
class OnboardingViewModel: OnboardingViewModelProtocol {
    
    private let userService: UserServiceProtocol
    
    var userName: String = ""
    var isCreatingProfile: Bool = false
    var errorMessage: String? = nil
    
    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    func createProfile(onSuccess: @escaping () -> Void) {
        isCreatingProfile = true
        Task {
            do {
                let profile = try await userService.createOwnProfile(name: userName)
                print("\(profile.name) criado")
                isCreatingProfile = false
                onSuccess()
            } catch {
                isCreatingProfile = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
}
