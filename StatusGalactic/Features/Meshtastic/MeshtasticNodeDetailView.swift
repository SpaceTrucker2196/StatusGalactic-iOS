import SwiftUI

/// Per-node detail page reached by tapping a row in the Mesh tab's NODES
/// section. Shows the running radio-quality snapshot, a bar graph of the
/// SNR history, and a filtered slice of the TRAFFIC log for this node.
struct MeshtasticNodeDetailView: View {
    let nodeNum: Int
    @Environment(MeshtasticService.self) private var service

    /// Re-resolve the node from the service every body eval so the view
    /// updates live as new packets arrive.
    private var node: MeshtasticService.KnownNode? {
        service.knownNodes[nodeNum]
    }

    private var nodeTraffic: [MeshtasticService.TrafficEntry] {
        service.traffic.filter { $0.fromNodeNum == nodeNum }
    }

    var body: some View {
        Form {
            identitySection
            signalSection
            metricsSection
            if hasPosition {
                positionSection
            }
            recentTrafficSection
        }
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle(headerTitle)
        .toolbarTitleDisplayMode(.inline)
        .tint(GalacticPalette.neonCyan)
    }

    // MARK: - IDENTITY

    @ViewBuilder
    private var identitySection: some View {
        PhosphorSection("IDENTITY") {
            VStack(alignment: .leading, spacing: 4) {
                if let short = node?.shortName, !short.isEmpty {
                    Text(short)
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .neonGlow(GalacticPalette.neonCyan, intensity: 4)
                }
                if let long = node?.longName, !long.isEmpty {
                    Text(long)
                        .font(.firaCode(.body))
                        .foregroundStyle(GalacticPalette.peach)
                }
                Text(formattedNodeID)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.phosphorGreen)
                    .neonGlow(GalacticPalette.phosphorGreen, intensity: 3)
                if let lastHeard = node?.lastHeard {
                    Text("Last heard \(relativeTimeString(lastHeard)) · \(absoluteTimeString(lastHeard))")
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.mint)
                } else {
                    Text("Last heard never")
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                }
            }
            .listRowBackground(Color.black.opacity(0.35))
        }
    }

    // MARK: - SIGNAL

    @ViewBuilder
    private var signalSection: some View {
        PhosphorSection("SIGNAL") {
            HStack(spacing: 16) {
                metricCell(
                    label: "SNR",
                    value: node?.snr.map { String(format: "%+.1f dB", $0) } ?? "—",
                    color: snrColor(node?.snr)
                )
                metricCell(
                    label: "RSSI",
                    value: node?.rssi.map { "\($0) dBm" } ?? "—",
                    color: rssiColor(node?.rssi)
                )
                metricCell(
                    label: "Samples",
                    value: "\(node?.snrHistory.count ?? 0)",
                    color: GalacticPalette.peach
                )
            }
            .listRowBackground(Color.black.opacity(0.35))

            SNRBarGraph(samples: node?.snrHistory ?? [])
                .frame(height: 96)
                .padding(.vertical, 6)
                .listRowBackground(Color.black.opacity(0.35))
        }
    }

    // MARK: - METRICS

    @ViewBuilder
    private var metricsSection: some View {
        if node?.batteryLevel != nil {
            PhosphorSection("METRICS") {
                if let batt = node?.batteryLevel {
                    HStack {
                        Text("Battery")
                            .font(.firaCode(.body, weight: .semibold))
                            .foregroundStyle(GalacticPalette.peach)
                        Spacer()
                        Text("\(batt)%")
                            .font(.firaCode(.body, weight: .bold))
                            .foregroundStyle(batt < 20 ? GalacticPalette.hotPink : GalacticPalette.mint)
                            .neonGlow(batt < 20 ? GalacticPalette.hotPink : GalacticPalette.mint, intensity: 3)
                    }
                    .listRowBackground(Color.black.opacity(0.35))
                }
            }
        }
    }

    // MARK: - POSITION

    private var hasPosition: Bool {
        (node?.latitudeI ?? 0) != 0 && (node?.longitudeI ?? 0) != 0
    }

    @ViewBuilder
    private var positionSection: some View {
        PhosphorSection("POSITION") {
            VStack(alignment: .leading, spacing: 4) {
                if let latI = node?.latitudeI, let lngI = node?.longitudeI {
                    // Meshtastic positions are reported as integer degrees
                    // ×1e7 — convert for display.
                    let lat = Double(latI) / 1e7
                    let lng = Double(lngI) / 1e7
                    Text(String(format: "Lat %.5f°", lat))
                        .font(.firaCode(.body))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    Text(String(format: "Lng %.5f°", lng))
                        .font(.firaCode(.body))
                        .foregroundStyle(GalacticPalette.neonCyan)
                }
            }
            .listRowBackground(Color.black.opacity(0.35))
        }
    }

    // MARK: - TRAFFIC FOR THIS NODE

    @ViewBuilder
    private var recentTrafficSection: some View {
        PhosphorSection("RECENT TRAFFIC") {
            if nodeTraffic.isEmpty {
                Text("No packets from this node in the live feed yet.")
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                    .listRowBackground(Color.black.opacity(0.35))
            } else {
                ForEach(nodeTraffic.suffix(40).reversed()) { entry in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.summary)
                            .font(.firaCode(.caption, weight: .semibold))
                            .foregroundStyle(GalacticPalette.phosphorGreen)
                            .neonGlow(GalacticPalette.phosphorGreen, intensity: 2)
                            .lineLimit(2)
                        Text("[\(absoluteTimeString(entry.timestamp))]")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                    }
                    .listRowBackground(Color.black.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Helpers

    private var headerTitle: String {
        if let short = node?.shortName, !short.isEmpty { return short }
        if let long = node?.longName, !long.isEmpty { return long }
        return formattedNodeID
    }

    private var formattedNodeID: String {
        String(format: "!%08x", UInt32(truncatingIfNeeded: nodeNum))
    }

    @ViewBuilder
    private func metricCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.85))
            Text(value)
                .font(.firaCode(.body, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func snrColor(_ snr: Float?) -> Color {
        guard let snr else { return GalacticPalette.peach }
        if snr >= 5  { return GalacticPalette.phosphorGreen }
        if snr >= 0  { return GalacticPalette.mint }
        if snr >= -5 { return GalacticPalette.peach }
        if snr >= -10 { return GalacticPalette.sunsetOrange }
        return GalacticPalette.hotPink
    }

    private func rssiColor(_ rssi: Int?) -> Color {
        guard let rssi else { return GalacticPalette.peach }
        if rssi >= -70  { return GalacticPalette.phosphorGreen }
        if rssi >= -90  { return GalacticPalette.mint }
        if rssi >= -110 { return GalacticPalette.peach }
        return GalacticPalette.hotPink
    }

    private func relativeTimeString(_ date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: Date())
    }

    private func absoluteTimeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: date)
    }
}

// MARK: - SNR Bar Graph

/// Vertical bar chart of one node's recent SNR samples. Each bar's height
/// is mapped from the sample's SNR, with the color shifting from
/// phosphor-green (strong) through peach (weak) to hot-pink (very weak).
///
/// Designed to read fine when the history is short (one or two bars) and
/// at the cap (`MeshtasticService.snrHistoryDepth`).
struct SNRBarGraph: View {
    let samples: [MeshtasticService.SNRSample]

    /// Meshtastic SNR typically ranges roughly -20 dB (very weak) to +10 dB
    /// (very strong). We clamp display to this window so a single great
    /// link doesn't dwarf the rest of the history.
    private let minDB: Float = -20
    private let maxDB: Float =  10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                gridlines(in: geo.size)
                if samples.isEmpty {
                    placeholder
                } else {
                    bars(in: geo.size)
                }
                axisLabels(in: geo.size)
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        VStack {
            Spacer()
            Text("No signal samples yet")
                .font(.firaCode(.caption))
                .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func gridlines(in size: CGSize) -> some View {
        // Three horizontal reference lines at -20, -5, +10 dB.
        let bands: [Float] = [maxDB, -5, minDB]
        ZStack(alignment: .topLeading) {
            ForEach(Array(bands.enumerated()), id: \.offset) { idx, db in
                let y = yPosition(for: db, height: size.height)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(
                    GalacticPalette.phosphorGreen.opacity(idx == 1 ? 0.35 : 0.18),
                    style: StrokeStyle(lineWidth: 1, dash: idx == 1 ? [] : [3, 3])
                )
            }
        }
    }

    @ViewBuilder
    private func bars(in size: CGSize) -> some View {
        // Fit up to `snrHistoryDepth` bars across the canvas. With fewer
        // samples each bar is wider; with the cap we get a sparkline-ish
        // density.
        let slotCount = max(samples.count, 1)
        let spacing: CGFloat = 2
        let totalSpacing = spacing * CGFloat(slotCount - 1)
        let barWidth = max(2, (size.width - totalSpacing) / CGFloat(slotCount))

        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(samples.indices, id: \.self) { i in
                let sample = samples[i]
                let h = barHeight(for: sample.snr, height: size.height)
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(color(for: sample.snr))
                    .frame(width: barWidth, height: max(2, h))
                    .neonGlow(color(for: sample.snr), intensity: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func axisLabels(in size: CGSize) -> some View {
        VStack {
            HStack {
                Spacer()
                Text("+10")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.75))
            }
            Spacer()
            HStack {
                Spacer()
                Text("-20 dB")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.75))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func clamp(_ snr: Float) -> Float {
        min(maxDB, max(minDB, snr))
    }

    private func normalized(_ snr: Float) -> CGFloat {
        let c = clamp(snr)
        return CGFloat((c - minDB) / (maxDB - minDB))
    }

    private func barHeight(for snr: Float, height: CGFloat) -> CGFloat {
        normalized(snr) * height
    }

    private func yPosition(for snr: Float, height: CGFloat) -> CGFloat {
        height - normalized(snr) * height
    }

    private func color(for snr: Float) -> Color {
        if snr >= 5  { return GalacticPalette.phosphorGreen }
        if snr >= 0  { return GalacticPalette.mint }
        if snr >= -5 { return GalacticPalette.peach }
        if snr >= -10 { return GalacticPalette.sunsetOrange }
        return GalacticPalette.hotPink
    }
}

#Preview {
    NavigationStack {
        MeshtasticNodeDetailView(nodeNum: Int(0xDEAD_BEEF))
            .environment({
                let svc = MeshtasticService(inMemoryStore: true)
                svc.knownNodes[Int(0xDEAD_BEEF)] = .init(
                    id: Int(0xDEAD_BEEF),
                    shortName: "WX5",
                    longName: "Wax Five — preview",
                    lastHeard: Date(),
                    snr: 4.5,
                    rssi: -78,
                    batteryLevel: 64,
                    latitudeI: 438_600_000,
                    longitudeI: -916_700_000,
                    snrHistory: (0..<20).map { i in
                        .init(timestamp: Date().addingTimeInterval(TimeInterval(-i * 60)),
                              snr: Float.random(in: -15...8))
                    }.reversed()
                )
                return svc
            }())
    }
}
