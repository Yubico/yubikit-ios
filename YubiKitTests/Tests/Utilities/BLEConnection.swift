//
//  BLEConnection.swift
//  Tests
//
//  Created by Jens Utbult on 2022-03-30.
//

import Foundation
import CoreBluetooth

class BLEConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BLEConnection()

    private var completionHandler: (()->())?
    private lazy var manager = CBCentralManager(delegate: self, queue: nil)
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    override init() {
        super.init()
        manager.scanForPeripherals(withServices: nil)
        print("🦠 init BLEConnection")
    }
    
    func touchKey(completion: @escaping ()->()) {
        if sendTouchData() {
            completion()
            print("🦠 touch key")
        } else {
            completionHandler = completion
        }
    }
    
    private func sendTouchData() -> Bool {
        guard let peripheral = peripheral, let characteristic = characteristic else {
            return false
        }
        let data = Data(bytes: [0x01], count: 1)
        print("🦠 write data \(data) \(peripheral.canSendWriteWithoutResponse)")
        
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        return true
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
          central.scanForPeripherals(withServices: nil, options: nil)
          print("🦠 Scanning...")
         }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else { return }
        if peripheral.name == "YubiKeyToucher" || peripheral.name == "Feather nRF52832" {
            self.peripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral)
            print("🦠 didDiscover: \(peripheral)")
            central.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🦠 didConnect: \(peripheral)")
        peripheral.discoverServices(nil)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print("🦠 didDiscoverServices: \(services)")
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        characteristics.forEach {
            if $0.uuid == CBUUID(string: "4444") {
                self.characteristic = $0
                if let completionHandler = completionHandler {
                    _ = sendTouchData()
                    completionHandler()
                    self.completionHandler = nil
                }
                print("🦠 didDiscoverCharacteristicsFor \($0)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("🦠 didWriteValueFor failed with:\(error)")
        } else {
            print("🦠 didWriteValueFor \(characteristic) succeeded")
        }
    }
}
