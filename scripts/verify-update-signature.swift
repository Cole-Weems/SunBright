import CryptoKit
import Foundation

// Public inputs only. Verify against the key embedded in the shipped app,
// rather than accepting any signature made by the CI signing secret.
do {
    guard CommandLine.arguments.count == 4,
          let publicKey = Data(base64Encoded: CommandLine.arguments[2]),
          let signature = Data(base64Encoded: CommandLine.arguments[3]) else {
        throw NSError(domain: "SunBrightUpdate", code: 1)
    }
    let key = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
    let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    guard key.isValidSignature(signature, for: archive) else {
        throw NSError(domain: "SunBrightUpdate", code: 2)
    }
} catch {
    fputs("Update signature does not match the public key embedded in the app.\n", stderr)
    exit(1)
}
