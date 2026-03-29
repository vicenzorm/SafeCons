//
//  ContactCardView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//

import SwiftUI

struct ContactCardView: View {
    let contact: User
    let colors: [Color]
    let isOnline: Bool
    
    init(contact: User, colors: [Color], isOnline: Bool) {
        self.contact = contact
        self.colors = colors
        self.isOnline = isOnline
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color(UIColor.systemGray6), lineWidth: 3)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
