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
    let updateTrigger: Bool  // New parameter to force updates

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
    
    var filteredReadings: [SensorReading] {
        let sortedReadings = sensor.readings.sorted(by: { $0.timestamp < $1.timestamp })
        
        if let interval = timeRange.timeInterval {
            let cutoffDate = Date().addingTimeInterval(-interval)
            return sortedReadings.filter { $0.timestamp >= cutoffDate }
        }
        
        return sortedReadings
    }
    
    var body: some View {
        VStack {
            // Chart type selector
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Time range selector
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if filteredReadings.isEmpty {
                Text("No data in selected time range")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            } else {
                Chart {
                    ForEach(filteredReadings) { reading in
                        LineMark(
                            x: .value("Time", reading.timestamp),
                            y: .value(yAxisLabel(), valueForReading(reading))
                        )
                        .foregroundStyle(colorForChartType())
                        
                        PointMark(
                            x: .value("Time", reading.timestamp),
                            y: .value(yAxisLabel(), valueForReading(reading))
                        )
                        .foregroundStyle(colorForChartType())
                    }
                }
                .frame(height: 250)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            
            // Reading count info
            HStack {
                Text("\(filteredReadings.count) readings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let newest = filteredReadings.last?.timestamp {
                    Text("Latest: \(newest, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
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
    
    private func yAxisLabel() -> String {
        switch chartType {
        case .pm25:
            return "PM2.5 (μg/m³)"
        case .temperature:
            return "Temperature (°C)"
        case .humidity:
            return "Humidity (%)"
        }
    }
    
    private func colorForChartType() -> Color {
        switch chartType {
        case .pm25:
            return .red
        case .temperature:
            return .orange
        case .humidity:
            return .blue
        }
    }
}


private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
