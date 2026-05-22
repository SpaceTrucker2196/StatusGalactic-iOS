import SwiftUI
import MapKit

/// Generic crewed-spacecraft card. Originally written for the ISS; now also
/// renders Tianhe / Tiangong and anything else `CrewedSpacecraftCatalog`
/// exposes. The `iss` parameter name is preserved internally to avoid
/// touching every call site.
struct ISSCard: View {
    let iss: CrewedObject
    let observerLat: Double
    let observerLng: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            mapPreview
            statsGrid
            if !iss.passes.isEmpty {
                Divider().overlay(GalacticPalette.neonCyan.opacity(0.4))
                passesSection
            }
            footer
        }
    }

    private var passesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next visible passes")
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            ForEach(iss.passes.prefix(3)) { pass in
                PassRow(pass: pass)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.up.forward")
                .foregroundStyle(GalacticPalette.neonCyan)
                .neonGlow(GalacticPalette.neonCyan, intensity: 5)
            Text(iss.name)
                .font(.firaCode(.headline, weight: .bold))
                .foregroundStyle(GalacticPalette.neonCyan)
            Spacer()
            if let visibility = iss.visibility {
                Text(visibility.capitalized)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(visibility == "daylight"
                                     ? GalacticPalette.daylight
                                     : GalacticPalette.electricBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(GalacticPalette.deepPurple.opacity(0.6))
                    )
                    .overlay(
                        Capsule().stroke(
                            visibility == "daylight"
                                ? GalacticPalette.daylight
                                : GalacticPalette.electricBlue,
                            lineWidth: 0.5
                        )
                    )
            }
        }
    }

    private var mapPreview: some View {
        let issCoord = CLLocationCoordinate2D(latitude: iss.latitude, longitude: iss.longitude)
        let observerCoord = CLLocationCoordinate2D(latitude: observerLat, longitude: observerLng)
        let midLat = (iss.latitude + observerLat) / 2
        let midLng = (iss.longitude + observerLng) / 2
        let span = max(60, min(120, abs(iss.latitude - observerLat) * 2 + abs(iss.longitude - observerLng) * 2 + 30))
        let region = MKCoordinateRegion(
            center: .init(latitude: midLat, longitude: midLng),
            span: .init(latitudeDelta: span, longitudeDelta: span)
        )
        return Map(initialPosition: .region(region)) {
            Marker(iss.name, systemImage: "dot.radiowaves.up.forward", coordinate: issCoord)
                .tint(GalacticPalette.neonCyan)
            Marker("Me", systemImage: "location.fill", coordinate: observerCoord)
                .tint(GalacticPalette.hotPink)
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(GalacticPalette.neonCyan.opacity(0.5), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }

    private var statsGrid: some View {
        HStack(spacing: 14) {
            stat(label: "Lat",     value: String(format: "%.2f°", iss.latitude),         color: GalacticPalette.peach)
            stat(label: "Lng",     value: String(format: "%.2f°", iss.longitude),        color: GalacticPalette.peach)
            stat(label: "Alt",     value: "\(Int(iss.altitudeKm)) km",                   color: GalacticPalette.mint)
            stat(label: "Speed",   value: "\(Int(iss.velocityKmh)) km/h",                color: GalacticPalette.hotPink)
        }
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        Text("As of \(iss.observedAt, style: .relative) ago • wheretheiss.at")
            .font(.firaCode(.caption2))
            .foregroundStyle(.secondary)
    }
}

private struct PassRow: View {
    let pass: ISSPass

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                Text(pass.startUTC, style: .date)
                    .font(.firaCode(.caption, weight: .semibold))
                Text(pass.startUTC, style: .time)
                    .font(.firaCode(.caption))
                Spacer()
                if let mag = pass.magnitude {
                    Text(String(format: "mag %.1f", mag))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(brightnessColor(for: mag))
                        .neonGlow(brightnessColor(for: mag), intensity: 3)
                }
            }
            HStack(spacing: 6) {
                if let s = pass.startAzCompass {
                    Text(s)
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(GalacticPalette.hotPink)
                }
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("max \(Int(pass.maxElevation.rounded()))° elev")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let e = pass.endAzCompass {
                    Text(e)
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(GalacticPalette.hotPink)
                }
                Spacer()
                Text("\(pass.durationSeconds / 60)m \(pass.durationSeconds % 60)s")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func brightnessColor(for mag: Double) -> Color {
        switch mag {
        case ..<(-3): return GalacticPalette.neonMagenta   // very bright
        case ..<(-2): return GalacticPalette.hotPink
        case ..<(-1): return GalacticPalette.active
        default:      return GalacticPalette.peach
        }
    }
}
