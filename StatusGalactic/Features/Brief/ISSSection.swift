import SwiftUI
import MapKit

struct ISSCard: View {
    let iss: ISSPosition
    let observerLat: Double
    let observerLng: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            mapPreview
            statsGrid
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "satellite.fill")
                .foregroundStyle(GalacticPalette.neonCyan)
                .neonGlow(GalacticPalette.neonCyan, intensity: 5)
            Text("ISS")
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
            Marker("ISS", systemImage: "satellite.fill", coordinate: issCoord)
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
