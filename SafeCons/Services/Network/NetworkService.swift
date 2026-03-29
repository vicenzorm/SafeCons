//
//  NetworkService.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//

import Foundation
import CoreBluetooth
import UIKit

@MainActor
protocol NetworkServiceProtocol {
    var connectedPeers: [UUID: CBPeripheral] { get }
    var radioState: RadioState { get }
    
    func startScanning()
    func startListening(onMessageReceived: @escaping (Data) -> Void)
    func send(payload: Data)
    func receive(payload: Data)
    
    func disconnect(peerID: UUID)
    func disconnectAllPeers()
}

@Observable
@MainActor
final class NetworkService: NSObject, NetworkServiceProtocol {
    
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    static let serviceUUID = CBUUID(string: "BC229754-7DDC-4B28-818F-325CECE2F170")
    static let rxCharacteristicUUID = CBUUID(string: "5BAC5A94-EE69-49D9-8D46-8F5A85B8AA42")
    
    var discoveredPeripherals: [CBPeripheral] = []
    var radioState: RadioState = .offline
    
    var peerCharacteristics: [UUID: CBCharacteristic] = [:]
    var connectedPeers: [UUID: CBPeripheral] = [:]
    
    private var incomingChunks: [UUID: [MessageChunk]] = [:]
    
    private var messageCallback: ((Data) -> Void)?
    
    override init() {
        super.init()
        
        let centralOptions: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: "SafeConsCentralRestoreID"
        ]
        let peripheralOptions: [String: Any] = [
            CBPeripheralManagerOptionRestoreIdentifierKey: "SafeConsPeripheralRestoreID"
        ]
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            self.radioState = .scanning
            print("Central Terminal: Starting scan for service \(NetworkService.serviceUUID)...")
            centralManager.scanForPeripherals(withServices: [NetworkService.serviceUUID], options: nil)
        } else {
            print("Central Terminal: Cannot scan. Bluetooth is not powered on (State: \(centralManager.state.rawValue)).")
        }
    }
    
    func startListening(onMessageReceived: @escaping (Data) -> Void) {
        print("NetworkService: Attached message listener callback.")
        self.messageCallback = onMessageReceived
    }
    
    func send(payload: Data) {
        print("NetworkService: Preparing to send payload of \(payload.count) bytes.")
        
        if connectedPeers.isEmpty {
            print("NetworkService [WARNING]: Send aborted. No connected peers available.")
            return
        }
        
        for targetID in connectedPeers.keys {
            guard let peripheral = connectedPeers[targetID] else { continue }
            
            let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
            let safeChunkSize = max(20, Int(Double(mtu) * 0.3)) // Mantendo 30% do limite por segurança
            
            print("NetworkService: Peripheral \(targetID) MTU is \(mtu). Safe chunk size calculated as \(safeChunkSize) bytes.")
            
            let chunks = splitIntoChunks(fullData: payload, chunkSize: safeChunkSize)
            print("NetworkService: Payload split into \(chunks.count) chunks.")
            
            for chunk in chunks {
                sendChunk(chunk: chunk, targetID: targetID)
            }
        }
    }
    
    private func splitIntoChunks(fullData: Data, chunkSize: Int) -> [MessageChunk] {
        let messageID = UUID()
        var chunks: [MessageChunk] = []
        let totalPags = Int(ceil(Double(fullData.count) / Double(chunkSize)))
        
        for inicioFatia in stride(from: 0, to: fullData.count, by: chunkSize) {
            let fimFatiaCalculado = inicioFatia + chunkSize
            let fimFatiaReal = min(fimFatiaCalculado, fullData.count)
            let pedacoCortado = fullData[inicioFatia ..< fimFatiaReal]
            let indexAtual = inicioFatia / chunkSize
            let novoChunk = MessageChunk(
                messageID: messageID,
                chunkIndex: indexAtual,
                totalChunks: totalPags,
                partialContent: pedacoCortado
            )
            chunks.append(novoChunk)
        }
        return chunks
    }
    
    private func sendChunk(chunk: MessageChunk, targetID: UUID) {
        guard let peripheral = connectedPeers[targetID], let characteristic = peerCharacteristics[targetID] else {
            print("NetworkService [ERROR]: Cannot send chunk. Peripheral or characteristic missing for \(targetID).")
            return
        }
        
        do {
            let chunkData = try JSONEncoder().encode(chunk)
            print("NetworkService: Sending chunk \(chunk.chunkIndex + 1)/\(chunk.totalChunks) (Encoded size: \(chunkData.count) bytes) to \(targetID).")
            
                // ATENÇÃO: Se o tamanho encodado exceder o MTU real do Mac, a Apple dropa o pacote.
            peripheral.writeValue(chunkData, for: characteristic, type: .withoutResponse)
        } catch {
            print("NetworkService [ERROR]: Failed to encode chunk: \(error.localizedDescription)")
        }
    }
    
    func receive(payload: Data) {
        print("NetworkService: Processing received raw payload of \(payload.count) bytes.")
        do {
            let chunk = try JSONDecoder().decode(MessageChunk.self, from: payload)
            print("NetworkService: Successfully decoded chunk \(chunk.chunkIndex + 1)/\(chunk.totalChunks) for MessageID: \(chunk.messageID).")
            
            if incomingChunks[chunk.messageID] == nil {
                print("NetworkService: Starting new buffer for incoming MessageID: \(chunk.messageID).")
                incomingChunks[chunk.messageID] = []
                
                Task {
                    try? await Task.sleep(nanoseconds: 15_000_000_000)
                    if let savedChunks = incomingChunks[chunk.messageID], savedChunks.count < chunk.totalChunks {
                        print("NetworkService [TIMEOUT]: Garbage collector dropped incomplete message \(chunk.messageID). Received \(savedChunks.count)/\(chunk.totalChunks) chunks.")
                        incomingChunks.removeValue(forKey: chunk.messageID)
                    }
                }
            }
            
            incomingChunks[chunk.messageID]?.append(chunk)
            let savedChunks = incomingChunks[chunk.messageID]!
            
            if savedChunks.count == chunk.totalChunks {
                print("NetworkService: All chunks received for MessageID: \(chunk.messageID). Assembling...")
                let sortedChunks = savedChunks.sorted { $0.chunkIndex < $1.chunkIndex }
                
                var fullEncryptedData = Data()
                for piece in sortedChunks {
                    fullEncryptedData.append(piece.partialContent)
                }
                
                incomingChunks.removeValue(forKey: chunk.messageID)
                print("NetworkService: Message fully assembled (\(fullEncryptedData.count) bytes). Forwarding to callback.")
                messageCallback?(fullEncryptedData)
            } else {
                print("NetworkService: Waiting for more chunks... (\(savedChunks.count)/\(chunk.totalChunks)).")
            }
        } catch {
            print("NetworkService [ERROR]: Failed to decode incoming payload into MessageChunk. Error: \(error.localizedDescription)")
        }
    }
    
    func disconnect(peerID: UUID) {
        guard let peripheral = connectedPeers[peerID] else { return }
        print("Central Terminal: Disconnecting from peripheral with ID:\(peerID).")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func disconnectAllPeers() {
        print("Central Terminal: Disconnecting all of the devices.")
        for peripheral in connectedPeers.values {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        self.connectedPeers.removeAll()
        self.peerCharacteristics.removeAll()
        self.incomingChunks.removeAll()
        
        self.radioState = .scanning
        self.startScanning()
    }
    
    
}

