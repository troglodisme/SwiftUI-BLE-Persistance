//
//  BLESimulator.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftUI
import SwiftData
import Combine

// Class to handle the BLE simulation
class BLESimulator: ObservableObject {
    @Published var isSimulating = false
    private var timer: AnyCancellable?
    private var sensor: Sensor?
    
    // Start simulation with a specific sensor
    func startSimulation(for sensor: Sensor, interval: TimeInterval = 5.0) {
        // Store the sensor
        self.sensor = sensor
        
        // Cancel any existing timer
        stopSimulation()
        
        // Set the simulation state
        isSimulating = true
        
        // Create a timer that fires at the specified interval
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.addSimulatedReading()
            }
    }
    
    // Stop the simulation
    func stopSimulation() {
        timer?.cancel()
        timer = nil
        isSimulating = false
    }
    
    // Toggle simulation state
    func toggleSimulation(for sensor: Sensor, interval: TimeInterval = 5.0) {
        if isSimulating {
            stopSimulation()
        } else {
            startSimulation(for: sensor, interval: interval)
        }
    }
    
    // Add a simulated reading
    private func addSimulatedReading() {
        guard let sensor = sensor else { return }
        
        // Create a realistic reading based on the previous readings
        let timestamp = Date()
        
        // Get the last reading if available
        let lastReading = sensor.readings.sorted(by: { $0.timestamp > $1.timestamp }).first
        
        // Add some small random changes to the last values, or use defaults
        let lastPM25 = lastReading?.pm25 ?? 20.0
        let lastTemp = lastReading?.temperature ?? 22.0
        let lastHumidity = lastReading?.humidity ?? 50.0
        
        // Create small variations for realistic sensor data
        let pm25 = max(0, lastPM25 + Double.random(in: -2...2))
        let temperature = lastTemp + Double.random(in: -0.3...0.3)
        let humidity = max(0, min(100, lastHumidity + Double.random(in: -1...1)))
        
        let reading = SensorReading(
            timestamp: timestamp,
            pm25: pm25,
            temperature: temperature,
            humidity: humidity
        )
        
        reading.sensor = sensor
        sensor.readings.append(reading)
    }
}

// Extension for SensorDetailView to incorporate BLE simulator
extension SensorDetailView {
    // Now update the SensorDetailView to include the BLE simulator
    struct BLESimulationView: View {
        let sensor: Sensor
        @StateObject private var bleSimulator = BLESimulator()
        @State private var simulationInterval: Double = 5.0
        
        var body: some View {
            VStack(spacing: 12) {
                HStack {
                    Text("Simulation interval: \(simulationInterval, specifier: "%.1f")s")
                    
                    Slider(value: $simulationInterval, in: 1...30, step: 1)
                        .disabled(bleSimulator.isSimulating)
                }
                
                Button(action: {
                    bleSimulator.toggleSimulation(for: sensor, interval: simulationInterval)
                }) {
                    HStack {
                        Image(systemName: bleSimulator.isSimulating ? "stop.circle.fill" : "play.circle.fill")
                        Text(bleSimulator.isSimulating ? "Stop BLE Simulation" : "Start BLE Simulation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(bleSimulator.isSimulating ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

