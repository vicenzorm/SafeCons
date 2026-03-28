//
//  PrivacySnapshotModifier.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//


import SwiftUI

struct PrivacySnapshotModifier: ViewModifier {
    @State private var shouldObscure = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if shouldObscure {
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 60))
                                .foregroundStyle(.green)
                        }
                    )
            }
        }
        .onAppear {
            setupLifecycleListeners()
        }
    }
    
    private func setupLifecycleListeners() {
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeInOut) {
                shouldObscure = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeInOut) {
                shouldObscure = false
            }
        }
    }
}

