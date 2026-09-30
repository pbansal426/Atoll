import Defaults
import SwiftUI

enum PinnedValue: String, CaseIterable, Defaults.Serializable, Identifiable {
    case cpu, gpu, ram, fan, clock
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .ram: return "Memory pressure"
        case .fan: return "Fan"
        case .clock: return "Clock"
        }
    }
}

struct PinnedSnapshot {
    let cpu: Double
    let gpu: Double
    let memoryPressure: Double?
    let fan: FanReading?
    let now: Date
}

enum PinnedLayout {
    static let wingWidth: CGFloat = 52
}

enum PinnedFormatter {
    static func text(_ value: PinnedValue, _ s: PinnedSnapshot, calendar: Calendar = .current) -> String {
        switch value {
        case .cpu: return "CPU " + StatsStripFormatter.percent(s.cpu)
        case .gpu: return "GPU " + StatsStripFormatter.percent(s.gpu)
        case .ram: return "MEM " + StatsStripFormatter.percent(s.memoryPressure ?? .nan)
        case .fan: return "FAN " + StatsStripFormatter.fanPercent(s.fan)
        case .clock:
            let parts = calendar.dateComponents([.hour, .minute], from: s.now)
            let hour12 = ((parts.hour ?? 0) + 11) % 12 + 1
            return String(format: "%d:%02d", hour12, parts.minute ?? 0)
        }
    }
}

/// True when a closed-notch live activity above the pinned branch is showing.
/// Kept in step with the closed chain in ContentView: those activities replace the wings.
@MainActor
enum PinnedLiveActivityGate {
    static func isShowing(vm: DynamicIslandViewModel, screenName: String?, fanAlerting: Bool) -> Bool {
        let coordinator = DynamicIslandViewCoordinator.shared
        let locked = LockScreenManager.shared.isLocked

        if coordinator.firstLaunch { return true }

        if NetworkConnectivityHUDMetrics.isPresented(
            state: NetworkConnectivityManager.shared.hudState,
            notchState: vm.notchState,
            hideOnClosed: vm.hideOnClosed,
            isLocked: locked
        ) { return true }

        let batteryVisible = isBatteryHUDVisible(screenName: screenName)
        let expansionVisible: Bool = {
            guard coordinator.expandingView.show else { return false }
            if coordinator.expandingView.type == .battery { return batteryVisible }
            return true
        }()
        if expansionVisible { return true }

        if inlineSneakPeekIsShowing(vm: vm, screenName: screenName) { return true }

        if vm.notchState == .closed && CapsLockManager.shared.isCapsLockActive && Defaults[.enableCapsLockIndicator] && !vm.hideOnClosed && !locked {
            return true
        }

        let musicEligible = closedMusicIsEligible(vm: vm)
        if musicEligible { return true }

        if vm.notchState == .closed && TimerManager.shared.isTimerActive && coordinator.timerLiveActivityEnabled && !vm.hideOnClosed {
            return true
        }
        if vm.notchState == .closed && ReminderLiveActivityManager.shared.isActive && Defaults[.enableReminderLiveActivity] && !vm.hideOnClosed {
            return true
        }
        if vm.notchState == .closed && ScreenRecordingManager.shared.isRecording && Defaults[.enableScreenRecordingDetection] && Defaults[.showRecordingIndicator] && !vm.hideOnClosed && !musicEligible {
            return true
        }
        if vm.notchState == .closed && DownloadManager.shared.isDownloading && Defaults[.enableDownloadListener] && !vm.hideOnClosed {
            return true
        }
        if vm.notchState == .closed && localSendIsActive && !vm.hideOnClosed {
            return true
        }

        let focus = DoNotDisturbManager.shared
        if vm.notchState == .closed && Defaults[.enableDoNotDisturbDetection] && Defaults[.showDoNotDisturbIndicator] && (focus.isDoNotDisturbActive || focus.isFocusToastDismissing) && !vm.hideOnClosed && !locked {
            return true
        }
        if vm.notchState == .closed && PrivacyIndicatorManager.shared.hasAnyIndicator && (Defaults[.enableCameraDetection] || Defaults[.enableMicrophoneDetection]) && !vm.hideOnClosed {
            return true
        }
        if vm.notchState == .closed && !ExtensionLiveActivityManager.shared.sortedActivities().isEmpty && !vm.hideOnClosed && !locked && vm.effectiveClosedNotchHeight > 0 {
            return true
        }
        if !coordinator.expandingView.show && vm.notchState == .closed && !ShelfStateViewModel.shared.isEmpty && !vm.hideOnClosed && !locked && !Defaults[.enableMinimalisticUI] {
            return true
        }
        if vm.notchState == .closed && fanAlerting && Defaults[.enableFanLiveActivity] && !vm.hideOnClosed && !locked {
            return true
        }
        return false
    }

    private static func isBatteryHUDVisible(screenName: String?) -> Bool {
        let coordinator = DynamicIslandViewCoordinator.shared
        guard coordinator.expandingView.show, coordinator.expandingView.type == .battery else { return false }
        guard Defaults[.showPowerStatusNotifications] else { return false }
        guard BatteryStatusViewModel.shared.activeTemporaryHUDKind != nil else { return false }
        if Defaults[.showOnAllDisplays] { return true }
        guard let target = BatteryStatusViewModel.shared.activeTemporaryHUDTargetScreenName else { return true }
        return screenName == target
    }

    private static func sneakPeekIsVisible(screenName: String?) -> Bool {
        let peek = DynamicIslandViewCoordinator.shared.sneakPeek
        guard peek.show else { return false }
        guard Defaults[.showOnAllDisplays] else { return true }
        guard let target = peek.targetScreenName else { return true }
        return screenName == target
    }

    private static func inlineSneakPeekIsShowing(vm: DynamicIslandViewModel, screenName: String?) -> Bool {
        let peek = DynamicIslandViewCoordinator.shared.sneakPeek
        let airPods = peek.type == .bluetoothAudio
            && peek.value < 0
            && AirPodsListeningMode.fromHUDSymbol(peek.icon) != nil
        return sneakPeekIsVisible(screenName: screenName)
            && (Defaults[.inlineHUD] || airPods)
            && peek.type != .music
            && peek.type != .battery
            && peek.type != .timer
            && peek.type != .reminder
            && !peek.type.isExtensionPayload
            && ((peek.type != .volume && peek.type != .brightness && peek.type != .backlight) || vm.notchState == .closed)
    }

    private static func closedMusicIsEligible(vm: DynamicIslandViewModel) -> Bool {
        let music = MusicManager.shared
        let hasMetadata = !music.songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !music.artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasActiveMusicSnapshot = music.isPlaying || (!music.isPlayerIdle && hasMetadata)
        return isClosedMusicPairingEligible(
            notchState: vm.notchState,
            hasActiveMusicSnapshot: hasActiveMusicSnapshot,
            musicLiveActivityEnabled: DynamicIslandViewCoordinator.shared.musicLiveActivityEnabled,
            closedMusicContentEnabled: Defaults[.enableMinimalisticUI] || Defaults[.showStandardMediaControls],
            hideOnClosed: vm.hideOnClosed,
            isLocked: LockScreenManager.shared.isLocked,
            isDeferredAfterUnlock: LockScreenManager.shared.shouldDelayPostUnlockMusicHUD
        )
    }

    private static var localSendIsActive: Bool {
        let service = LocalSendService.shared
        if service.isSending { return true }
        switch service.transferState {
        case .completed, .failed, .rejected: return true
        case .idle, .sending: return false
        }
    }
}

/// Closed-notch wings: one pinned value each side of the notch.
struct PinnedStatsView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var fans = FanMonitor.shared
    @Default(.pinnedLeft) private var left
    @Default(.pinnedRight) private var right
    @State private var now = Date()
    private let clock = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private var snapshot: PinnedSnapshot {
        PinnedSnapshot(cpu: stats.cpuUsage, gpu: stats.gpuUsage,
                       memoryPressure: stats.memoryBreakdown.pressure.percent, fan: fans.reading, now: now)
    }

    var body: some View {
        HStack(spacing: 0) {
            wing(PinnedFormatter.text(left, snapshot), alignment: .leading)
            Rectangle().fill(.black).frame(width: vm.closedNotchSize.width)
            wing(PinnedFormatter.text(right, snapshot), alignment: .trailing)
        }
        .frame(height: vm.effectiveClosedNotchHeight)
        .onReceive(clock) { now = $0 }
    }

    private func wing(_ text: String, alignment: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: PinnedLayout.wingWidth, alignment: alignment)
    }
}
