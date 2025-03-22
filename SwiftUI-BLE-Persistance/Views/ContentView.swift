//
//  ContentView.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sensors: [Sensor]
    @State private var isSheetPresented = false
    
    var body: some View {
        NavigationView {
            // Your List view and toolbar items remain the same
            List {
                ForEach(sensors) { sensor in
                    NavigationLink(destination: SensorDetailView(sensor: sensor)) {
                        VStack(alignment: .leading) {
                            Text(sensor.name)
                                .font(.headline)
                            Text(sensor.location)
                                .font(.subheadline)
                            Text("\(sensor.readings.count) readings")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Air Quality Sensors")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isSheetPresented.toggle() }) {
                        Image(systemName: "sensor")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Test Data") {
                        let newSensor = Sensor(name: "New Sensor", location: "Test Location")
                        modelContext.insert(newSensor)
                        
                        // Add some random readings
                        for _ in 1...3 {
                            newSensor.addTestReading()
                        }
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                BLEDevicesView()
            }
        }
        .onAppear {
            createSampleData(modelContext: modelContext)
        }
    }
}

struct SheetListView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(1...5, id: \.self) { index in
                    Text("Item \(index)")
                }
            }
            .navigationTitle("Sheet List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

