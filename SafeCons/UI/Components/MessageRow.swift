//
//  MessageRow.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct MessageRow: View {
    let text: String
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                Text(text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            } else {
                Text(text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                Spacer()
            }
        }
    }
}

