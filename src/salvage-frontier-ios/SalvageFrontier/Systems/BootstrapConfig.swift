import CoreGraphics
import Foundation

enum BootstrapConfig {
  static let shipMaxSpeed: CGFloat = 820
  static let shipAcceleration: CGFloat = 2200
  static let shipDampingPerSecond: CGFloat = 7.5
  static let playerProjectileDamage: Int = 1
  static let bulletSpeed: CGFloat = 800
  static let autoFireInterval: TimeInterval = 0.34
  static let lanePadding: CGFloat = 80
  static let totalSupportedLaneCount: Int = 7
  static let defaultActiveLaneCount: Int = 5
  static let intentDeadzone: CGFloat = 36
  static let laneSwitchHysteresis: CGFloat = 42
  static let laneMagnetStrength: CGFloat = 9.5
  static let laneTransitionMatchOffsetFactor: CGFloat = 0.22
  static let shipMaxTiltRadians: CGFloat = 0.2
  static let shipTiltResponsiveness: CGFloat = 8
  static let enemyFireTelegraphDuration: TimeInterval = 0.18
  static let targetDummyMinCount: Int = 2
  static let targetDummyMaxCount: Int = 3
  static let targetDummyHP: Int = 3
  static let targetSpawnMinYOffset: CGFloat = 90
  static let targetSpawnMaxYOffset: CGFloat = 320
  static let targetApproachSpeed: CGFloat = 42
  static let targetRespawnDelay: TimeInterval = 1.15
  static let targetBreachDistanceFromShip: CGFloat = 58
  static let targetMissCleanupDistanceFromShip: CGFloat = 180
  static let targetBreachHullDamage: Int = 1
  static let scoutApproachSpeed: CGFloat = 80
  static let scoutBreachHullDamage: Int = 1
  static let bruteHull: Int = 10
  static let bruteApproachSpeed: CGFloat = 36
  static let bruteBreachHullDamage: Int = 4
  static let playerHullMax: Int = 6
  static let rewardDropDriftSpeed: CGFloat = 78
  static let rewardDropLifetime: TimeInterval = 5.25
  static let rewardCollectionDistanceFromShip: CGFloat = 82
  static let salvageCrateLifetime: TimeInterval = 6.5
  static let salvageCrateDriftSpeed: CGFloat = 44
  static let salvageCrateSalvageValue: Int = 2
  static let overchargeTokenThreshold: Int = 3
  static let overchargeDuration: TimeInterval = 6.0
  static let overchargeFireIntervalMultiplier: TimeInterval = 0.72

  static func sanitizedActiveLaneCount(_ requestedLaneCount: Int) -> Int {
    switch requestedLaneCount {
    case 7:
      return 7
    default:
      return 5
    }
  }
}
