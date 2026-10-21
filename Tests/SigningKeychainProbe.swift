import Foundation
import Security

// Dedicated disposable fixture only; no Roblox item names or real credentials.
guard CommandLine.arguments.count == 3 else { exit(2) }
let operation = CommandLine.arguments[1]
let service = CommandLine.arguments[2]
guard service.hasPrefix("com.rbxmulti.signing-test."),
      UUID(uuidString: String(service.dropFirst("com.rbxmulti.signing-test.".count))) != nil else { exit(2) }
let account = "disposable-test"
let fixture = "not-a-real-credential"
SecKeychainSetUserInteractionAllowed(false)
var keychain: SecKeychain?
let path = NSHomeDirectory() + "/Library/Keychains/login.keychain-db"
guard SecKeychainOpen(path, &keychain) == errSecSuccess else { exit(3) }
var item: SecKeychainItem?
var length: UInt32 = 0
var bytes: UnsafeMutableRawPointer?
let status: OSStatus
if operation == "create" {
    status = SecKeychainAddGenericPassword(keychain, UInt32(service.utf8.count), service,
        UInt32(account.utf8.count), account, UInt32(fixture.utf8.count), fixture, nil)
} else {
    status = SecKeychainFindGenericPassword(keychain, UInt32(service.utf8.count), service,
        UInt32(account.utf8.count), account, &length, &bytes, &item)
}
guard status == errSecSuccess else {
    print("Fixture operation failed without prompting: \(status)")
    exit(4)
}
if let bytes {
    let correct = Data(bytes: bytes, count: Int(length)) == Data(fixture.utf8)
    SecKeychainItemFreeContent(nil, bytes)
    guard correct else { exit(5) }
}
if operation == "delete", let item {
    guard SecKeychainItemDelete(item) == errSecSuccess else { exit(6) }
}
#if UPDATED_BUILD
print("Updated build: \(operation) succeeded without a Keychain prompt")
#else
print("Initial build: \(operation) succeeded without a Keychain prompt")
#endif
