    //
    //  BluetoothServiceProtocol.swift
    //  SafeCons
    //
    //  Created by Vicenzo Másera on 28/03/26.
    //


import Foundation
import CoreBluetooth

@MainActor
protocol NetworkServiceProtocol {
    func startScanning()
    func startAdvertising()
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
    var isConnected: Bool = false
    
    private var incomingChunks: [UUID: [MessageChunk]] = [:]
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }

    func startScanning() {
        // TODO: Implement scanning flow.
    }

    func startAdvertising() {
        // TODO: Implement advertising flow.
    }
    
    func send(payload: Data) {
        let chunks = splitIntoChunks(fullData: payload, chunkSize: 100)
        
        for chunk in chunks {
            sendChunk(chunk: chunk)
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
    
    private func sendChunk(chunk: MessageChunk) {
        
    }

    func receive(payload: Data) {
        // TODO: Implement payload reassembly/processing.
    }
}


extension NetworkService: CBCentralManagerDelegate, CBPeripheralManagerDelegate {
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("encontrado \(peripheral.name ?? "Desconhecido")")
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
        central.connect(peripheral, options: nil)
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
}
