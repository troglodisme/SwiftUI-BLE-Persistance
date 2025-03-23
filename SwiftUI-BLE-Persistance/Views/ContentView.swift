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
    @StateObject private var bleManager = BLEManager()
    @State private var isSheetPresented = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sensors) { sensor in
                    NavigationLink(destination: SensorDetailView(sensor: sensor, bleManager: bleManager)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(sensor.name)
                                    .font(.headline)
                                if let peripheralId = sensor.peripheralId,
                                   bleManager.connectedPeripheralUUID == peripheralId {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                        .foregroundColor(.green)
                                }
                            }
                            Text(sensor.location)
                                .font(.subheadline)
                            Text("\(sensor.readings.count) readings")
                                .font(.caption)
                        }
                    }
                }
                .onDelete(perform: deleteSensors)
            }
            .navigationTitle("Air Quality Sensors")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isSheetPresented.toggle() }) {
                        Image(systemName: "sensor")
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
    
    private func deleteSensors(at offsets: IndexSet) {
        for index in offsets {
            let sensor = sensors[index]
            if let peripheralId = sensor.peripheralId,
               bleManager.connectedPeripheralUUID == peripheralId {
                bleManager.disconnect()
            }
            modelContext.delete(sensor)
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
