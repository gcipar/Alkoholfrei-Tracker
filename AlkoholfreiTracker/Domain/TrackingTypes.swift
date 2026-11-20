import Foundation

enum GoalKind: String, Codable, CaseIterable, Sendable {
    case dryJanuary
    case lent
    case custom
    case openEnded
}

enum DayStatus: String, Codable, Sendable {
    case alcoholFree
    case drank
}

struct LoggedDay: Equatable, Sendable {
    var day: Date
    var status: DayStatus
}
