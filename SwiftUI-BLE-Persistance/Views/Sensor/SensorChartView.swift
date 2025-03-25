//
//  SensorChartView.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 22/03/25.
//

import SwiftUI
import SwiftData
import Charts

struct SensorChartView: View {
    let sensor: Sensor
    let updateTrigger: Bool

    @State private var chartType: ChartType = .pm25
    @State private var timeRange: TimeRange = .hour1
    
    enum ChartType: String, CaseIterable, Identifiable {
        case pm25 = "PM2.5"
        case temperature = "Temperature"
        case humidity = "Humidity"
        
        var id: String { self.rawValue }
    }
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case minute1 = "1 min"
        case hour1 = "1 hour"
        case hours6 = "6 hours"
        case day1 = "24 hours"
        case all = "All"
        
        var id: String { self.rawValue }
        
        var timeInterval: TimeInterval? {
            switch self {
            case .minute1: return 1 * 60
            case .hour1: return 60 * 60
            case .hours6: return 6 * 60 * 60
            case .day1: return 24 * 60 * 60
            case .all: return nil
            }
        }
    }

    private var timeRangeString: String {
        if timeRange == .all {
            return "All readings"
        }
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-timeRange.timeInterval!)
        return "\(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: endDate))"
    }

    private var filteredReadings: [SensorReading] {
        let sortedReadings = sensor.readings.sorted(by: { $0.timestamp < $1.timestamp })
        
        if let interval = timeRange.timeInterval {
            let currentDate = Date()
            let cutoffDate = currentDate.addingTimeInterval(-interval)
            return sortedReadings.filter { reading in
                reading.timestamp >= cutoffDate && reading.timestamp <= currentDate
            }
        }
        
        return sortedReadings
    }
    
    private var processedReadings: [(timestamp: Date, value: Double)] {
        return filteredReadings.map { ($0.timestamp, valueForReading($0)) }
    }

    var body: some View {
        VStack {
            ChartControls(
                chartType: $chartType,
                timeRange: $timeRange,
                readingsCount: processedReadings.count,
                latestReading: processedReadings.last?.timestamp,
                timeRangeString: timeRangeString
            )
            
            SensorChart(
                readings: processedReadings,
                chartType: chartType
            )
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func valueForReading(_ reading: SensorReading) -> Double {
        switch chartType {
        case .pm25:
            return reading.pm25
        case .temperature:
            return reading.temperature
        case .humidity:
            return reading.humidity
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
