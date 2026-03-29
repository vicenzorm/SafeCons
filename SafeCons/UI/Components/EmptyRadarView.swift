//
//  EmptyRadarView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct EmptyRadarView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("No active tunnels")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Scan a contact's terminal to establish a physical handshake.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
