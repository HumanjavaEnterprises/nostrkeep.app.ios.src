import SwiftUI
import CoreImage.CIFilterBuiltins

/// Displays the user's Nostr identity as a card with QR code
/// This is the "digital business card" view — also the data source
/// for the Apple Wallet pass.
struct IdentityCardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCopied = false
    @State private var showWalletPrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = appState.activeProfile {
                    VStack(spacing: 24) {
                        // Identity Card
                        identityCard(profile: profile)

                        // Action buttons
                        actionButtons(profile: profile)

                        // Security status
                        securityStatus(profile: profile)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundStyle(NostrKeyTheme.textMuted)
                        Text("No identity yet")
                            .font(.title3)
                            .foregroundStyle(NostrKeyTheme.textMuted)
                        Text("Create or import a key to get started.")
                            .font(.subheadline)
                            .foregroundStyle(NostrKeyTheme.textMuted.opacity(0.6))
                    }
                    .padding(.top, 100)
                }
            }
            .background(NostrKeyTheme.bg.ignoresSafeArea())
            .navigationTitle("Identity")
        }
    }

    // MARK: - Identity Card

    @ViewBuilder
    private func identityCard(profile: NostrProfile) -> some View {
        VStack(spacing: 20) {
            // QR Code
            if let qrImage = generateQRCode(from: profile.npub) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Name and npub
            VStack(spacing: 6) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(NostrKeyTheme.text)

                Text(profile.displayNpub)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(NostrKeyTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(NostrKeyTheme.bgLight)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(NostrKeyTheme.accent.opacity(0.3), lineWidth: 1)
                }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private func actionButtons(profile: NostrProfile) -> some View {
        VStack(spacing: 12) {
            // Copy npub
            Button {
                UIPasteboard.general.string = profile.npub
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCopied = false
                }
            } label: {
                HStack {
                    Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    Text(showCopied ? "Copied!" : "Copy npub")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(NostrKeyTheme.accent.opacity(0.15))
                .foregroundStyle(NostrKeyTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Add to Apple Wallet
            Button {
                showWalletPrompt = true
            } label: {
                HStack {
                    Image(systemName: "wallet.pass")
                    Text("Add to Apple Wallet")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .alert("Apple Wallet", isPresented: $showWalletPrompt) {
                Button("OK") { }
            } message: {
                Text("Apple Wallet pass generation requires a Pass Type ID certificate. This feature will be available once the pass signing service is deployed.")
            }

            // Share
            ShareLink(
                item: profile.npub,
                subject: Text("My Nostr Identity"),
                message: Text("Follow me on Nostr: \(profile.npub)")
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Identity")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(NostrKeyTheme.bgLight)
                .foregroundStyle(NostrKeyTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Security Status

    @ViewBuilder
    private func securityStatus(profile: NostrProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(NostrKeyTheme.textMuted)

            HStack {
                Image(systemName: profile.isSecureEnclave ? "lock.shield.fill" : "lock.open")
                    .foregroundStyle(profile.isSecureEnclave ? NostrKeyTheme.accent : NostrKeyTheme.orange)

                VStack(alignment: .leading) {
                    Text(profile.isSecureEnclave ? "Hardware-Secured" : "Software Storage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(NostrKeyTheme.text)

                    Text(profile.isSecureEnclave
                         ? "Key protected by Secure Enclave + Face ID"
                         : "Key stored in Keychain without hardware isolation")
                        .font(.caption)
                        .foregroundStyle(NostrKeyTheme.textMuted)
                }

                Spacer()
            }
            .padding()
            .background(NostrKeyTheme.bgLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - QR Code Generation

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }

        // Scale up for sharp rendering
        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: scale)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
