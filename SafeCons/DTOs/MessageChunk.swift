//
//  MessageChunk.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import Foundation

struct MessageChunk: Codable {
    let messageID: UUID
    let chunkIndex: Int
    let totalChunks: Int
    let partialContent: Data
}
