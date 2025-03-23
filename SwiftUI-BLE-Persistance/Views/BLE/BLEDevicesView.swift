    //
    //  BLEDevicesView.swift
    //  Swiftui-BLE-Test
    //
    //  Created by Giulio on 08/11/24.
    //

    import SwiftUI

    struct BLEDevicesView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.dismiss) var dismiss
        @StateObject var bleManager = BLEManager()
        @State private var selectedPeripheral: Peripheral?

        var body: some View {
            NavigationView {
                VStack(alignment: .leading) {
                    List(bleManager.peripherals) { peripheral in
                        VStack(alignment: .leading) {
                            Text(peripheral.name)
                                .font(.headline)
                            Text("ID: \(peripheral.id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Text("RSSI: \(peripheral.rssi)")
                                Spacer()
                                Button(action: {
                                    connectToPeripheral(peripheral)
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
                        .padding(.vertical, 4)
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

        private func connectToPeripheral(_ peripheral: Peripheral) {
            bleManager.stopScanning()
            bleManager.connect(to: peripheral)
            
            // Create and save a new sensor with peripheralId
            let newSensor = Sensor(name: peripheral.name, location: "Unknown", peripheralId: peripheral.id)
            modelContext.insert(newSensor)
            
            // Dismiss the sheet
            dismiss()
        }

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
