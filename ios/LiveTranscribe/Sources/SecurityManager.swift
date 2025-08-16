import Foundation
import CryptoKit
import LocalAuthentication
import UIKit

/// Advanced security manager for TalkNote app
@MainActor
public class SecurityManager: ObservableObject {
    @Published var isAppSecure = true
    @Published var biometricAuthEnabled = false
    @Published var lastSecurityCheck = Date()
    
    private let keychain = KeychainManager.shared
    private var appIntegrityHash: String?
    
    init() {
        setupSecurity()
    }
    
    // MARK: - App Integrity Protection
    
    /// Verify app integrity and detect tampering
    func verifyAppIntegrity() async -> Bool {
        // Check if app is running in debug mode (potential security risk)
        #if DEBUG
        print("⚠️ Debug mode detected - security checks relaxed")
        return true
        #else
        
        // Verify app bundle integrity
        guard let bundlePath = Bundle.main.bundlePath else { return false }
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: bundlePath, isDirectory: &isDirectory) else {
            return false
        }
        
        // Check for jailbreak indicators
        if await isJailbroken() {
            await handleSecurityThreat(.jailbreakDetected)
            return false
        }
        
        // Verify code signature (simplified)
        if await isCodeSignatureValid() {
            return true
        }
        
        await handleSecurityThreat(.codeIntegrityFailure)
        return false
        #endif
    }
    
    // MARK: - Anti-Tampering Protection
    
    private func isJailbroken() async -> Bool {
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if app can write outside sandbox
        do {
            let testString = "jailbreak_test"
            try testString.write(toFile: "/private/test.txt", atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: "/private/test.txt")
            return true // Should not be able to write outside sandbox
        } catch {
            return false // Normal behavior
        }
    }
    
    private func isCodeSignatureValid() async -> Bool {
        // In production, implement proper code signature verification
        return true
    }
    
    // MARK: - Runtime Application Self-Protection (RASP)
    
    func detectRuntimeThreats() async {
        // Anti-debugging
        if await isDebuggingDetected() {
            await handleSecurityThreat(.debuggerAttached)
        }
        
        // Memory protection
        await protectSensitiveMemory()
        
        // Network security validation
        await validateNetworkSecurity()
    }
    
    private func isDebuggingDetected() async -> Bool {
        // Check for debugger attachment
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func protectSensitiveMemory() async {
        // Clear sensitive data from memory when not in use
        // This is a placeholder - implement based on your app's sensitive data
    }
    
    // MARK: - Data Encryption & Protection
    
    func encryptSensitiveData(_ data: Data) -> Data? {
        guard let key = getOrCreateEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptSensitiveData(_ encryptedData: Data) -> Data? {
        guard let key = getOrCreateEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    private func getOrCreateEncryptionKey() -> SymmetricKey? {
        // Try to retrieve existing key from Keychain
        if let keyData = keychain.retrieve(key: "app_encryption_key") {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Store in Keychain
        if keychain.store(key: "app_encryption_key", data: keyData) {
            return key
        }
        
        return nil
    }
    
    // MARK: - Biometric Authentication
    
    func enableBiometricAuth() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to secure TalkNote"
            )
            
            if success {
                biometricAuthEnabled = true
                return true
            }
        } catch {
            print("Biometric authentication failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - Network Security
    
    private func validateNetworkSecurity() async {
        // Implement certificate pinning validation
        // Check for man-in-the-middle attacks
        // Validate TLS configuration
    }
    
    // MARK: - Security Event Handling
    
    private func handleSecurityThreat(_ threat: SecurityThreat) async {
        print("🚨 Security threat detected: \(threat)")
        
        switch threat {
        case .jailbreakDetected:
            isAppSecure = false
            // In production: disable sensitive features, log event
            
        case .debuggerAttached:
            // In production: terminate app or disable debugging
            break
            
        case .codeIntegrityFailure:
            isAppSecure = false
            // In production: prevent app from running
            
        case .unauthorizedAccess:
            // Clear sensitive data, require re-authentication
            break
        }
    }
    
    // MARK: - Setup & Monitoring
    
    private func setupSecurity() {
        Task {
            await verifyAppIntegrity()
            await detectRuntimeThreats()
            
            // Start continuous monitoring
            startSecurityMonitoring()
        }
    }
    
    private func startSecurityMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.detectRuntimeThreats()
                self.lastSecurityCheck = Date()
            }
        }
    }
}

// MARK: - Security Threat Types

enum SecurityThreat {
    case jailbreakDetected
    case debuggerAttached
    case codeIntegrityFailure
    case unauthorizedAccess
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    private let service = "com.talknote.app.security"
    
    func store(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieve(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? result as? Data : nil
    }
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
