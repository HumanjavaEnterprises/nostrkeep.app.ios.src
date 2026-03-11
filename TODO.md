# NostrKeep Signer iOS App TODO

## NIP-46 Bunker Implementation — QR Scan + Remote Signing

**Status:** Scaffolded — needs crypto + business logic
**Depends on:** `swift-secp256k1` package integration
**Context:** The browser extension (NostrKey) already has complete NIP-46. The iOS app has the UI skeleton (QR scanner, session struct, WebSocket init) but can't sign yet. MVP auth testing is happening via browser extension paste flow first (see `nostrkeep.bizdocs.src/TODO.md` Phase 2E).

### What's Already Built
- QR scanner (DataScannerViewController, full lifecycle, haptic feedback)
- Recognizes `bunker://` and `nostrconnect://` URLs from scans
- URL scheme registration (`nostrkeepsigner://`, `nostrconnect://`)
- NIP46Session struct with all fields (remotePubkey, relayURL, appName, etc.)
- WebSocket task initialized (URLSessionWebSocketTask)
- Deep link handler routing

### Implementation Tasks (in dependency order)

1. **Add `swift-secp256k1` package** — CRITICAL BLOCKER
   - [ ] Add to Xcode project dependencies (SPM)
   - [ ] Wire into KeyManager for real key derivation from nsec
   - [ ] Implement BIP-340 Schnorr signing (`KeyManager.signEvent()`)

2. **NIP-46 Message Flow**
   - [ ] Send REQ subscription: `["REQ", sub_id, {"kinds": [24133], "#p": [our_pubkey]}]`
   - [ ] Parse incoming Nostr relay messages: `["EVENT", sub_id, { event }]`
   - [ ] Implement NIP-04 decryption (AES-128-CBC) for NIP-46 message content
   - [ ] Extract NIP-46 request JSON: `{"id", "method", "params"}`
   - [ ] Handle methods: `connect`, `sign_event`, `get_public_key`, `get_relays`, `ping`

3. **Signing Approval UI**
   - [ ] SwiftUI view showing sign request details (kind, content preview, requesting app)
   - [ ] Approve / Deny buttons
   - [ ] Biometric confirmation (Face ID / Touch ID) via LocalAuthentication
   - [ ] Optional "always approve" per kind (like browser extension UX)

4. **Response Flow**
   - [ ] Sign the requested event with Schnorr
   - [ ] Encrypt response with NIP-04 using remote pubkey
   - [ ] Wrap in kind 24133 event, tag remote pubkey
   - [ ] Publish to relay: `["EVENT", signed_response_event]`

5. **Session Persistence**
   - [ ] Save active NIP-46 sessions to UserDefaults or KeyManager
   - [ ] Restore sessions on app relaunch
   - [ ] Auto-reconnect WebSocket on connection drop
   - [ ] Session expiry handling

6. **Error Handling + UX**
   - [ ] Toast/alert for relay disconnection
   - [ ] Notification badge when sign request pending
   - [ ] Error state in scanner for invalid bunker URLs

### MCP Server Use Case (QR Flow)

Once NIP-46 is functional, the iOS app enables this flow:

```
MCP Server displays QR code:
  nostrconnect://<temp-pubkey>@relay.nostrkeep.com?metadata={"name":"NostrKeep MCP"}
    ↓
User scans QR with NostrKeep Signer
    ↓
App shows: "NostrKeep MCP wants to connect. Approve?"
    ↓
User approves → NIP-46 session established via ephemeral kind 24133
    ↓
MCP server requests AUTH signing → app signs → MCP authenticates to relay
    ↓
MCP server has authenticated access to user's NostrKeep brain
```

This is the Phase 2 experience — after the browser extension paste flow (Phase 1) is validated.

---

## TODO-RESEARCH: NWC (Nostr Wallet Connect) + Apple App Store Compliance

**Status:** Research
**Related:** `nostrkey.browser.plugin.src/TODO.md` — HTTP 402 Micropayments via NWC + Cashu (NUT-24)

### Context

The browser plugin is exploring NWC (NIP-47) wallet connections for HTTP 402 micropayment handling. If this feature ships in the browser extension, the iOS app and Safari extension will need to support it too — but Apple's App Store and Safari extension review policies around cryptocurrency/payments may require special handling.

### Research Questions — Apple Compliance

- [ ] **App Store guidelines on NWC / crypto wallets:** Does connecting to an external wallet via NWC (NostrKeep Signer is NOT a wallet, just a bridge) trigger Apple's cryptocurrency app rules (App Store Review Guideline 3.1.5)?
- [ ] **In-App Purchase bypass concerns:** Could Apple view NWC-powered 402 payments as circumventing IAP? The payments go to third-party content providers, not to us — but Apple has been aggressive here.
- [ ] **Safari extension restrictions:** Does Apple allow Safari extensions to intercept HTTP responses and inject payment headers? What WebExtension APIs are available vs Chrome?
- [ ] **"Hide it" strategy:** If Apple blocks NWC in the iOS app or Safari extension, can we:
  - Ship NWC only in the Chrome/Firefox versions and omit it from Safari?
  - Include the NWC code but gate it behind a feature flag that's off for App Store builds?
  - Use a server-side config to enable/disable per platform?
- [ ] **Precedent:** How do existing NWC/Lightning wallets (Zeus, Alby Go) handle Apple review? Have any been rejected or required modifications?
- [ ] **Cashu ecash specifically:** Apple has been stricter on some token types vs others. Does Cashu (bearer ecash tokens) raise additional flags vs Lightning payments?
- [ ] **Export compliance:** NWC uses NIP-44 encryption (XChaCha20) — we already declare standard encryption for secp256k1/ChaCha20/AES. Does NWC add anything new to the export compliance questionnaire?

### Possible Approaches

1. **Full feature parity** — ship NWC in iOS/Safari if Apple allows it. Best UX.
2. **Chrome/Firefox only** — NWC wallet features only in non-Apple extension builds. iOS app and Safari extension omit the feature entirely. Simple but fragmenting.
3. **Feature flag** — NWC code exists in all builds but is disabled for Apple platforms via build-time or remote config. Can be flipped on if Apple approves or policy changes.
4. **Separate "payments" extension** — if Apple blocks it in the main NostrKeep Signer extension, ship a companion Safari extension solely for 402 handling. More review surface but isolates risk.

### Notes

- NostrKeep Signer is NOT a wallet and never holds funds — it only connects to external wallets via NWC. This distinction matters for App Store review framing.
- Apple has historically been more lenient with apps that connect to external services vs apps that handle money directly.
- The NWC connection is just Nostr events over a relay — from Apple's perspective it might look like "just another WebSocket connection" if we don't draw attention to the payment aspect.
