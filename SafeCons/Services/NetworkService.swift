    //
    //  BluetoothServiceProtocol.swift
    //  SafeCons
    //
    //  Created by Vicenzo Másera on 28/03/26.
    //


import Foundation
import CoreBluetooth
import UIKit

@MainActor
protocol NetworkServiceProtocol {
    func startScanning()
    func startListening(onMessageReceived: @escaping (Data) -> Void)
    func send(payload: Data, targetID: UUID)
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
    var isConnected: Bool = false
    
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
        // TODO: Implement scanning flow.
    }

    func startListening(onMessageReceived: @escaping (Data) -> Void) {
        self.messageCallback = onMessageReceived
    }
    
    func send(payload: Data, targetID: UUID) {
        let chunks = splitIntoChunks(fullData: payload, chunkSize: 100)
        
        for chunk in chunks {
            sendChunk(chunk: chunk, targetID: targetID)
        }
    }
    
    private func splitIntoChunks(fullData: Data, chunkSize: Int) -> [MessageChunk] {
        let messageID = UUID()
        var chunks: [MessageChunk] = []
            // ceil arredonda pra cima
        let totalPags = Int(ceil(Double(fullData.count) / Double(chunkSize)))
            // pula de chunksize em chunksize
        for inicioFatia in stride(from: 0, to: fullData.count, by: chunkSize) {
                // pega o menor entre ambos, pra não dar index out of bounds
            let fimFatiaCalculado = inicioFatia + chunkSize
            let fimFatiaReal = min(fimFatiaCalculado, fullData.count)
                // pega tudo que tem entre o incio e o final da chunk
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
        guard let peripheral = connectedPeers[targetID], let characteristic = peerCharacteristics[targetID] else { return }
        
        do {
            let chunkData = try JSONEncoder().encode(chunk)
            peripheral.writeValue(chunkData, for: characteristic, type: .withoutResponse)
        } catch {
            print(error.localizedDescription)
        }
    }

    func receive(payload: Data) {
        do {
            let chunk = try JSONDecoder().decode(MessageChunk.self, from: payload)
            if incomingChunks[chunk.messageID] == nil {
                incomingChunks[chunk.messageID] = []
            }
            incomingChunks[chunk.messageID]?.append(chunk)
            let savedChunks = incomingChunks[chunk.messageID]!
            if savedChunks.count == chunk.totalChunks {
                let sortedChunks = savedChunks.sorted { $0.chunkIndex < $1.chunkIndex }
                
                var fullEncryptedData = Data()
                for piece in sortedChunks {
                    fullEncryptedData.append(piece.partialContent)
                }
                // apenas para não pesar na ram
                incomingChunks.removeValue(forKey: chunk.messageID)
                messageCallback?(fullEncryptedData)
            } else {
                print("ainda não está pronto")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}


extension NetworkService: CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("radar acordou")
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
        print("periférico acordou")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [NetworkService.serviceUUID], options: nil)
        case .unknown:
            print("erro enorme")
        case .resetting:
            print("bluetooth instável")
        case .unsupported:
            print("bluetooth não suportado")
        case .unauthorized:
            print("bluetooth não autorizado")
        case .poweredOff:
            print("bluetooth desligado")
        @unknown default:
            print("erro muito grade")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == NetworkService.rxCharacteristicUUID {
                if let value = request.value {
                    self.receive(payload: value)
                }
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("encontrado \(peripheral.name ?? "Desconhecido")")
        let myID = UserDefaults.standard.string(forKey: "SafeConsDeviceID") ?? {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "SafeConsDeviceID")
            return newID
        }()
        
        let otherID = peripheral.identifier.uuidString
        if myID > otherID {
            if !discoveredPeripherals.contains(peripheral) {
                discoveredPeripherals.append(peripheral)
            }
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        peripheral.discoverServices([NetworkService.serviceUUID])
        
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("bluetooth ligado")
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
            print("enviando sinais")
        case .unknown:
            print("erro enorme")
        case .resetting:
            print("bluetooth instável")
        case .unsupported:
            print("bluetooth não suportado")
        case .unauthorized:
            print("bluetooth não autorizado")
        case .poweredOff:
            print("bluetooth desligado")
        @unknown default:
            print("erro muito grade")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == NetworkService.serviceUUID {
                peripheral.discoverCharacteristics([NetworkService.rxCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            return
        }
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == NetworkService.rxCharacteristicUUID {
                self.peerCharacteristics.updateValue(characteristic, forKey: peripheral.identifier)
                self.connectedPeers.updateValue(peripheral, forKey: peripheral.identifier)
                self.isConnected = true
            }
        }
    }
}
