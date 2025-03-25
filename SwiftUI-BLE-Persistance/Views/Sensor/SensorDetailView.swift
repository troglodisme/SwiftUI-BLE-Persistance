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
    
    @State private var isAutoStoreEnabled = false
    @State private var forceChartUpdate = false
    
    var autoStoreHelperText: String {
        if isAutoStoreEnabled {
            return "Storing readings every 5 seconds"
        }
        return ""
    }
    
    var body: some View {
        List {
            if !sensor.readings.isEmpty {
                Section(header: Text("Visualization")) {
                    SensorChartView(sensor: sensor, updateTrigger: forceChartUpdate)
                        .listRowInsets(EdgeInsets())
                }
            }
            
            Section(header: Text("Live Data")) {
                if isConnected {
                    Section(header: Text("Particulate Matter").bold()) {
                        LiveDataRow(label: "PM1.0", value: bleManager.particulateData.pm1, unit: "μg/m³", color: .purple)
                        LiveDataRow(label: "PM2.5", value: bleManager.particulateData.pm25, unit: "μg/m³", color: .purple)
                        LiveDataRow(label: "PM4.0", value: bleManager.particulateData.pm4, unit: "μg/m³", color: .purple)
                        LiveDataRow(label: "PM10", value: bleManager.particulateData.pm10, unit: "μg/m³", color: .purple)
                    }
                    .listRowBackground(Color.purple.opacity(0.1))
                    
                    Section(header: Text("Environmental").bold()) {
                        LiveDataRow(label: "Temperature", value: bleManager.environmentalData.temperature, unit: "°C", color: .orange)
                        LiveDataRow(label: "Humidity", value: bleManager.environmentalData.humidity, unit: "%", color: .orange)
                    }
                    .listRowBackground(Color.orange.opacity(0.1))
                    
                    Section(header: Text("Gas Measurements").bold()) {
                        LiveDataRow(label: "VOC Index", value: bleManager.gasData.vocIndex, unit: "", color: .green)
                        LiveDataRow(label: "NOx Index", value: bleManager.gasData.noxIndex, unit: "", color: .green)
                        LiveDataRow(label: "CO2", value: bleManager.gasData.co2, unit: "ppm", color: .green)
                    }
                    .listRowBackground(Color.green.opacity(0.1))
                    
                    Section {
                        Button("Store Reading") {
                            storeReading()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
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
            
//            Section(header: Text("BLE Simulation")) {
//                BLESimulationView(sensor: sensor)
//                    .listRowInsets(EdgeInsets())
//            }
            
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
                
                // Add battery indicator
                if isConnected {
                    HStack {
                        Image(systemName: getBatterySymbol())
                            .foregroundColor(getBatteryColor())
                        Text("Battery: \(bleManager.batteryLevel)%")
                            .foregroundColor(getBatteryColor())
                    }
                }
            }
            
//            Section(header: Text("Readings")) {
//                ForEach(sensor.readings.sorted(by: { $0.timestamp > $1.timestamp })) { reading in
//                    VStack(alignment: .leading) {
//                        Text("Time: \(reading.timestamp, formatter: itemFormatter)")
//                            .font(.caption)
//                        
//                        HStack {
//                            VStack(alignment: .leading) {
//                                Text("PM2.5: \(reading.pm25, specifier: "%.1f") μg/m³")
//                                Text("Temp: \(reading.temperature, specifier: "%.1f")°C")
//                            }
//                            
//                            Spacer()
//                            
//                            VStack(alignment: .trailing) {
//                                Text("Humidity: \(reading.humidity, specifier: "%.1f")%")
//                            }
//                        }
//                    }
//                    .padding(.vertical, 4)
//                }
//            }
            
            Section {
                Toggle("Auto-Store Readings", isOn: $isAutoStoreEnabled)
                    .onChange(of: isAutoStoreEnabled) { newValue in
                        bleManager.toggleAutoStore(enabled: newValue)
                        if newValue {
                            setupNotifications()
                        }
                    }
                if isAutoStoreEnabled {
                    Text(autoStoreHelperText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
//            Section {
//                Button("Add Test Reading") {
//                    sensor.addTestDescriptiveReading()
//                }
//                .frame(maxWidth: .infinity)
//                .buttonStyle(.bordered)
//            }
        }
        .onChange(of: sensor.readings.count) { _ in
            forceChartUpdate.toggle()
        }
        .navigationTitle(sensor.name)
        .onDisappear {
            if isConnected {
                bleManager.disconnect()
            }
        }
    }
    
    private func setupNotifications() {
        print("Setting up notifications for auto-store")
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StoreReading"),
            object: nil,
            queue: .main
        ) { _ in
            print("Received store reading notification")
            storeReading()
        }
    }

    private func storeReading() {
        print("Storing reading - Current count: \(sensor.readings.count)")
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
        print("Reading stored - New count: \(sensor.readings.count)")
    }
    
    private func getBatterySymbol() -> String {
        let level = bleManager.batteryLevel
        switch level {
        case 0...20:
            return "battery.0"
        case 21...40:
            return "battery.25"
        case 41...60:
            return "battery.50"
        case 61...80:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    private func getBatteryColor() -> Color {
        let level = bleManager.batteryLevel
        switch level {
        case 0...20:
            return .red
        case 21...40:
            return .orange
        default:
            return .green
        }
    }
}

struct LiveDataRow: View {
    let label: String
    let value: Float
    let unit: String
    let color: Color
    
    init(label: String, value: Float, unit: String, color: Color = .blue) {
        self.label = label
        self.value = value
        self.unit = unit
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value, specifier: "%.1f")")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
