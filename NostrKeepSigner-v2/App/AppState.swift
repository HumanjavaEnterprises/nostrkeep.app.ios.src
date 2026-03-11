import SwiftUI
import Combine

/// Central application state shared across all views
@MainActor
class AppState: ObservableObject {
    // MARK: - Published State

    /// The active Nostr identity (nil if no keys generated yet)
    @Published var activeProfile: NostrProfile?

    /// All stored profiles
    @Published var profiles: [NostrProfile] = []

    /// Connected relays
    @Published var relays: [RelayInfo] = []

    /// Current tab in the main interface
    @Published var selectedTab: AppTab = .home

    /// Whether we're showing the onboarding flow
    @Published var showOnboarding: Bool = false

    /// Active NIP-46 sessions
    @Published var activeSessions: [NIP46Session] = []

    // MARK: - Managers

    let keyManager = KeyManager()
    let relayManager = RelayManager()

    // MARK: - Initialization

    init() {
        loadProfiles()
        loadRelays()
    }

    // MARK: - Profile Management

    func loadProfiles() {
        profiles = keyManager.loadProfiles()
        activeProfile = profiles.first(where: { $0.isActive }) ?? profiles.first

        if profiles.isEmpty {
            showOnboarding = true
        }
    }

    func createNewIdentity(name: String = "Default") async throws {
        let profile = try keyManager.generateKeyPair(name: name)
        profiles.append(profile)
        activeProfile = profile
        showOnboarding = false
        saveProfiles()
    }

    func importKeys(nsec: String, name: String = "Imported") throws {
        let profile = try keyManager.importFromNsec(nsec, name: name)
        profiles.append(profile)
        activeProfile = profile
        showOnboarding = false
        saveProfiles()
    }

    func saveProfiles() {
        keyManager.saveProfiles(profiles)
    }

    // MARK: - Relay Management

    func loadRelays() {
        relays = relayManager.loadRelays()
    }

    func addRelay(url: String, name: String? = nil, paid: Bool = false) {
        let relay = RelayInfo(
            url: url,
            name: name ?? url,
            paid: paid,
            addedAt: Date()
        )
        if !relays.contains(where: { $0.url == url }) {
            relays.append(relay)
            relayManager.saveRelays(relays)
        }
    }

    func removeRelay(at offsets: IndexSet) {
        relays.remove(atOffsets: offsets)
        relayManager.saveRelays(relays)
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable {
    case home = "Home"
    case scanner = "Scanner"
    case identity = "Identity"
    case relays = "Relays"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .scanner: return "qrcode.viewfinder"
        case .identity: return "person.crop.circle"
        case .relays: return "network"
        case .settings: return "gearshape"
        }
    }
}
