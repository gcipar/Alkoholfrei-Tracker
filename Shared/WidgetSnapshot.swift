import Foundation

struct WidgetSnapshot: Equatable, Sendable {
    var alcoholFreeDays: Int
    var streakDays: Int
    var moneySavedEUR: Decimal
    var challengeTitle: String?
    var updatedAt: Date
}

extension WidgetSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case alcoholFreeDays
        case streakDays
        case moneySavedEUR
        case challengeTitle
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alcoholFreeDays = try container.decode(Int.self, forKey: .alcoholFreeDays)
        streakDays = try container.decode(Int.self, forKey: .streakDays)
        let money = try container.decode(String.self, forKey: .moneySavedEUR)
        guard let decimal = Decimal(string: money, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                forKey: .moneySavedEUR,
                in: container,
                debugDescription: "Money is not a decimal string."
            )
        }
        moneySavedEUR = decimal
        challengeTitle = try container.decodeIfPresent(String.self, forKey: .challengeTitle)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alcoholFreeDays, forKey: .alcoholFreeDays)
        try container.encode(streakDays, forKey: .streakDays)
        try container.encode(Self.plainString(from: moneySavedEUR), forKey: .moneySavedEUR)
        try container.encodeIfPresent(challengeTitle, forKey: .challengeTitle)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    private static func plainString(from value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

struct WidgetSnapshotStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    static func live() -> WidgetSnapshotStore? {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
            return nil
        }
        return WidgetSnapshotStore(defaults: defaults)
    }

    func save(_ snapshot: WidgetSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: AppGroup.snapshotKey)
    }

    func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: AppGroup.snapshotKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
