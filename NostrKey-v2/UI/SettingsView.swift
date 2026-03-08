import SwiftUI

/// App settings and key management
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showExportWarning = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // Active Profile
                if let profile = appState.activeProfile {
                    Section("Active Identity") {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(NostrKeyTheme.accent)
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .fontWeight(.medium)
                                    .foregroundStyle(NostrKeyTheme.text)
                                Text(profile.displayNpub)
                                    .font(.caption)
                                    .foregroundStyle(NostrKeyTheme.textMuted)
                            }
                        }
                        .listRowBackground(NostrKeyTheme.bgLight)
                    }
                }

                // Security
                Section("Security") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(NostrKeyTheme.accent)
                        Text("Secure Enclave")
                            .foregroundStyle(NostrKeyTheme.text)
                        Spacer()
                        Text(appState.activeProfile?.isSecureEnclave == true ? "Active" : "Inactive")
                            .foregroundStyle(NostrKeyTheme.textMuted)
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)

                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(NostrKeyTheme.cyan)
                        Text("Biometric Authentication")
                            .foregroundStyle(NostrKeyTheme.text)
                        Spacer()
                        Text("Required for signing")
                            .font(.caption)
                            .foregroundStyle(NostrKeyTheme.textMuted)
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)
                }

                // Connected Sessions
                Section("NIP-46 Sessions") {
                    if appState.activeSessions.isEmpty {
                        Text("No active sessions")
                            .foregroundStyle(NostrKeyTheme.textMuted)
                            .listRowBackground(NostrKeyTheme.bgLight)
                    } else {
                        ForEach(appState.activeSessions) { session in
                            HStack {
                                Circle()
                                    .fill(session.isActive ? NostrKeyTheme.accent : NostrKeyTheme.textMuted)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading) {
                                    Text(session.appName ?? "Unknown App")
                                        .fontWeight(.medium)
                                        .foregroundStyle(NostrKeyTheme.text)
                                    Text(session.relayURL)
                                        .font(.caption)
                                        .foregroundStyle(NostrKeyTheme.textMuted)
                                }
                            }
                            .listRowBackground(NostrKeyTheme.bgLight)
                        }
                    }
                }

                // Key Management
                Section("Key Management") {
                    Button {
                        showExportWarning = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Keys (nsec)")
                        }
                        .foregroundStyle(NostrKeyTheme.orange)
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)

                    NavigationLink {
                        ProfileListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                            Text("Manage Profiles")
                                .foregroundStyle(NostrKeyTheme.text)
                        }
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(NostrKeyTheme.text)
                        Spacer()
                        Text("2.0.0 (1)")
                            .foregroundStyle(NostrKeyTheme.textMuted)
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)

                    Link(destination: URL(string: "https://nostrkey.com")!) {
                        HStack {
                            Text("Website")
                                .foregroundStyle(NostrKeyTheme.text)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(NostrKeyTheme.textMuted)
                        }
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)

                    Link(destination: URL(string: "https://github.com/ArcadeLabsInc/nostrkey")!) {
                        HStack {
                            Text("Source Code")
                                .foregroundStyle(NostrKeyTheme.text)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(NostrKeyTheme.textMuted)
                        }
                    }
                    .listRowBackground(NostrKeyTheme.bgLight)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NostrKeyTheme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Export Warning", isPresented: $showExportWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Export", role: .destructive) {
                    // TODO: Export keys with biometric confirmation
                }
            } message: {
                Text("Exporting your nsec (private key) allows anyone who has it to control your Nostr identity. Only export if you need to back up or move your key. Never share it.")
            }
        }
    }
}

// MARK: - Profile List

struct ProfileListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            ForEach(appState.profiles) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name)
                            .fontWeight(.medium)
                            .foregroundStyle(NostrKeyTheme.text)
                        Text(profile.displayNpub)
                            .font(.caption)
                            .foregroundStyle(NostrKeyTheme.textMuted)
                    }

                    Spacer()

                    if profile.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(NostrKeyTheme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setActiveProfile(profile)
                }
                .listRowBackground(NostrKeyTheme.bgLight)
            }
        }
        .scrollContentBackground(.hidden)
        .background(NostrKeyTheme.bg.ignoresSafeArea())
        .navigationTitle("Profiles")
    }

    private func setActiveProfile(_ profile: NostrProfile) {
        for i in appState.profiles.indices {
            appState.profiles[i].isActive = (appState.profiles[i].id == profile.id)
        }
        appState.activeProfile = profile
        appState.saveProfiles()
    }
}
