import SwiftUI

/// Searchable, region-grouped picker for NWS marine forecast zones, with a
/// "None / inland" row at the top and a "Custom code" row at the bottom for
/// zones not in the curated catalog.
struct MarineZonePickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var customCode: String = ""
    @State private var showCustom: Bool = false

    var body: some View {
        NavigationStack {
            List {
                noneSection

                ForEach(filteredRegions, id: \.self) { region in
                    Section(region) {
                        ForEach(filteredZones(in: region)) { zone in
                            zoneRow(zone)
                        }
                    }
                    .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
                }

                customSection
            }
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .searchable(text: $query, prompt: "Search by code or place")
            .navigationTitle("Marine Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var noneSection: some View {
        Section {
            Button {
                selection = ""
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                    Text("None / inland")
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(.primary)
                    Spacer()
                    if selection.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundStyle(GalacticPalette.neonCyan)
                    }
                }
            }
        }
        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
    }

    private var customSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showCustom) {
                HStack {
                    TextField("e.g. AMZ158", text: $customCode)
                        .font(.firaCode(.body))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Use") {
                        let trimmed = customCode.trimmingCharacters(in: .whitespacesAndNewlines)
                            .uppercased()
                        if !trimmed.isEmpty {
                            selection = trimmed
                            dismiss()
                        }
                    }
                    .disabled(customCode.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(GalacticPalette.hotPink)
                    Text("Custom code")
                        .font(.firaCode(.subheadline))
                }
            }
        } footer: {
            Text("Find your zone at weather.gov/marine. Format is REGIONPREFIX + number, e.g. GMZ033.")
                .font(.firaCode(.caption2))
        }
        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
    }

    // MARK: - Rows

    private func zoneRow(_ zone: MarineZone) -> some View {
        Button {
            selection = zone.code
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Text(zone.code)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .frame(width: 64, alignment: .leading)
                Text(zone.name)
                    .font(.firaCode(.subheadline))
                    .foregroundStyle(GalacticPalette.peach)
                    .lineLimit(2)
                Spacer()
                if selection.uppercased() == zone.code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .neonGlow(GalacticPalette.neonCyan, intensity: 4)
                }
            }
        }
    }

    // MARK: - Filtering

    private var filteredRegions: [String] {
        MarineZoneCatalog.orderedRegions.filter { region in
            !filteredZones(in: region).isEmpty
        }
    }

    private func filteredZones(in region: String) -> [MarineZone] {
        let zones = MarineZoneCatalog.zones(in: region)
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return zones }
        let q = query.lowercased()
        return zones.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }
}
