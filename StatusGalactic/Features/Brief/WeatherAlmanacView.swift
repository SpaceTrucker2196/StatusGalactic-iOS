import SwiftUI
import Charts

/// Tap-detail for the headline weather summary. Renders meteorologist-style
/// sparklines for temperature, precipitation probability, wind, and humidity
/// over the next 48-72 hours, plus aggregate stats and the 12-hourly period
/// breakdown that the brief is built from.
struct WeatherAlmanacView: View {
    let earth: EarthWeather
    let timezoneName: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let first = earth.periods.first {
                    WeatherSummaryView(period: first)
                        .padding(.bottom, 4)
                }

                if !earth.hourly.isEmpty {
                    statsRow
                    sparkline(
                        title: "Temperature",
                        unit: "°F",
                        color: GalacticPalette.sun,
                        values: earth.hourly.map { ($0.time, $0.temperatureF) }
                    )
                    sparkline(
                        title: "Precipitation chance",
                        unit: "%",
                        color: GalacticPalette.electricBlue,
                        values: earth.hourly.map { ($0.time, $0.precipChancePct) },
                        yDomain: 0...100
                    )
                    sparkline(
                        title: "Wind speed",
                        unit: "mph",
                        color: GalacticPalette.hotPink,
                        values: earth.hourly.map { ($0.time, $0.windSpeedMph) }
                    )
                    sparkline(
                        title: "Humidity",
                        unit: "%",
                        color: GalacticPalette.mint,
                        values: earth.hourly.map { ($0.time, $0.humidityPct) },
                        yDomain: 0...100
                    )
                } else {
                    Text("Hourly sparkline data unavailable for this location.")
                        .font(.firaCode(.caption))
                        .foregroundStyle(.secondary)
                }

                periodsBreakdown
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("Weather Almanac")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsRow: some View {
        let temps = earth.hourly.compactMap(\.temperatureF)
        let precip = earth.hourly.compactMap(\.precipChancePct)
        let wind = earth.hourly.compactMap(\.windSpeedMph)

        HStack(spacing: 12) {
            if let hi = temps.max(), let lo = temps.min() {
                stat(label: "48h hi/lo",
                     value: String(format: "%.0f° / %.0f°", hi, lo),
                     color: GalacticPalette.sun)
            }
            if let peakPrecip = precip.max(), peakPrecip > 0 {
                stat(label: "Peak rain",
                     value: String(format: "%.0f%%", peakPrecip),
                     color: GalacticPalette.electricBlue)
            }
            if let peakWind = wind.max() {
                stat(label: "Peak wind",
                     value: String(format: "%.0f mph", peakWind),
                     color: GalacticPalette.hotPink)
            }
        }
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.headline, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 4)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sparkline

    private func sparkline(
        title: String,
        unit: String,
        color: Color,
        values: [(Date, Double?)],
        yDomain: ClosedRange<Double>? = nil
    ) -> some View {
        let points: [(Date, Double)] = values.compactMap { (t, v) in
            v.map { (t, $0) }
        }
        let nonZero = points.filter { $0.1 > 0 }
        let visible = (yDomain == 0...100) ? points : (nonZero.isEmpty ? points : nonZero)
        let series = visible.map { (time: $0.0, value: $0.1) }

        let current = series.first?.value
        let minV = series.min(by: { $0.value < $1.value })?.value
        let maxV = series.max(by: { $0.value < $1.value })?.value

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let current {
                    Text(String(format: "%.0f%@", current, unit))
                        .font(.firaCode(.body, weight: .bold))
                        .foregroundStyle(color)
                        .neonGlow(color, intensity: 4)
                        .monospacedDigit()
                }
            }

            chartView(series: series, color: color, yDomain: yDomain)

            HStack {
                if let minV {
                    Text("min \(String(format: "%.0f%@", minV, unit))")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let maxV {
                    Text("max \(String(format: "%.0f%@", maxV, unit))")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func chartView(
        series: [(time: Date, value: Double)],
        color: Color,
        yDomain: ClosedRange<Double>?
    ) -> some View {
        let chart = Chart {
            ForEach(series, id: \.time) { s in
                AreaMark(
                    x: .value("Time", s.time),
                    y: .value("Value", s.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.45), color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Time", s.time),
                    y: .value("Value", s.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 12)) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.weekday(.abbreviated).hour())
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 100)

        if let yDomain {
            chart.chartYScale(domain: yDomain)
        } else {
            chart
        }
    }

    // MARK: - Periods breakdown

    @ViewBuilder
    private var periodsBreakdown: some View {
        if earth.periods.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Periods")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                ForEach(earth.periods) { period in
                    WeatherPeriodCard(period: period)
                }
            }
        }
    }
}

private struct WeatherPeriodCard: View {
    let period: WeatherPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: GalacticSymbols.weatherSymbol(
                    for: period.shortForecast,
                    isDaytime: period.isDaytime
                ))
                .foregroundStyle(period.isDaytime ? GalacticPalette.sun : GalacticPalette.electricBlue)
                Text(period.name)
                    .font(.firaCode(.subheadline, weight: .semibold))
                Spacer()
                if let temp = period.temperature {
                    Text("\(temp)°\(period.temperatureUnit)")
                        .font(.firaCode(.subheadline, weight: .bold))
                        .foregroundStyle(GalacticPalette.temperature(temp))
                        .neonGlow(GalacticPalette.temperature(temp), intensity: 3)
                }
            }
            if let detailed = period.detailedForecast {
                Text(detailed)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.primary)
            } else {
                Text(period.shortForecast)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.primary)
            }
            if let wind = period.wind {
                Label(wind, systemImage: "wind")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(GalacticPalette.neonPurple.opacity(0.4), lineWidth: 0.6)
        )
    }
}
