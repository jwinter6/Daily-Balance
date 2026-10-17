import Foundation
import LocalAuthentication
import Observation

@MainActor @Observable final class LockService {
    var unlocked = false
    var authenticating = false
    var message: String?
    func authenticate() async -> Bool {
        guard !authenticating else { return false }
        authenticating = true
        defer { authenticating = false }
        let context = LAContext()
        context.localizedCancelTitle = "Abbrechen"
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                localizedReason: "Öffne dein persönliches Tagebuch.")
            unlocked = success
            message = success ? nil : "Dein Tagebuch bleibt gesperrt."
            return success
        } catch {
            message = "Entsperren nicht möglich. Prüfe Face ID und deinen Gerätecode in iOS."
            return false
        }
    }
}
