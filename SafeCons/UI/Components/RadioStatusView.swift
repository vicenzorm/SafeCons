//
//  RadioStatusView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct RadioStatusView: View {
    var isTunnelActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isTunnelActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(isTunnelActive ? "Túnel Estabelecido" : "Rádio Desconectado")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}
