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
    
    var body: some View {
        List {
            if !sensor.readings.isEmpty {
                Section(header: Text("Visualization")) {
                    SensorChartView(sensor: sensor)
                        .listRowInsets(EdgeInsets())
                }
            }
            
            Section(header: Text("BLE Simulation")) {
                BLESimulationView(sensor: sensor)
                    .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text("Sensor Info")) {
                Text("Name: \(sensor.name)")
                Text("Location: \(sensor.location)")
                Text("ID: \(sensor.id.uuidString)")
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
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
