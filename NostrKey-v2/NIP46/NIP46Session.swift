import Foundation

/// Represents an active NIP-46 remote signing session
struct NIP46Session: Identifiable, Codable {
    let id: UUID
    let remotePubkey: String     // The client's pubkey requesting signing
    let relayURL: String         // Relay used for communication
    let createdAt: Date
    var lastActiveAt: Date
    var appName: String?         // Name of the connecting app (if provided)
    var isActive: Bool

    init(
        id: UUID = UUID(),
        remotePubkey: String,
        relayURL: String,
        appName: String? = nil
    ) {
        self.id = id
        self.remotePubkey = remotePubkey
        self.relayURL = relayURL
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.appName = appName
        self.isActive = true
    }
}

/// NIP-46 remote signing service
/// Connects to a relay and responds to signing requests from remote clients
class NIP46Signer {

    private var webSocketTask: URLSessionWebSocketTask?
    private let keyManager: KeyManager
    private var session: NIP46Session?

    init(keyManager: KeyManager) {
        self.keyManager = keyManager
    }

    // MARK: - Connection

    /// Initiate a NIP-46 session from a nostrconnect:// URI
    func connect(uri: String) async throws -> NIP46Session {
        guard let url = URL(string: uri),
              url.scheme == "nostrconnect",
              let remotePubkey = url.host else {
            throw NostrError.nip46Error("Invalid nostrconnect URI")
        }

        let params = url.queryParameters
        guard let relayURL = params["relay"] else {
            throw NostrError.nip46Error("Missing relay parameter")
        }

        let session = NIP46Session(
            remotePubkey: remotePubkey,
            relayURL: relayURL,
            appName: params["name"]
        )

        try await connectToRelay(session: session)
        self.session = session
        return session
    }

    /// Connect to the relay WebSocket and start listening
    private func connectToRelay(session: NIP46Session) async throws {
        // Convert wss:// to URL
        guard let url = URL(string: session.relayURL) else {
            throw NostrError.nip46Error("Invalid relay URL")
        }

        let wsSession = URLSession(configuration: .default)
        webSocketTask = wsSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // Subscribe to events addressed to our pubkey
        // ["REQ", subscription_id, { "kinds": [24133], "#p": [our_pubkey] }]
        // TODO: Send subscription filter and start message loop

        startListening()
    }

    /// Listen for incoming NIP-46 requests
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startListening() // Continue listening
            case .failure(let error):
                print("NIP-46 WebSocket error: \(error)")
            }
        }
    }

    /// Handle an incoming WebSocket message
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            // Parse Nostr relay message
            // Expected: ["EVENT", subscription_id, { event_object }]
            // The event content is NIP-04 encrypted and contains the signing request
            processRelayMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                processRelayMessage(text)
            }
        @unknown default:
            break
        }
    }

    /// Process a relay message containing a NIP-46 request
    private func processRelayMessage(_ message: String) {
        // TODO: Implement full NIP-46 message parsing
        // 1. Parse the relay message array
        // 2. Decrypt the NIP-04 encrypted content
        // 3. Parse the NIP-46 request (sign_event, get_public_key, etc.)
        // 4. Prompt user for biometric confirmation
        // 5. Sign the event using KeyManager
        // 6. Encrypt the response and send back via relay
        print("NIP-46 message received: \(message.prefix(100))")
    }

    // MARK: - Request Handling

    /// Handle a sign_event request
    func handleSignRequest(eventJSON: String, fromPubkey: String) async throws -> String {
        // TODO: Parse event, compute event ID, sign with Schnorr
        // This requires biometric confirmation via KeyManager.signEvent()
        throw NostrError.nip46Error("Not yet implemented")
    }

    /// Handle a get_public_key request
    func handleGetPublicKey() throws -> String {
        // Return our active profile's pubkey
        throw NostrError.nip46Error("Not yet implemented")
    }

    // MARK: - Disconnect

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.isActive = false
    }
}
