//
//  ChartControls.swift
//  SwiftUI-BLE-Persistance
//
//  Created by Giulio on 23/03/25.
//

import SwiftUI

struct ChartControls: View {
    @Binding var chartType: SensorChartView.ChartType
    @Binding var timeRange: SensorChartView.TimeRange
    let readingsCount: Int
    let latestReading: Date?
    let timeRangeString: String
    
    var body: some View {
        VStack {
            Picker("Chart Type", selection: $chartType) {
                ForEach(SensorChartView.ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Picker("Time Range", selection: $timeRange) {
                ForEach(SensorChartView.TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Text(timeRangeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                Text("\(readingsCount) readings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let latest = latestReading {
                    Text("Latest: \(latest, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
