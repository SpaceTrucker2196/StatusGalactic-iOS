import SwiftUI
import Charts

/// Tap-detail for the Space Weather summary. Mirrors WeatherAlmanacView:
/// stats row, sparklines for F10.7 flux and planetary Kp, then a per-band
/// HF propagation breakdown.
struct SolarAlmanacView: View {
    let brief: Brief

    private var space: SpaceWeather { brief.space ?? SpaceWeather(
        solarFlux: nil, kpIndex: nil, kpStatus: nil,
        auroraLikely: false, hfSummary: nil, observedAt: nil
    ) }

    @Environment(ClientConfig.self) private var config
    @State private var almanac: SolarAlmanac?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headlineRow
                if let wind = brief.solarWind {
                    SolarWindPanel(wind: wind)
                }
                if let flare = brief.flareProbability {
                    FlareProbabilityPanel(flare: flare)
                }
                if !brief.kpForecast.isEmpty {
                    KpForecastPanel(days: brief.kpForecast)
                }
                if !brief.activeRegions.isEmpty {
                    ActiveRegionsPanel(regions: brief.activeRegions)
                }
                if !brief.cmes.isEmpty {
                    CMETrackerPanel(cmes: brief.cmes)
                }
                DRAPPanel()
                if !brief.solarOutlook.isEmpty {
                    SolarOutlookPanel(days: brief.solarOutlook)
                }
                if isLoading && almanac == nil {
                    ProgressView()
                        .tint(GalacticPalette.neonCyan)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    if let almanac, !almanac.kp.isEmpty {
                        kpSparkline(points: almanac.kp)
                    }
                    if let almanac, !almanac.flux.isEmpty {
                        fluxSparkline(points: almanac.flux)
                    }
                    if let almanac, almanac.kp.isEmpty && almanac.flux.isEmpty {
                        Text("SWPC historical samples unavailable.")
                            .font(.firaCode(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                if let wwv = brief.wwvBulletin {
                    WWVBulletinPanel(bulletin: wwv)
                }
                if let hf = space.hfSummary, !hf.isEmpty {
                    hfPanel(hf)
                }
                if let err = loadError {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.storm)
                }
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("Solar Almanac")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Headline

    @ViewBuilder
    private var headlineRow: some View {
        HStack(spacing: 14) {
            statTile(
                label: "Kp",
                value: space.kpIndex.map { String(format: "%.1f", $0) } ?? "—",
                accent: space.kpIndex.map(GalacticPalette.kp(_:)) ?? GalacticPalette.peach,
                detail: space.kpStatus
            )
            statTile(
                label: "F10.7",
                value: space.solarFlux.map { String(format: "%.0f", $0) } ?? "—",
                accent: space.solarFlux.map(GalacticPalette.solarFlux(_:)) ?? GalacticPalette.peach,
                detail: "sfu"
            )
            statTile(
                label: "Aurora",
                value: space.auroraLikely ? "Likely" : "Quiet",
                accent: space.auroraLikely ? GalacticPalette.severe : GalacticPalette.mint,
                detail: nil
            )
        }
    }

    private func statTile(label: String, value: String, accent: Color, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.title2, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 6)
                .monospacedDigit()
            if let detail {
                Text(detail)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.45), lineWidth: 0.75)
        )
    }

    // MARK: - Sparklines

    private func kpSparkline(points: [KpPoint]) -> some View {
        let current = points.last?.kp
        let peak = points.map(\.kp).max()
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Planetary Kp (3h, 7d)")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let current {
                    Text(String(format: "%.1f", current))
                        .font(.firaCode(.body, weight: .bold))
                        .foregroundStyle(GalacticPalette.kp(current))
                        .neonGlow(GalacticPalette.kp(current), intensity: 4)
                        .monospacedDigit()
                }
            }
            Chart {
                ForEach(points, id: \.time) { p in
                    BarMark(
                        x: .value("Time", p.time),
                        y: .value("Kp", p.kp)
                    )
                    .foregroundStyle(GalacticPalette.kp(p.kp))
                }
                RuleMark(y: .value("Storm", 5))
                    .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.storm.opacity(0.6))
            }
            .chartYScale(domain: 0...9)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 3, 5, 7, 9]) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel()
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 110)
            HStack {
                Text("min \(String(format: "%.1f", points.map(\.kp).min() ?? 0))")
                Spacer()
                if let peak {
                    Text("peak \(String(format: "%.1f", peak))")
                        .foregroundStyle(GalacticPalette.kp(peak))
                }
            }
            .font(.firaCode(.caption2))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func fluxSparkline(points: [SolarFluxPoint]) -> some View {
        let current = points.last?.flux
        let lo = points.map(\.flux).min()
        let hi = points.map(\.flux).max()
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("F10.7 cm flux (daily, 30d)")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let current {
                    Text(String(format: "%.0f sfu", current))
                        .font(.firaCode(.body, weight: .bold))
                        .foregroundStyle(GalacticPalette.solarFlux(current))
                        .neonGlow(GalacticPalette.solarFlux(current), intensity: 4)
                        .monospacedDigit()
                }
            }
            Chart {
                ForEach(points, id: \.time) { p in
                    AreaMark(
                        x: .value("Time", p.time),
                        y: .value("Flux", p.flux)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GalacticPalette.sun.opacity(0.45),
                                GalacticPalette.sun.opacity(0.02),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Time", p.time),
                        y: .value("Flux", p.flux)
                    )
                    .foregroundStyle(GalacticPalette.sun)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                RuleMark(y: .value("HF threshold", 100))
                    .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.electricBlue.opacity(0.6))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
            .frame(height: 110)
            HStack {
                if let lo {
                    Text("min \(String(format: "%.0f", lo))")
                }
                Spacer()
                if let hi {
                    Text("max \(String(format: "%.0f", hi))")
                }
            }
            .font(.firaCode(.caption2))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func hfPanel(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HF propagation")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            Text(summary)
                .font(.firaCode(.caption))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.40))
        )
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        let client = SolarAlmanacClient(userAgent: config.userAgent)
        almanac = await client.fetch()
        if almanac?.kp.isEmpty == true && almanac?.flux.isEmpty == true {
            loadError = "SWPC historical feed unavailable. Pull to retry."
        } else {
            loadError = nil
        }
    }
}
