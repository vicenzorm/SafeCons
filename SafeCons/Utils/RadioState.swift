//
//  RadioState.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

enum RadioState: String {
    case offline = "Rádio Desconectado"
    case scanning = "Escaneando o ar..."
    case discovering = "Negociando chaves..."
    case connected = "Túnel Estabelecido"
    
    var color: Color {
        switch self {
        case .offline: return .red
        case .scanning: return .gray
        case .discovering: return .yellow
        case .connected: return .green
        }
    }
}
