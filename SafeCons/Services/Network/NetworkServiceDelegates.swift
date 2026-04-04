//
//  NetworkServiceDelegates.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI
import CoreBluetooth
import UIKit

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
                print("Central Terminal: Handshake complete. Awaiting heartbeat trigger from upper layer.")
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
