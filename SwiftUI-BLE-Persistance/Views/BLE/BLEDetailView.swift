//
//  BLEDetailiew.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftUI

struct SensorDataRow: View {
    let label: String
    let value: Float
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value, specifier: "%.1f") \(unit)")
                .foregroundColor(.gray)
        }
    }
}

struct BLEDetailView: View {
    let peripheral: Peripheral
    @ObservedObject var bleManager: BLEManager
    @Environment(\.presentationMode) var presentationMode
    @State private var ledState: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
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
                
                if bleManager.connectionState == .connected {
                    Section(header: Text("Particulate Matter")) {
                        SensorDataRow(label: "PM1.0", value: bleManager.particulateData.pm1, unit: "μg/m³")
                        SensorDataRow(label: "PM2.5", value: bleManager.particulateData.pm25, unit: "μg/m³")
                        SensorDataRow(label: "PM4.0", value: bleManager.particulateData.pm4, unit: "μg/m³")
                        SensorDataRow(label: "PM10", value: bleManager.particulateData.pm10, unit: "μg/m³")
                    }
                    
                    Section(header: Text("Environmental")) {
                        SensorDataRow(label: "Temperature", value: bleManager.environmentalData.temperature, unit: "°C")
                        SensorDataRow(label: "Humidity", value: bleManager.environmentalData.humidity, unit: "%")
                    }
                    
                    Section(header: Text("Gas Measurements")) {
                        SensorDataRow(label: "VOC Index", value: bleManager.gasData.vocIndex, unit: "")
                        SensorDataRow(label: "NOx Index", value: bleManager.gasData.noxIndex, unit: "")
                        SensorDataRow(label: "CO2", value: bleManager.gasData.co2, unit: "ppm")
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
