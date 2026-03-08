import Foundation
import CryptoKit

/// Nostr protocol cryptographic operations
/// Nostr uses secp256k1 for signing (Schnorr/BIP-340)
/// This module handles key encoding/decoding (bech32) and event hashing
enum NostrCrypto {

    // MARK: - Bech32 Encoding/Decoding

    /// Decode a bech32-encoded Nostr key (nsec1... or npub1...)
    static func decodeBech32(_ str: String) throws -> (hrp: String, data: Data) {
        let decoded = try Bech32.decode(str)
        let data = try Bech32.convertBits(data: decoded.data, fromBits: 5, toBits: 8, pad: false)
        return (decoded.hrp, Data(data))
    }

    /// Encode raw bytes to bech32 with the given human-readable prefix
    static func encodeBech32(hrp: String, data: Data) throws -> String {
        let converted = try Bech32.convertBits(data: Array(data), fromBits: 8, toBits: 5, pad: true)
        return Bech32.encode(hrp: hrp, data: converted)
    }

    /// Convert nsec string to raw 32-byte private key
    static func nsecToPrivateKey(_ nsec: String) throws -> Data {
        let (hrp, data) = try decodeBech32(nsec)
        guard hrp == "nsec", data.count == 32 else {
            throw NostrError.invalidKey("Invalid nsec: wrong prefix or length")
        }
        return data
    }

    /// Convert raw 32-byte private key to nsec string
    static func privateKeyToNsec(_ key: Data) throws -> String {
        guard key.count == 32 else {
            throw NostrError.invalidKey("Private key must be 32 bytes")
        }
        return try encodeBech32(hrp: "nsec", data: key)
    }

    /// Convert raw 32-byte public key to npub string
    static func publicKeyToNpub(_ key: Data) throws -> String {
        guard key.count == 32 else {
            throw NostrError.invalidKey("Public key must be 32 bytes")
        }
        return try encodeBech32(hrp: "npub", data: key)
    }

    /// Convert npub string to raw 32-byte public key
    static func npubToPublicKey(_ npub: String) throws -> Data {
        let (hrp, data) = try decodeBech32(npub)
        guard hrp == "npub", data.count == 32 else {
            throw NostrError.invalidKey("Invalid npub: wrong prefix or length")
        }
        return data
    }

    // MARK: - Event Hashing

    /// Compute the event ID (SHA-256 hash of serialized event)
    static func computeEventId(
        pubkey: String,
        createdAt: Int,
        kind: Int,
        tags: [[String]],
        content: String
    ) -> Data {
        // Nostr event ID = SHA256([0, pubkey, created_at, kind, tags, content])
        let serialized = "[0,\"\(pubkey)\",\(createdAt),\(kind),\(serializeTags(tags)),\"\(escapeJSON(content))\"]"
        let data = Data(serialized.utf8)
        return Data(SHA256.hash(data: data))
    }

    private static func serializeTags(_ tags: [[String]]) -> String {
        let inner = tags.map { tag in
            let items = tag.map { "\"\(escapeJSON($0))\"" }.joined(separator: ",")
            return "[\(items)]"
        }.joined(separator: ",")
        return "[\(inner)]"
    }

    private static func escapeJSON(_ str: String) -> String {
        str.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
           .replacingOccurrences(of: "\n", with: "\\n")
           .replacingOccurrences(of: "\r", with: "\\r")
           .replacingOccurrences(of: "\t", with: "\\t")
    }

    // MARK: - Hex Encoding

    static func hexEncode(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    static func hexDecode(_ hex: String) throws -> Data {
        guard hex.count % 2 == 0 else {
            throw NostrError.invalidKey("Invalid hex string length")
        }
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                throw NostrError.invalidKey("Invalid hex character")
            }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
}

// MARK: - Bech32 Implementation

/// Bech32 encoding/decoding (BIP-173)
enum Bech32 {
    private static let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    private static let generator: [UInt32] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]

    struct DecodedResult {
        let hrp: String
        let data: [UInt8]
    }

    static func encode(hrp: String, data: [UInt8]) -> String {
        let checksum = createChecksum(hrp: hrp, data: data)
        let combined = data + checksum
        let chars = Array(charset)
        let encoded = combined.map { chars[Int($0)] }
        return hrp + "1" + String(encoded)
    }

    static func decode(_ str: String) throws -> DecodedResult {
        let lowered = str.lowercased()
        guard let separatorIndex = lowered.lastIndex(of: "1") else {
            throw NostrError.invalidKey("No separator found in bech32 string")
        }

        let hrp = String(lowered[lowered.startIndex..<separatorIndex])
        let dataStr = String(lowered[lowered.index(after: separatorIndex)...])
        let chars = Array(charset)

        var data: [UInt8] = []
        for char in dataStr {
            guard let idx = chars.firstIndex(of: char) else {
                throw NostrError.invalidKey("Invalid bech32 character: \(char)")
            }
            data.append(UInt8(idx))
        }

        guard verifyChecksum(hrp: hrp, data: data) else {
            throw NostrError.invalidKey("Invalid bech32 checksum")
        }

        return DecodedResult(hrp: hrp, data: Array(data.dropLast(6)))
    }

    static func convertBits(data: [UInt8], fromBits: Int, toBits: Int, pad: Bool) throws -> [UInt8] {
        var acc: UInt32 = 0
        var bits: Int = 0
        var result: [UInt8] = []
        let maxv: UInt32 = (1 << toBits) - 1

        for value in data {
            let v = UInt32(value)
            guard v >> fromBits == 0 else {
                throw NostrError.invalidKey("Invalid data for bit conversion")
            }
            acc = (acc << fromBits) | v
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                result.append(UInt8((acc >> bits) & maxv))
            }
        }

        if pad {
            if bits > 0 {
                result.append(UInt8((acc << (toBits - bits)) & maxv))
            }
        } else if bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0 {
            throw NostrError.invalidKey("Invalid padding in bit conversion")
        }

        return result
    }

    private static func polymod(_ values: [UInt32]) -> UInt32 {
        var chk: UInt32 = 1
        for v in values {
            let top = chk >> 25
            chk = (chk & 0x1ffffff) << 5 ^ v
            for i in 0..<5 {
                if ((top >> i) & 1) != 0 {
                    chk ^= generator[i]
                }
            }
        }
        return chk
    }

    private static func hrpExpand(_ hrp: String) -> [UInt32] {
        var result: [UInt32] = []
        for char in hrp.unicodeScalars {
            result.append(UInt32(char.value) >> 5)
        }
        result.append(0)
        for char in hrp.unicodeScalars {
            result.append(UInt32(char.value) & 31)
        }
        return result
    }

    private static func verifyChecksum(hrp: String, data: [UInt8]) -> Bool {
        let values = hrpExpand(hrp) + data.map { UInt32($0) }
        return polymod(values) == 1
    }

    private static func createChecksum(hrp: String, data: [UInt8]) -> [UInt8] {
        let values = hrpExpand(hrp) + data.map { UInt32($0) } + [0, 0, 0, 0, 0, 0]
        let mod = polymod(values) ^ 1
        return (0..<6).map { UInt8((mod >> (5 * (5 - $0))) & 31) }
    }
}

// MARK: - Errors

enum NostrError: LocalizedError {
    case invalidKey(String)
    case signingFailed(String)
    case keychainError(String)
    case relayError(String)
    case nip46Error(String)

    var errorDescription: String? {
        switch self {
        case .invalidKey(let msg): return "Invalid key: \(msg)"
        case .signingFailed(let msg): return "Signing failed: \(msg)"
        case .keychainError(let msg): return "Keychain error: \(msg)"
        case .relayError(let msg): return "Relay error: \(msg)"
        case .nip46Error(let msg): return "NIP-46 error: \(msg)"
        }
    }
}
