import SwiftUI

/// Sheets have their own presentation layer, so each sensitive sheet needs its own cover.
struct PrivacyShield: ViewModifier {
    @Environment(AppStore.self) private var store
    @Environment(LockService.self) private var lock
    @Environment(\.scenePhase) private var phase
    private var covered: Bool { phase != .active || (store.settings.faceIDEnabled && !lock.unlocked) }
    func body(content: Content) -> some View {
        ZStack {
            content.opacity(covered ? 0 : 1).accessibilityHidden(covered).disabled(covered)
            if covered {
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield").font(.largeTitle).foregroundStyle(Color.balanceTeal)
                    Text("Daily Balance").font(.headline)
                    if phase == .active && store.settings.faceIDEnabled {
                        Button("Tagebuch entsperren") { Task { _ = await lock.authenticate() } }
                            .buttonStyle(.borderedProminent).disabled(lock.authenticating)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.balanceCanvas)
            }
        }.privacySensitive()
    }
}
extension View { func protectJournal() -> some View { modifier(PrivacyShield()) } }
