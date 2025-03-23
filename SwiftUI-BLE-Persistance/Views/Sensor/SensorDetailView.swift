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
        let connected = sensor.peripheralId == bleManager.connectedPeripheralUUID &&
        bleManager.connectionState == .connected
        print("Connection state check - Sensor peripheralId: \(sensor.peripheralId?.uuidString ?? "nil"), Connected peripheralId: \(bleManager.connectedPeripheralUUID?.uuidString ?? "nil"), State: \(bleManager.connectionState)")
        print("isConnected: \(connected)")
        return connected
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
                    Group {
                        Section(header: Text("Particulate Matter")) {
                            LiveDataRow(label: "PM1.0", value: bleManager.particulateData.pm1, unit: "μg/m³")
                            LiveDataRow(label: "PM2.5", value: bleManager.particulateData.pm25, unit: "μg/m³")
                            LiveDataRow(label: "PM4.0", value: bleManager.particulateData.pm4, unit: "μg/m³")
                            LiveDataRow(label: "PM10", value: bleManager.particulateData.pm10, unit: "μg/m³")
                        }
                        
                        Section(header: Text("Environmental")) {
                            LiveDataRow(label: "Temperature", value: bleManager.environmentalData.temperature, unit: "°C")
                            LiveDataRow(label: "Humidity", value: bleManager.environmentalData.humidity, unit: "%")
                        }
                        
                        Section(header: Text("Gas Measurements")) {
                            LiveDataRow(label: "VOC Index", value: bleManager.gasData.vocIndex, unit: "")
                            LiveDataRow(label: "NOx Index", value: bleManager.gasData.noxIndex, unit: "")
                            LiveDataRow(label: "CO2", value: bleManager.gasData.co2, unit: "ppm")
                        }
                        
                        Section {
                            Button("Store Reading") {
                                let reading = SensorReading(
                                    pm1: Double(bleManager.particulateData.pm1),
                                    pm25: Double(bleManager.particulateData.pm25),
                                    pm4: Double(bleManager.particulateData.pm4),
                                    pm10: Double(bleManager.particulateData.pm10),
                                    temperature: Double(bleManager.environmentalData.temperature),
                                    humidity: Double(bleManager.environmentalData.humidity),
                                    vocIndex: Double(bleManager.gasData.vocIndex),
                                    noxIndex: Double(bleManager.gasData.noxIndex),
                                    co2: Double(bleManager.gasData.co2)
                                )
                                reading.sensor = sensor
                                sensor.readings.append(reading)
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                } else {
                    Section(header: Text("Connection")) {
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

struct LiveDataRow: View {
    let label: String
    let value: Float
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value, specifier: "%.1f") \(unit)")
                .foregroundColor(.blue)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
