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
                Section("Callsign") {
                    TextField("e.g. W9FJC", text: $call)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3.monospaced())
                }
                Section("Label (optional)") {
                    TextField("e.g. Jeff's rig", text: $label)
                }
                Section("Notes (optional)") {
                    TextField("e.g. La Crosse base", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Callsign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(CallsignStore.normalize(call).isEmpty)
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
