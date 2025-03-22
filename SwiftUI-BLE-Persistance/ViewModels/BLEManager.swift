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

    // Air Quality Characteristic UUID
    let pm25CharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef1")

    @Published var pm25Value: Float = 0.0

    
    //Service UUIDs
    let ledServiceUUID = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    
    //Characteristics UUIDs
    let ledCharacteristicUUID = CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214")
    let buttonCharacteristicUUID = CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214")

    
    override init() {
        super.init()
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
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("Advertisement Data: \(advertisementData)") // Log advertisement data
//        let newPeripheral = Peripheral(id: peripheral.identifier, name: peripheral.name ?? "Unknown", rssi: RSSI.intValue) // Create a new Peripheral instance
//        if !peripherals.contains(where: { $0.id == newPeripheral.id }) { // Check if peripheral is already in the list
//            DispatchQueue.main.async { // Update peripherals list on the main queue
//                self.peripherals.append(newPeripheral) // Add new peripheral to the list
//            }
//        }
//    }
    
    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        let name = peripheral.name ?? "Unknown"
//        guard name != "Unknown" else {
//            return // Skip peripherals with name 'Unknown'
//        }
//
////        print("Advertisement Data: \(advertisementData)")
//        let newPeripheral = Peripheral(id: peripheral.identifier, name: name, rssi: RSSI.intValue, advertisementData: advertisementData)
//        if !peripherals.contains(where: { $0.id == newPeripheral.id }) {
//            DispatchQueue.main.async {
//                self.peripherals.append(newPeripheral)
//            }
//        }
//    }
    
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

        }
    }
    
    
    // Called when services are discovered on a peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ledServiceUUID {
                    print("Found LED Service")
                    peripheral.discoverCharacteristics([ledCharacteristicUUID, buttonCharacteristicUUID], for: service)
                } else if service.uuid == airQualityServiceUUID {
                    print("Found Air Quality Service")
                    peripheral.discoverCharacteristics([pm25CharacteristicUUID], for: service)
                }
            }
        }
    }


//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//          if let characteristics = service.characteristics {
//              for characteristic in characteristics {
//                  if characteristic.uuid == ledCharacteristicUUID {
//                      print("Found LED Characteristic")
//                      self.ledCharacteristic = characteristic // Save the LED characteristic for writing
//                  } else if characteristic.uuid == buttonCharacteristicUUID {
//                      print("Found Button Characteristic")
//                      peripheral.setNotifyValue(true, for: characteristic) // Enable notifications for button changes
//                  }
//              }
//          }
//      }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == ledCharacteristicUUID {
                    print("Found LED Characteristic")
                    self.ledCharacteristic = characteristic // Save the LED characteristic for writing
                } else if characteristic.uuid == buttonCharacteristicUUID {
                    print("Found Button Characteristic")
                    peripheral.setNotifyValue(true, for: characteristic) // Enable notifications for button changes
                } else if characteristic.uuid == pm25CharacteristicUUID {
                    print("Found pm2.5 Characteristic")
                    peripheral.setNotifyValue(true, for: characteristic) // Enable notifications for pm2.5 updates
                }
            }
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
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }
        
        if characteristic.uuid == pm25CharacteristicUUID {
            if let data = characteristic.value {
                let pm25Value = data.withUnsafeBytes { $0.load(as: Float.self) }
                DispatchQueue.main.async {
                    self.pm25Value = pm25Value
                    print("Updated pm2.5 Value: \(pm25Value) µg/m³")
                }
            }
        }
    }

    
    
    


}
