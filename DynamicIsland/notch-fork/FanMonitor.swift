import Combine
import Defaults
import Foundation

/// Samples the fans on a timer and publishes the fastest one plus whether the
/// fan live activity should show. Runs whenever the strip, the activity, or
/// pinned wings are enabled; an SMC read every couple of seconds is negligible.
final class FanMonitor: ObservableObject {
    static let shared = FanMonitor(reader: SMCFanReader(), policy: FanAlertPolicy(), interval: 2)

    @Published private(set) var reading: FanReading?
    @Published private(set) var isAlerting = false

    private let reader: FanSensorReading
    private var stateMachine: FanAlertStateMachine
    private let interval: TimeInterval
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(reader: FanSensorReading, policy: FanAlertPolicy, interval: TimeInterval) {
        self.reader = reader
        self.stateMachine = FanAlertStateMachine(policy: policy)
        self.interval = interval
    }

    /// Starts sampling while either consumer is enabled, and follows the settings.
    func start() {
        Defaults.publisher(keys: .showHomeStatsStrip, .enableFanLiveActivity, .pinnedMode, options: [.initial])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncTimer() }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        timer?.invalidate()
        timer = nil
    }

    func tick(now: Date = Date()) {
        let latest = FanReadingResolver.fastest(from: reader)
        reading = latest
        let alerting = stateMachine.update(fraction: latest?.fraction, now: now)
        if alerting != isAlerting { isAlerting = alerting }
    }

    private func syncTimer() {
        let needed = Defaults[.showHomeStatsStrip] || Defaults[.enableFanLiveActivity] || Defaults[.pinnedMode]
        if needed, timer == nil {
            tick()
            let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } else if !needed {
            timer?.invalidate()
            timer = nil
            reading = nil
            isAlerting = false
            stateMachine = FanAlertStateMachine(policy: stateMachine.policy)
        }
    }
}
