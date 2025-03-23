//
//  SensorDetailView.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 23/03/25.
//

import SwiftUI
import SwiftData
import Charts

struct SensorDetailView: View {
    let sensor: Sensor
    @ObservedObject var bleManager: BLEManager
    
    private var isConnected: Bool {
        sensor.peripheralId == bleManager.connectedPeripheralUUID &&
        bleManager.connectionState == .connected
    }
    
    var body: some View {
        List {
            if !sensor.readings.isEmpty {
                Section(header: Text("Visualization")) {
                    SensorChartView(sensor: sensor)
                        .listRowInsets(EdgeInsets())
                }
            }
            
            Section(header: Text("Live Data")) {
                if isConnected {
                    HStack {
                        Text("PM2.5:")
                        Spacer()
                        Text("\(bleManager.pm25Value, specifier: "%.1f") μg/m³")
                            .foregroundColor(.blue)
                    }
                    
                    Button("Store Reading") {
                        let reading = SensorReading(
                            pm25: Double(bleManager.pm25Value),
                            temperature: 0, // We don't have these values yet
                            humidity: 0     // We don't have these values yet
                        )
                        reading.sensor = sensor
                        sensor.readings.append(reading)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                } else {
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text("Disconnected")
                            .foregroundColor(.red)
                    }
                    Button("Connect") {
                        if let peripheralId = sensor.peripheralId {
                            let peripheral = Peripheral(
                                id: peripheralId,
                                name: sensor.name,
                                rssi: 0,
                                advertisementData: [:] // Empty dictionary for reconnection
                            )
                            bleManager.connect(to: peripheral)
                        }
                    }
                }
            }
            
            Section(header: Text("BLE Simulation")) {
                BLESimulationView(sensor: sensor)
                    .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text("Sensor Info")) {
                Text("Name: \(sensor.name)")
                Text("Location: \(sensor.location)")
                Text("Sensor ID: \(sensor.id.uuidString)")
                if let peripheralId = sensor.peripheralId {
                    Text("Peripheral ID: \(peripheralId.uuidString)")
                        .foregroundColor(.blue)
                } else {
                    Text("No Peripheral ID")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Readings")) {
                ForEach(sensor.readings.sorted(by: { $0.timestamp > $1.timestamp })) { reading in
                    VStack(alignment: .leading) {
                        Text("Time: \(reading.timestamp, formatter: itemFormatter)")
                            .font(.caption)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("PM2.5: \(reading.pm25, specifier: "%.1f") μg/m³")
                                Text("Temp: \(reading.temperature, specifier: "%.1f")°C")
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Humidity: \(reading.humidity, specifier: "%.1f")%")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Button("Add Test Reading") {
                    sensor.addTestReading()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle(sensor.name)
        .onDisappear {
            if isConnected {
                bleManager.disconnect()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
