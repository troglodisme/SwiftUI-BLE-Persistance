//
//  BLEDetailiew.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//


import SwiftUI

struct BLEDetailView: View {
    let peripheral: Peripheral
    @ObservedObject var bleManager: BLEManager
    @Environment(\.presentationMode) var presentationMode
    @State private var ledState: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    // Existing Connection Status Section
                    Section(header: Text("Connection Status")) {
                        HStack {
                            Text("Status")
                            Spacer()
                            if bleManager.connectedPeripheralUUID == peripheral.id {
                                switch bleManager.connectionState {
                                case .connecting:
                                    Text("Connecting...")
                                case .connected:
                                    Text("Connected").foregroundColor(.green)
                                case .disconnecting:
                                    Text("Disconnecting...")
                                default:
                                    Text("Unknown")
                                }
                            } else {
                                Text("Disconnected")
                            }
                        }
                    }
                    
                    // Existing Controls Section
                    if bleManager.connectionState == .connected {
                        Section(header: Text("Controls")) {
                            Toggle(isOn: $ledState) {
                                Text("Toggle LED")
                            }
                            .onChange(of: ledState) { value in
                                bleManager.toggleLED(on: value)
                            }
                        }
                    }
                    
                    // New Sensor Data Section
                    if bleManager.connectionState == .connected {
                        Section(header: Text("Sensor Data")) {
                            HStack {
                                Text("pm2.5")
                                Spacer()
                                Text("\(bleManager.pm25Value, specifier: "%.1f") µg/m³")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(peripheral.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Disconnect") {
                            bleManager.disconnect()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .onChange(of: bleManager.connectionState) { newState in
                    if newState == .disconnected {
                        alertMessage = "Peripheral disconnected"
                        showAlert = true
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Disconnected"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
        }
    }
}
