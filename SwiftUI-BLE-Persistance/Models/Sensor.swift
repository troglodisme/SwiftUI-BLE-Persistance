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
              pm1: Double.random(in: 1...10),
              pm25: Double.random(in: 5...50),
              pm4: Double.random(in: 2...20),
              pm10: Double.random(in: 5...50),
              temperature: Double.random(in: 18...30),
              humidity: Double.random(in: 30...80),
              vocIndex: Double.random(in: 0...100),
              noxIndex: Double.random(in: 0...100),
              co2: Double.random(in: 0...1000)
          )
          reading.sensor = self
          readings.append(reading)
      }
}

@Model
class SensorReading {
    var id: UUID
    var timestamp: Date
    
    // Particulate Matter
    var pm1: Double
    var pm25: Double
    var pm4: Double
    var pm10: Double
    
    // Environmental
    var temperature: Double
    var humidity: Double
    
    // Gas
    var vocIndex: Double
    var noxIndex: Double
    var co2: Double
    
    @Relationship(inverse: \Sensor.readings)
    var sensor: Sensor?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         pm1: Double = 0,
         pm25: Double = 0,
         pm4: Double = 0,
         pm10: Double = 0,
         temperature: Double = 0,
         humidity: Double = 0,
         vocIndex: Double = 0,
         noxIndex: Double = 0,
         co2: Double = 0) {
        self.id = id
        self.timestamp = timestamp
        self.pm1 = pm1
        self.pm25 = pm25
        self.pm4 = pm4
        self.pm10 = pm10
        self.temperature = temperature
        self.humidity = humidity
        self.vocIndex = vocIndex
        self.noxIndex = noxIndex
        self.co2 = co2
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
            
            let pm1Base = 5.0
            let pm1Variation = hourOfDay >= 7 && hourOfDay <= 9 ? 10.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 15.0 : 2.5)
            
            let pm4Base = 10.0
            let pm4Variation = hourOfDay >= 7 && hourOfDay <= 9 ? 15.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 20.0 : 5.0)
            
            let pm10Base = 15.0
            let pm10Variation = hourOfDay >= 7 && hourOfDay <= 9 ? 20.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 25.0 : 5.0)
            
            let vocIndexBase = 50.0
            let vocIndexVariation = hourOfDay >= 7 && hourOfDay <= 9 ? 20.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 25.0 : 5.0)
            
            let noxIndexBase = 20.0
            let noxIndexVariation = hourOfDay >= 7 && hourOfDay <= 9 ? 10.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 15.0 : 2.5)
            
            let co2Base = 500.0
            let co2Variation = hourOfDay >= 7 && hourOfDay <= 9 ? 100.0 :
                               (hourOfDay >= 17 && hourOfDay <= 20 ? 150.0 : 25.0)
            
            let livingRoomReading = SensorReading(
                timestamp: timestamp,
                pm1: pm1Base + Double.random(in: 0...pm1Variation),
                pm25: pm25Base + Double.random(in: 0...pm25Variation),
                pm4: pm4Base + Double.random(in: 0...pm4Variation),
                pm10: pm10Base + Double.random(in: 0...pm10Variation),
                temperature: tempBase + Double.random(in: -2...tempVariation),
                humidity: humidityBase + Double.random(in: -5...humidityVariation),
                vocIndex: vocIndexBase + Double.random(in: 0...vocIndexVariation),
                noxIndex: noxIndexBase + Double.random(in: 0...noxIndexVariation),
                co2: co2Base + Double.random(in: 0...co2Variation)
            )
            livingRoomReading.sensor = livingRoom
            livingRoom.readings.append(livingRoomReading)
            
            let bedroomReading = SensorReading(
                timestamp: timestamp,
                pm1: (pm1Base - 1.0) + Double.random(in: 0...pm1Variation * 0.8),
                pm25: (pm25Base - 3.0) + Double.random(in: 0...pm25Variation * 0.8),
                pm4: (pm4Base - 2.0) + Double.random(in: 0...pm4Variation * 0.8),
                pm10: (pm10Base - 3.0) + Double.random(in: 0...pm10Variation * 0.8),
                temperature: (tempBase - 1.0) + Double.random(in: -2...tempVariation * 0.9),
                humidity: (humidityBase + 5.0) + Double.random(in: -5...humidityVariation * 1.1),
                vocIndex: (vocIndexBase + 5.0) + Double.random(in: 0...vocIndexVariation * 1.1),
                noxIndex: (noxIndexBase + 2.5) + Double.random(in: 0...noxIndexVariation * 1.1),
                co2: (co2Base + 50.0) + Double.random(in: 0...co2Variation * 1.1)
            )
            bedroomReading.sensor = bedroom
            bedroom.readings.append(bedroomReading)
        }
    }
}
