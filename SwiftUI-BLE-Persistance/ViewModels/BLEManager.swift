//
//  BLEManager.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import Foundation
import SwiftUI
import CoreBluetooth

// BLEManager class responsible for managing Bluetooth Low Energy (BLE) connections
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false // Property to track if scanning is in progress
    
    @Published var connectionState: CBPeripheralState = .disconnected //publish peripheral device

    var myCentral: CBCentralManager! // Declare a variable for the central manager
    @Published var isSwitchedOn = false // Property to track if Bluetooth is powered on
    @Published var peripherals = [Peripheral]() // Array to store discovered peripherals
    @Published var connectedPeripheralUUID: UUID? // UUID of the currently connected peripheral
    private var connectedPeripheral: CBPeripheral? // Reference to the currently connected peripheral
    
    // Add this property to store the LED characteristic
    private var ledCharacteristic: CBCharacteristic? // Reference to the LED characteristic

    // Air Quality Service UUID
    let airQualityServiceUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef0")

    // Characteristic UUIDs for different sensor types
    let particulateCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdea1")
    let environmentCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdea2")
    let gasCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdea3")

    // Published properties for all sensor values
    @Published var particulateData: (pm1: Float, pm25: Float, pm4: Float, pm10: Float) = (0, 0, 0, 0)
    @Published var environmentalData: (temperature: Float, humidity: Float) = (0, 0)
    @Published var gasData: (vocIndex: Float, noxIndex: Float, co2: Float) = (0, 0, 0)

    //Service UUIDs
    let ledServiceUUID = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    
    //Characteristics UUIDs
    let ledCharacteristicUUID = CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214")
    let buttonCharacteristicUUID = CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214")

    // Add these properties for automatic reading storage
    @Published var isAutoStoreEnabled = false
    private var lastStorageTime: Date?
    private var storageTimer: Timer?
    private let minimumStorageInterval: TimeInterval = 5 // 5 seconds to match sensor update rate

    override init() {
        super.init()
        print("BLEManager initialized")
        myCentral = CBCentralManager(delegate: self, queue: nil) // Initialize the central manager with self as the delegate
    }

    // Called when the Bluetooth state updates (e.g., powered on or off)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isSwitchedOn = central.state == .poweredOn // Update isSwitchedOn based on Bluetooth state
        if isSwitchedOn {
            startScanning() // Start scanning if Bluetooth is on
        } else {
            stopScanning() // Stop scanning if Bluetooth is off
        }
    }
    
    // Called when a peripheral is discovered during scanning
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        guard name != "Unknown" else { return }

        let newPeripheral = Peripheral(id: peripheral.identifier, name: name, rssi: RSSI.intValue, advertisementData: advertisementData)

        DispatchQueue.main.async {
            if !self.peripherals.contains(where: { $0.id == newPeripheral.id }) {
                self.peripherals.append(newPeripheral)
            }
        }
    }
    
    
    // Start scanning for peripherals
    func startScanning() {
        guard !isScanning else { return }
        print("Start Scanning") // Log the start of scanning
        isScanning = true
        myCentral.scanForPeripherals(withServices: nil, options: nil) // Start scanning for any peripheral
    }
    
    // Stop scanning for peripherals
    func stopScanning() {
        guard isScanning else { return }
        print("Stop Scanning") // Log the stop of scanning
        isScanning = false
        myCentral.stopScan() // Stop scanning
    }
    
    // Connect to a specific peripheral
    func connect(to peripheral: Peripheral) {
        guard let cbPeripheral = myCentral.retrievePeripherals(withIdentifiers: [peripheral.id]).first // Retrieve the peripheral with the given UUID
        else {
            print("Peripheral not found for connection") // Log if the peripheral is not found
            return
        }
        
        connectedPeripheralUUID = cbPeripheral.identifier // Store the UUID of the peripheral to connect
        connectedPeripheral = cbPeripheral // Store a reference to the peripheral
        cbPeripheral.delegate = self // Set self as the delegate for the peripheral
        
        connectionState = .connecting //testing cb state

        myCentral.connect(cbPeripheral, options: nil) // Attempt to connect to the peripheral
        
    }
    
    func disconnect() {
        storageTimer?.invalidate()
        storageTimer = nil
        if let connectedPeripheral = connectedPeripheral {
            connectionState = .disconnecting

            myCentral.cancelPeripheralConnection(connectedPeripheral) // Disconnect from the peripheral
//            connectedPeripheralUUID = nil // Reset the connected UUID
//            self.connectedPeripheral = nil // Clear the connected peripheral reference
        }
    }
    
    // Called when a peripheral is successfully connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")") // Log the successful connection
        peripheral.discoverServices(nil) // Discover services of the connected peripheral
        
        connectionState = .connected

    }
    
    // Called when the connection to a peripheral fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "No error information")") // Log the failure to connect
        if peripheral.identifier == connectedPeripheralUUID { // Check if the failed peripheral is the connected one
            connectedPeripheralUUID = nil // Clear the connected peripheral UUID
            connectedPeripheral = nil // Clear the connected peripheral reference
            
            connectionState = .disconnected

        }
    }

    // Called when a peripheral is disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown")") // Log the disconnection
        if peripheral.identifier == connectedPeripheralUUID { // Check if the disconnected peripheral is the connected one
            connectedPeripheralUUID = nil // Clear the connected peripheral UUID
            connectedPeripheral = nil // Clear the connected peripheral reference
            
            connectionState = .disconnected

            // Clean up timer and notifications when disconnecting
            storageTimer?.invalidate()
            storageTimer = nil
            lastStorageTime = nil
        }
    }
    
    
    // Called when services are discovered on a peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Services discovered - Count: \(peripheral.services?.count ?? 0)")
        if let services = peripheral.services {
            for service in services {
                print("Found service: \(service.uuid)")
                if service.uuid == airQualityServiceUUID {
                    print("Found Air Quality Service - discovering characteristics")
                    peripheral.discoverCharacteristics(
                        [particulateCharacteristicUUID, environmentCharacteristicUUID, gasCharacteristicUUID],
                        for: service
                    )
                }
            }
        }
    }

    // Update characteristic discovery
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Characteristics discovered for service: \(service.uuid)")
        print("Characteristics count: \(service.characteristics?.count ?? 0)")
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Found characteristic: \(characteristic.uuid)")
                if characteristic.uuid == particulateCharacteristicUUID ||
                   characteristic.uuid == environmentCharacteristicUUID ||
                   characteristic.uuid == gasCharacteristicUUID {
                    print("Enabling notifications for: \(characteristic.uuid)")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    // Update value handling for all characteristics
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        switch characteristic.uuid {
        case particulateCharacteristicUUID:
            if data.count >= 16 { // 4 Float values * 4 bytes each
                let values = data.withUnsafeBytes { bytes -> (Float, Float, Float, Float) in
                    let pm1 = bytes.load(fromByteOffset: 0, as: Float.self)
                    let pm25 = bytes.load(fromByteOffset: 4, as: Float.self)
                    let pm4 = bytes.load(fromByteOffset: 8, as: Float.self)
                    let pm10 = bytes.load(fromByteOffset: 12, as: Float.self)
                    return (pm1, pm25, pm4, pm10)
                }
                DispatchQueue.main.async {
                    self.particulateData = values
                    print("Particulate Data - PM1.0: \(values.0), PM2.5: \(values.1), PM4.0: \(values.2), PM10.0: \(values.3)")
                }
            }
            
        case environmentCharacteristicUUID:
            if data.count >= 8 { // 2 Float values * 4 bytes each
                let values = data.withUnsafeBytes { bytes -> (Float, Float) in
                    let temp = bytes.load(fromByteOffset: 0, as: Float.self)
                    let humidity = bytes.load(fromByteOffset: 4, as: Float.self)
                    return (temp, humidity)
                }
                DispatchQueue.main.async {
                    self.environmentalData = values
                    print("Environmental Data - Temp: \(values.0)°C, Humidity: \(values.1)%")
                }
            }
            
        case gasCharacteristicUUID:
            if data.count >= 12 { // 3 Float values * 4 bytes each
                let values = data.withUnsafeBytes { bytes -> (Float, Float, Float) in
                    let voc = bytes.load(fromByteOffset: 0, as: Float.self)
                    let nox = bytes.load(fromByteOffset: 4, as: Float.self)
                    let co2 = bytes.load(fromByteOffset: 8, as: Float.self)
                    return (voc, nox, co2)
                }
                DispatchQueue.main.async {
                    self.gasData = values
                    print("Gas Data - VOC: \(values.0), NOx: \(values.1), CO2: \(values.2)")
                }
            }
            
        default:
            break
        }
        
        // After updating values, check if we should store
        if isAutoStoreEnabled {
            checkAndStoreReadings()
        }
    }

    // Add toggleLED function to write to the LED characteristic, can be made more general for boolean write
    func toggleLED(on: Bool) {
        guard let ledCharacteristic = ledCharacteristic else {
            print("LED Characteristic not found")
            return
        }
        
        let value: UInt8 = on ? 1 : 0 // 1 to turn on, 0 to turn off
        let data = Data([value])
        connectedPeripheral?.writeValue(data, for: ledCharacteristic, type: .withResponse)
    }

    // Add this method for automatic storage control
    func toggleAutoStore(enabled: Bool) {
        isAutoStoreEnabled = enabled
        if enabled {
            setupStorageTimer()
        } else {
            storageTimer?.invalidate()
            storageTimer = nil
        }
    }

    private func setupStorageTimer() {
        storageTimer?.invalidate()
        storageTimer = Timer.scheduledTimer(withTimeInterval: minimumStorageInterval, repeats: true) { [weak self] _ in
            self?.checkAndStoreReadings()
        }
    }

    private func checkAndStoreReadings() {
        guard isAutoStoreEnabled else {
            print("Auto-store is disabled")
            return
        }
        
        if let lastStorage = lastStorageTime,
           Date().timeIntervalSince(lastStorage) < minimumStorageInterval {
            print("Too soon to store new reading")
            return
        }
        
        print("Posting StoreReading notification")
        NotificationCenter.default.post(
            name: Notification.Name("StoreReading"),
            object: nil
        )
        
        lastStorageTime = Date()
        print("Updated last storage time to: \(lastStorageTime?.description ?? "nil")")
    }
}
