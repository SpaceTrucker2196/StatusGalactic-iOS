import SwiftUI

struct MeshtasticView: View {
    @Environment(MeshtasticService.self) private var service
    @State private var vm = MeshtasticViewModel()

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                if !service.knownNodes.isEmpty {
                    nodesSection
                }
                trafficSection
                deviceLogSection
                sendSection
            }
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("Mesh")
            .toolbarTitleDisplayMode(.inline)
        }
        .tint(GalacticPalette.neonCyan)
        .onAppear { service.appeared() }
    }

    // MARK: - STATUS

    @ViewBuilder
    private var statusSection: some View {
        PhosphorSection("STATUS") {
            VStack(alignment: .leading, spacing: 8) {
                Text(service.status.label)
                    .font(.firaCode(.body, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .neonGlow(statusColor, intensity: 4)
                if let own = service.ownNodeNum {
                    Text(String(format: "Own node: !%08x", own))
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.peach)
                }
            }
            .listRowBackground(Color.black.opacity(0.35))

            scanRow

            if !service.discoveredNodes.isEmpty {
                ForEach(service.discoveredNodes) { peer in
                    Button {
                        service.connect(peer.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(peer.name)
                                    .font(.firaCode(.body, weight: .semibold))
                                    .foregroundStyle(GalacticPalette.neonCyan)
                                Text("RSSI \(peer.rssi) dBm")
                                    .font(.firaCode(.caption))
                                    .foregroundStyle(GalacticPalette.peach)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(GalacticPalette.phosphorGreen)
                        }
                    }
                    .listRowBackground(Color.black.opacity(0.35))
                }
            }

            if case .connected = service.status {
                Button(role: .destructive) {
                    service.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "bolt.horizontal.fill")
                        .font(.firaCode(.body, weight: .semibold))
                }
                .listRowBackground(Color.black.opacity(0.35))
            }

            clearHistoryButton
        }
    }

    @ViewBuilder
    private var scanRow: some View {
        switch service.status {
        case .scanning:
            Button {
                service.stopScan()
            } label: {
                Label("Stop scanning", systemImage: "stop.circle.fill")
                    .font(.firaCode(.body, weight: .semibold))
                    .foregroundStyle(GalacticPalette.hotPink)
            }
            .listRowBackground(Color.black.opacity(0.35))
        case .connected, .connecting, .disconnecting:
            EmptyView()
        case .bluetoothOff, .bluetoothUnauthorized, .bluetoothUnsupported:
            Text("Bluetooth must be on to find nodes.")
                .font(.firaCode(.caption))
                .foregroundStyle(GalacticPalette.peach)
                .listRowBackground(Color.black.opacity(0.35))
        default:
            Button {
                service.startScan()
            } label: {
                Label("Scan for Meshtastic nodes", systemImage: "dot.radiowaves.left.and.right")
                    .font(.firaCode(.body, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
            }
            .listRowBackground(Color.black.opacity(0.35))
        }
    }

    @ViewBuilder
    private var clearHistoryButton: some View {
        Button(role: .destructive) {
            if vm.clearArmed {
                service.clearHistory()
                vm.clearArmed = false
            } else {
                vm.clearArmed = true
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    vm.clearArmed = false
                }
            }
        } label: {
            Label(
                vm.clearArmed ? "Tap again to confirm clear" : "Clear history",
                systemImage: vm.clearArmed ? "exclamationmark.triangle.fill" : "trash"
            )
            .font(.firaCode(.caption, weight: .semibold))
        }
        .listRowBackground(Color.black.opacity(0.35))
    }

    private var statusColor: Color {
        switch service.status {
        case .connected:                                       return GalacticPalette.phosphorGreen
        case .scanning, .connecting, .disconnecting:           return GalacticPalette.neonCyan
        case .failed, .bluetoothOff,
             .bluetoothUnauthorized, .bluetoothUnsupported:    return GalacticPalette.hotPink
        case .idle:                                            return GalacticPalette.peach
        }
    }

    // MARK: - NODES

    @ViewBuilder
    private var nodesSection: some View {
        PhosphorSection("NODES") {
            // Most-recently-heard at the top; nodes without a last-heard
            // value sort to the bottom.
            let sorted = service.knownNodes.values.sorted { a, b in
                (a.lastHeard ?? .distantPast) > (b.lastHeard ?? .distantPast)
            }
            ForEach(sorted) { node in
                NavigationLink {
                    MeshtasticNodeDetailView(nodeNum: node.id)
                } label: {
                    nodeRow(node)
                }
                .listRowBackground(Color.black.opacity(0.35))
            }
        }
    }

    @ViewBuilder
    private func nodeRow(_ node: MeshtasticService.KnownNode) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(node.shortName.isEmpty
                        ? String(format: "!%08x", UInt32(truncatingIfNeeded: node.id))
                        : node.shortName)
                    .font(.firaCode(.body, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                if !node.longName.isEmpty {
                    Text(node.longName)
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(GalacticPalette.peach)
                        .lineLimit(2)
                }
                if let lastHeard = node.lastHeard {
                    Text(relativeTimeString(lastHeard))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.mint)
                } else {
                    Text("never heard")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.6))
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                if let snr = node.snr {
                    Text(String(format: "%+.1f dB", snr))
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(GalacticPalette.phosphorGreen)
                        .neonGlow(GalacticPalette.phosphorGreen, intensity: 2)
                }
                if let batt = node.batteryLevel {
                    Text("\(batt)%")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(batt < 20 ? GalacticPalette.hotPink : GalacticPalette.mint)
                }
            }
        }
    }

    private func relativeTimeString(_ date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return "heard " + fmt.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - TRAFFIC

    @ViewBuilder
    private var trafficSection: some View {
        PhosphorSection("TRAFFIC") {
            HStack {
                Text("\(service.traffic.count) entries")
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Button {
                    vm.trafficPaused.toggle()
                } label: {
                    Label(
                        vm.trafficPaused ? "Resume" : "Pause",
                        systemImage: vm.trafficPaused ? "play.fill" : "pause.fill"
                    )
                    .font(.firaCode(.caption, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(GalacticPalette.phosphorGreen)
            }
            .listRowBackground(Color.black.opacity(0.35))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(service.traffic) { entry in
                            trafficRow(entry).id(entry.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 280)
                .onChange(of: service.traffic.count) { _, _ in
                    guard !vm.trafficPaused else { return }
                    if let last = service.traffic.last?.id {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            .listRowBackground(Color.black.opacity(0.35))
        }
    }

    @ViewBuilder
    private func trafficRow(_ entry: MeshtasticService.TrafficEntry) -> some View {
        let glow: Color = entry.direction == .rx
            ? GalacticPalette.phosphorGreen
            : GalacticPalette.neonCyan
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.summary)
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(glow)
                .neonGlow(glow, intensity: 3)
                .lineLimit(2)
            Text("[\(timeString(entry.timestamp))] \(entry.rawHex)")
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeString(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss.SSS"
        return fmt.string(from: d)
    }

    // MARK: - DEVICE LOG

    @ViewBuilder
    private var deviceLogSection: some View {
        if !service.deviceLog.isEmpty {
            PhosphorSection("DEVICE LOG") {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(service.deviceLog.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.mint)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 180)
                .listRowBackground(Color.black.opacity(0.35))
            }
        }
    }

    // MARK: - SEND

    @ViewBuilder
    private var sendSection: some View {
        PhosphorSection("SEND") {
            HStack {
                TextField("Message…", text: $vm.composeText, axis: .vertical)
                    .font(.firaCode(.body))
                    .foregroundStyle(GalacticPalette.peach)
                    .lineLimit(1...3)
                    .submitLabel(.send)
                    .onSubmit(sendNow)
                Button(action: sendNow) {
                    Image(systemName: "paperplane.fill")
                        .font(.firaCode(.body, weight: .bold))
                }
                .disabled(!canSend)
                .tint(canSend ? GalacticPalette.neonCyan : GalacticPalette.peach)
            }
            .listRowBackground(Color.black.opacity(0.35))

            if !service.chat.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(service.chat) { msg in
                                chatRow(msg).id(msg.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 220)
                    .onChange(of: service.chat.count) { _, _ in
                        if let last = service.chat.last?.id {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.35))
            }
        }
    }

    private var canSend: Bool {
        if case .connected = service.status {
            return !vm.composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    private func sendNow() {
        let text = vm.composeText
        guard canSend else { return }
        service.sendBroadcast(text)
        vm.composeText = ""
    }

    @ViewBuilder
    private func chatRow(_ msg: MeshtasticService.ChatEntry) -> some View {
        let tint: Color = msg.isOutbound
            ? GalacticPalette.neonCyan
            : GalacticPalette.phosphorGreen
        VStack(alignment: msg.isOutbound ? .trailing : .leading, spacing: 1) {
            Text("\(msg.fromName) · \(timeString(msg.timestamp))")
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.8))
            Text(msg.text)
                .font(.firaCode(.body))
                .foregroundStyle(tint)
                .neonGlow(tint, intensity: 3)
                .frame(maxWidth: .infinity, alignment: msg.isOutbound ? .trailing : .leading)
        }
    }
}

#Preview {
    MeshtasticView()
        .environment(MeshtasticService(inMemoryStore: true))
}
