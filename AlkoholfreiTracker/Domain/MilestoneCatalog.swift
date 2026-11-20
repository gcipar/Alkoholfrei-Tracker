import Foundation

enum GardenStage: Equatable, Sendable {
    case seed
    case sprout
    case youngPlant
    case plant
    case bush
    case tree
}

enum MilestoneCatalog {
    static let thresholds = [1, 7, 14, 31, 40, 100]

    static func unlocked(totalAlcoholFreeDays: Int) -> [Int] {
        thresholds.filter { totalAlcoholFreeDays >= $0 }
    }

    static func stage(for totalAlcoholFreeDays: Int) -> GardenStage {
        switch totalAlcoholFreeDays {
        case ..<1:
            .seed
        case 1..<7:
            .sprout
        case 7..<14:
            .youngPlant
        case 14..<31:
            .plant
        case 31..<100:
            .bush
        default:
            .tree
        }
    }
}
