//
//  BLEDevicesView.swift
//  Swiftui-BLE-Test
//
//  Created by Giulio on 08/11/24.
//

import SwiftUI

struct BLEDevicesView: View {
    @StateObject var bleManager = BLEManager()
    @State private var selectedPeripheral: Peripheral?
    @State private var isSheetPresented = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {

//                HStack {
//                    if bleManager.isSwitchedOn {
//                        Text("Bluetooth is on")
//                            .foregroundColor(.green)
//                    } else {
//                        Text("Bluetooth is off, switch it on!")
//                            .foregroundColor(.red)
//                    }
//                }
//                .padding()
                
                List(bleManager.peripherals) { peripheral in
                    HStack {
                        Text(peripheral.name)
                        Spacer()
                        Text(String(peripheral.rssi))
                        Button(action: {
                            bleManager.stopScanning() // Stop scanning on selection
                            bleManager.connect(to: peripheral)
                            selectedPeripheral = peripheral
                            isSheetPresented = true // Present the sheet
                        }) {
                            if bleManager.connectedPeripheralUUID == peripheral.id {
                                Text("Connected")
                                    .foregroundColor(.green)
                            } else {
                                Text("Connect")
                            }
                        }
                    }
                }
                .sheet(isPresented: $isSheetPresented, onDismiss: {
                    selectedPeripheral = nil // Reset the selected peripheral
                    // Optionally restart scanning when sheet is dismissed
                    // bleManager.startScanning()
                }) {
                    if let peripheral = selectedPeripheral {
                        BLEDetailView(peripheral: peripheral, bleManager: bleManager)
                    }
                }
            }
            .navigationBarTitle("BLE Devices", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    refreshPeripherals()
                }) {
                    Text("Refresh")
                }
            )
            .onAppear {
                if bleManager.isSwitchedOn {
                    bleManager.startScanning()
                }
            }
        }
    }

    // Helper function to refresh peripherals
    private func refreshPeripherals() {
        bleManager.stopScanning()
        bleManager.peripherals.removeAll()
        if bleManager.isSwitchedOn {
            bleManager.startScanning()
        }
    }
}


#Preview {
    BLEDevicesView()
}




