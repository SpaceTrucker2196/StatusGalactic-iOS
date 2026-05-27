import SwiftUI

struct AddCallsignView: View {
    @Environment(CallsignStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var call: String = ""
    @State private var label: String = ""
    @State private var notes: String = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                PhosphorSection("Callsign") {
                    TextField("e.g. W9FJC", text: $call)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .accessibilityIdentifier(A11yID.Callsigns.AddForm.call)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
                PhosphorSection("Label (optional)") {
                    TextField("e.g. Jeff's rig", text: $label)
                        .font(.firaCode(.body))
                        .accessibilityIdentifier(A11yID.Callsigns.AddForm.label)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
                PhosphorSection("Notes (optional)") {
                    TextField("e.g. La Crosse base", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.firaCode(.body))
                        .accessibilityIdentifier(A11yID.Callsigns.AddForm.notes)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(GalacticPalette.storm)
                    }
                    .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
                }
            }
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("Add Callsign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GalacticPalette.cosmicBlack.opacity(0.85), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(A11yID.Callsigns.AddForm.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(CallsignStore.normalize(call).isEmpty)
                        .accessibilityIdentifier(A11yID.Callsigns.AddForm.save)
                }
            }
        }
    }

    private func save() {
        let normalized = CallsignStore.normalize(call)
        if normalized.isEmpty {
            error = "Callsign is required."
            return
        }
        guard store.add(normalized, label: label, notes: notes) != nil else {
            error = "\(normalized) is already in the list."
            return
        }
        dismiss()
    }
}
