//
//  IntercomView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct IntercomView: View {
    let container = AppContainer.shared
    
    var body: some View {
        NavigationStack {
            List {
                if container.requestManager.pendingRequests.isEmpty {
                    Text("O rádio está silencioso. Nenhuma conexão pendente.")
                        .foregroundStyle(.gray)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(container.requestManager.pendingRequests) { request in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(request.senderName) quer se conectar")
                                .font(.headline)
                            
                            Text("Bateu na porta às \(request.timeStamp.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            
                            HStack {
                                Button(role: .destructive) {
                                    container.rejectConnection(request)
                                } label: {
                                    Label("Bloquear", systemImage: "nosign")
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button {
                                    Task {
                                        await container.acceptConnection(request)
                                    }
                                } label: {
                                    Label("Aceitar", systemImage: "key.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Interfone")
        }
    }
}
