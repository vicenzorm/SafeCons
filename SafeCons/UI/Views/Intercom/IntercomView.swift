//
//  IntercomView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct IntercomView: View {
    @Bindable var viewModel: IntercomViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.requestManager.pendingRequests.isEmpty {
                    emptyIntercomView
                } else {
                    requestsScrollView
                }
            }
            .navigationTitle("Intercom")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyIntercomView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("Radio is silent.")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("No pending connection requests in this perimeter.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var requestsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.requestManager.pendingRequests) { request in
                    requestCard(for: request)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    private func requestCard(for request: ConnectionRequest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(request.senderName) is knocking")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Handshake detected at \(request.timeStamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "key.viewfinder")
                    .foregroundStyle(.green)
                    .font(.title3)
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    viewModel.reject(request)
                } label: {
                    Text("Block")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    Task {
                        await viewModel.accept(request)
                    }
                } label: {
                    Text("Accept Handshake")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
