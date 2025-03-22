
//  Peripheral.swift
//  Swiftui-BLE-Test
//  Created by Giulio on 07/11/24.

import Foundation

struct Peripheral: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisementData: [String: Any]

    static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        lhs.id == rhs.id
    }
}


