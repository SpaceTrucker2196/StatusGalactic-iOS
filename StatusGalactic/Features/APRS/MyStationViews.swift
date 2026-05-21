import SwiftUI

/// Rich detail rows under the station header on the APRS tab. Renders every
/// useful field aprs.fi returns for the user's own callsign.
struct MyStationFixRows: View {
    let fix: APRSFix

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Position",
                String(format: "%.4f, %.4f", fix.lat, fix.lng),
                color: GalacticPalette.peach)
            if let course = fix.courseDeg {
                row("Course",
                    String(format: "%.0f° %@", course, compass(for: course)),
                    color: GalacticPalette.hotPink)
            }
            if let speed = fix.speedKmh, speed > 0 {
                let mph = speed * 0.6213712
                let knots = speed * 0.5399568
                row("Speed",
                    String(format: "%.0f km/h · %.0f mph · %.0f kt", speed, mph, knots),
                    color: GalacticPalette.electricBlue)
            }
            if let alt = fix.altitudeM {
                let ft = alt * 3.28084
                row("Altitude",
                    String(format: "%.0f m (%.0f ft)", alt, ft),
                    color: GalacticPalette.mint)
            }
            if let symbol = fix.symbol, !symbol.isEmpty {
                row("Symbol", symbol, color: GalacticPalette.neonCyan)
            }
            if let kind = fix.stationType, !kind.isEmpty {
                row("Type", stationTypeLabel(kind), color: GalacticPalette.peach)
            }
            if let status = fix.statusMessage {
                row("Status", status, color: GalacticPalette.neonCyan)
            }
            if let comment = fix.comment, !comment.isEmpty {
                row("Comment", comment, color: GalacticPalette.peach.opacity(0.9))
            }
            if let path = fix.path, !path.isEmpty {
                row("Path", path, color: GalacticPalette.peach.opacity(0.85))
            }
            if let phg = fix.phg, !phg.isEmpty {
                row("PHG", phg, color: GalacticPalette.neonCyan)
            }
            if let last = fix.lastTime {
                HStack {
                    Text("Last heard")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(last, style: .relative)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                }
            }
        }
    }

    private func row(_ label: String, _ value: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)
            Text(value)
                .font(.firaCode(.caption))
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(2)
        }
    }

    private func compass(for course: Double) -> String {
        let normalized = course.truncatingRemainder(dividingBy: 360)
        let bearing = normalized < 0 ? normalized + 360 : normalized
        let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                    "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        return dirs[Int((bearing / 22.5).rounded()) % 16]
    }

    private func stationTypeLabel(_ type: String) -> String {
        switch type.lowercased() {
        case "l": return "APRS station"
        case "i": return "APRS item"
        case "o": return "APRS object"
        case "w": return "Weather station"
        case "a": return "AIS vessel"
        default:  return type
        }
    }
}

/// One row in the station log. Compact: time + coords + speed if moving.
struct StationLogRow: View {
    let entry: APRSStationLogEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(GalacticPalette.electricBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.observedAt, style: .relative)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Text(String(format: "%.4f, %.4f", entry.lat, entry.lng))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let speed = entry.speedKmh, speed > 0 {
                Text(String(format: "%.0f km/h", speed))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.hotPink)
                    .monospacedDigit()
            }
        }
    }
}
