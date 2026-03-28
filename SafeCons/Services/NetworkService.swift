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
    var radioState: RadioState { get }
    
    func startScanning()
    func startListening(onMessageReceived: @escaping (Data) -> Void)
    func send(payload: Data)
    func receive(payload: Data)
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
    
    private var peerCharacteristics: [UUID: CBCharacteristic] = [:]
    private var connectedPeers: [UUID: CBPeripheral] = [:]
    
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
}

extension NetworkService: CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("Central Terminal: Radar waking up from background state restoration.")
        if let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in restoredPeripherals {
                peripheral.delegate = self
                if !discoveredPeripherals.contains(peripheral) {
                    discoveredPeripherals.append(peripheral)
                }
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("Peripheral Terminal: Radio waking up from background state restoration.")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central Terminal: Bluetooth powered on. Starting scan...")
            self.startScanning()
        case .unknown:
            print("Central Terminal: Unknown state.")
        case .resetting:
            print("Central Terminal: Bluetooth resetting radio stack.")
        case .unsupported:
            print("Central Terminal: Hardware does not support BLE.")
        case .unauthorized:
            print("Central Terminal: Bluetooth permission denied by user.")
        case .poweredOff:
            self.radioState = .offline
            print("Central Terminal: Bluetooth powered off.")
        @unknown default:
            print("Central Terminal: Unmapped critical error.")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Peripheral Terminal: Incoming write request detected (\(requests.count) operations).")
        for request in requests {
            if request.characteristic.uuid == NetworkService.rxCharacteristicUUID {
                if let value = request.value {
                    print("Peripheral Terminal: Extracting \(value.count) bytes from Rx Characteristic.")
                    self.receive(payload: value)
                } else {
                    print("Peripheral Terminal [WARNING]: Received write request but value was nil.")
                }
                peripheral.respond(to: request, withResult: .success)
            } else {
                print("Peripheral Terminal [WARNING]: Write request targeted wrong characteristic UUID: \(request.characteristic.uuid)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.state == .disconnected else { return }
        
            // 1. Filtro Espacial (Anti-Ghosting)
        guard RSSI.intValue > -80 else {
            print("Central Terminal: Ignoring weak ghost signal from \(peripheral.identifier) (RSSI: \(RSSI)).")
            return
        }
        
        print("Central Terminal: Discovered peer \(peripheral.identifier) with RSSI: \(RSSI). Initiating handshake...")
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
        
            // 2. Proteção de Máquina de Estado
        if self.connectedPeers.isEmpty {
            self.radioState = .discovering
        }
        
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Central Terminal: Successfully connected to peer \(peripheral.identifier). Discovering services...")
        peripheral.delegate = self
        peripheral.discoverServices([NetworkService.serviceUUID])
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Terminal: Bluetooth powered on. Configuring GATT server...")
            let rxCharacteristic = CBMutableCharacteristic(
                type: NetworkService.rxCharacteristicUUID,
                properties: [.write, .writeWithoutResponse],
                value: nil,
                permissions: [.writeable]
            )
            let chatService = CBMutableService(type: NetworkService.serviceUUID, primary: true)
            chatService.characteristics = [rxCharacteristic]
            peripheral.add(chatService)
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [NetworkService.serviceUUID]
            ])
            print("Peripheral Terminal: Advertising SafeCons Service beacon...")
        case .unknown:
            print("Peripheral Terminal: Unknown state.")
        case .resetting:
            print("Peripheral Terminal: Bluetooth resetting radio stack.")
        case .unsupported:
            print("Peripheral Terminal: Hardware does not support BLE.")
        case .unauthorized:
            print("Peripheral Terminal: Bluetooth permission denied by user.")
        case .poweredOff:
            print("Peripheral Terminal: Bluetooth powered off.")
        @unknown default:
            print("Peripheral Terminal: Unmapped critical error.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Central Terminal [ERROR]: Failed to discover services for \(peripheral.identifier): \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            print("Central Terminal [WARNING]: No services found on \(peripheral.identifier).")
            return
        }
        
        for service in services {
            print("Central Terminal: Found service \(service.uuid). Discovering characteristics...")
            if service.uuid == NetworkService.serviceUUID {
                peripheral.discoverCharacteristics([NetworkService.rxCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Central Terminal [ERROR]: Failed to discover characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else {
            print("Central Terminal [WARNING]: No characteristics found in service \(service.uuid).")
            return
        }
        
        for characteristic in characteristics {
            print("Central Terminal: Found characteristic \(characteristic.uuid).")
            if characteristic.uuid == NetworkService.rxCharacteristicUUID {
                self.peerCharacteristics.updateValue(characteristic, forKey: peripheral.identifier)
                self.connectedPeers.updateValue(peripheral, forKey: peripheral.identifier)
                self.radioState = .connected
                print("Central Terminal: Radio handshake complete. Secure Tunnel established with \(peripheral.identifier).")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Central Terminal: Peer \(peripheral.identifier) disconnected.")
        if let error = error {
            print("Central Terminal [ERROR]: Disconnection reason: \(error.localizedDescription)")
        }
        
        self.connectedPeers.removeValue(forKey: peripheral.identifier)
        self.peerCharacteristics.removeValue(forKey: peripheral.identifier)
        
            // 3. Resgate da Máquina de Estado
        if self.connectedPeers.isEmpty {
            print("Central Terminal: No peers remaining. Resuming scan...")
            self.radioState = .scanning
            startScanning()
        } else {
            print("Central Terminal: Tunnel remains active with other verified peers.")
            self.radioState = .connected
        }
    }
}
