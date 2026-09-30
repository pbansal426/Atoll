import Foundation

/// The fan that is spinning fastest, relative to its own maximum.
struct FanReading: Equatable {
    let rpm: Double
    let maxRPM: Double

    /// Share of maximum speed, 0...1. The alert threshold is a share of max,
    /// not of the min–max range: that is how the user thinks about fan speed.
    var fraction: Double { maxRPM > 0 ? rpm / maxRPM : 0 }
}

protocol FanSensorReading {
    func fanCount() -> Int
    func actualRPM(fan: Int) -> Double?
    func maxRPM(fan: Int) -> Double?
}

enum FanReadingResolver {
    /// The fastest fan with a known maximum, or `nil` when no fan can be read.
    /// 0 RPM is a real reading -- Apple Silicon fans stop at idle.
    static func fastest(from reader: FanSensorReading) -> FanReading? {
        (0..<reader.fanCount())
            .compactMap { fan -> FanReading? in
                guard let rpm = reader.actualRPM(fan: fan),
                      let max = reader.maxRPM(fan: fan), max > 0 else { return nil }
                return FanReading(rpm: rpm, maxRPM: max)
            }
            .max { $0.rpm < $1.rpm }
    }
}

/// Reads fans through Atoll's SMC wrapper. Read-only: fan control belongs to smctl.
struct SMCFanReader: FanSensorReading {
    func fanCount() -> Int { Int(SMC.shared.getValue("FNum") ?? 0) }
    func actualRPM(fan: Int) -> Double? { SMC.shared.getValue("F\(fan)Ac") }
    func maxRPM(fan: Int) -> Double? { SMC.shared.getValue("F\(fan)Mx") }
}
