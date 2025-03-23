//
//  Sensor.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftData
import SwiftUI

@Model
class Sensor {
    var id: UUID
    var name: String
    var location: String
    var lastConnected: Date?
    var peripheralId: UUID?
    
    @Relationship(deleteRule: .cascade)
    var readings: [SensorReading] = []
    
    init(id: UUID = UUID(), name: String, location: String, peripheralId: UUID? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.peripheralId = peripheralId
    }
    
    func addTestReading() {
          let randomHoursAgo = Double.random(in: 0...1)
          let timestamp = Date(timeIntervalSinceNow: -randomHoursAgo * 3600)
          
          let reading = SensorReading(
              timestamp: timestamp,
              pm25: Double.random(in: 5...50),
              temperature: Double.random(in: 18...30),
              humidity: Double.random(in: 30...80)
          )
          reading.sensor = self
          readings.append(reading)
      }
}

@Model
class SensorReading {
    var id: UUID
    var timestamp: Date
    var pm25: Double
    var temperature: Double
    var humidity: Double
    
    @Relationship(inverse: \Sensor.readings)
    var sensor: Sensor?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), pm25: Double, temperature: Double, humidity: Double) {
        self.id = id
        self.timestamp = timestamp
        self.pm25 = pm25
        self.temperature = temperature
        self.humidity = humidity
    }
}

@MainActor
func createSampleData(modelContext: ModelContext) {
    let descriptor = FetchDescriptor<Sensor>()
    guard let count = try? modelContext.fetchCount(descriptor), count == 0 else {
        return
    }
    
    let livingRoom = Sensor(name: "Living Room", location: "First Floor")
    let bedroom = Sensor(name: "Bedroom", location: "Second Floor")
    
    modelContext.insert(livingRoom)
    modelContext.insert(bedroom)
    
    let calendar = Calendar.current
    let now = Date()
    
    for i in 0..<24 {
        if let timestamp = calendar.date(byAdding: .hour, value: -i, to: now) {
            let hourOfDay = calendar.component(.hour, from: timestamp)
            
            let pm25Base = 15.0
            let pm25Variation = hourOfDay >= 7 && hourOfDay <= 9 ? 20.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 25.0 : 5.0)
            
            let tempBase = 22.0
            let tempVariation = hourOfDay >= 12 && hourOfDay <= 18 ? 5.0 : 0.0
            
            let humidityBase = 50.0
            let humidityVariation = hourOfDay >= 5 && hourOfDay <= 10 ? 15.0 : 5.0
            
            let livingRoomReading = SensorReading(
                timestamp: timestamp,
                pm25: pm25Base + Double.random(in: 0...pm25Variation),
                temperature: tempBase + Double.random(in: -2...tempVariation),
                humidity: humidityBase + Double.random(in: -5...humidityVariation)
            )
            livingRoomReading.sensor = livingRoom
            livingRoom.readings.append(livingRoomReading)
            
            let bedroomReading = SensorReading(
                timestamp: timestamp,
                pm25: (pm25Base - 3.0) + Double.random(in: 0...pm25Variation * 0.8),
                temperature: (tempBase - 1.0) + Double.random(in: -2...tempVariation * 0.9),
                humidity: (humidityBase + 5.0) + Double.random(in: -5...humidityVariation * 1.1)
            )
            bedroomReading.sensor = bedroom
            bedroom.readings.append(bedroomReading)
        }
    }
}
