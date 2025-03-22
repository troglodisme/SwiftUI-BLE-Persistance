//
//  SwiftUI_BLE_PersistanceApp.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftUI
import SwiftData

@main
struct SwiftUI_BLE_Persistance: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Sensor.self, SensorReading.self])
    }
}
