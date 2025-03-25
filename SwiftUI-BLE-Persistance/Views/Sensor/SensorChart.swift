import SwiftUI
import Charts

struct SensorChart: View {
    let readings: [(timestamp: Date, value: Double)]
    let chartType: SensorChartView.ChartType
    
    var body: some View {
        if readings.isEmpty {
            Text("No data in selected time range")
                .foregroundColor(.secondary)
                .frame(height: 250)
        } else {
            Chart {
                ForEach(readings, id: \.0) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value(yAxisLabel(), reading.value)
                    )
                    .foregroundStyle(colorForChartType())
                    
                    PointMark(
                        x: .value("Time", reading.timestamp),
                        y: .value(yAxisLabel(), reading.value)
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
