import SwiftUI

/// Displays and manages the user's relay connections
struct RelayListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddRelay = false
    @State private var newRelayURL = ""

    var body: some View {
        NavigationStack {
            List {
                if appState.relays.isEmpty {
                    ContentUnavailableView {
                        Label("No Relays", systemImage: "network")
                            .foregroundStyle(NostrKeyTheme.textMuted)
                    } description: {
                        Text("Add a relay to connect to the Nostr network. Scan a QR code or add one manually.")
                            .foregroundStyle(NostrKeyTheme.textMuted.opacity(0.7))
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(appState.relays) { relay in
                        RelayRow(relay: relay)
                            .listRowBackground(NostrKeyTheme.bgLight)
                    }
                    .onDelete(perform: appState.removeRelay)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NostrKeyTheme.bg.ignoresSafeArea())
            .navigationTitle("Relays")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddRelay = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRelay) {
                AddRelaySheet(relayURL: $newRelayURL) {
                    if !newRelayURL.isEmpty {
                        let url = newRelayURL.hasPrefix("wss://") || newRelayURL.hasPrefix("ws://")
                            ? newRelayURL
                            : "wss://\(newRelayURL)"
                        appState.addRelay(url: url)
                        newRelayURL = ""
                        showAddRelay = false
                    }
                }
            }
        }
    }
}

// MARK: - Relay Row

struct RelayRow: View {
    let relay: RelayInfo

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(relay.isConnected ? NostrKeyTheme.accent : .gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(relay.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(NostrKeyTheme.text)

                    if relay.paid {
                        Text("PAID")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(NostrKeyTheme.orange.opacity(0.2))
                            .foregroundStyle(NostrKeyTheme.orange)
                            .clipShape(Capsule())
                    }
                }

                Text(relay.url)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(NostrKeyTheme.textMuted)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Relay Sheet

struct AddRelaySheet: View {
    @Binding var relayURL: String
    @Environment(\.dismiss) var dismiss
    let onAdd: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter a relay WebSocket URL, or scan a QR code from the Scanner tab.")
                    .font(.subheadline)
                    .foregroundStyle(NostrKeyTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("wss://relay.example.com", text: $relayURL)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(NostrKeyTheme.bgLight)
                    .foregroundStyle(NostrKeyTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(NostrKeyTheme.accent.opacity(0.3), lineWidth: 1)
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(.horizontal)

                Button("Add Relay") {
                    onAdd()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(relayURL.isEmpty ? NostrKeyTheme.bgLight : NostrKeyTheme.accent)
                .foregroundStyle(relayURL.isEmpty ? NostrKeyTheme.textMuted : NostrKeyTheme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .disabled(relayURL.isEmpty)

                Spacer()
            }
            .padding(.top, 24)
            .background(NostrKeyTheme.bg.ignoresSafeArea())
            .navigationTitle("Add Relay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
