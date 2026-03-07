import CoreGraphics
import Foundation

enum LaneChangeBehavior: String, Codable {
  case hold
  case occasional
  case reactive
}

enum FireMode: String, Codable {
  case single
  case burst
  case auto
}

enum Faction: String, Codable {
  case player
  case hostile
  case neutral
}

struct EnemyDefinition: Codable, Equatable {
  let id: String
  let displayName: String
  let maxHull: Int
  let movementSpeed: CGFloat
  let laneChangeBehavior: LaneChangeBehavior
  let styleID: String
  let weaponID: String?
  let collisionDamage: Int
  let salvageValue: Int
}

struct WeaponDefinition: Codable, Equatable {
  let id: String
  let displayName: String
  let damage: Int
  let rateOfFire: TimeInterval
  let projectileSpeed: CGFloat
  let ammoCapacity: Int?
  let projectileStyleID: String
  let fireMode: FireMode
  let allowedFaction: Faction
}

struct ShipLoadout: Codable, Equatable {
  let maxHull: Int
  var currentHull: Int
  let hasShieldGenerator: Bool
  var currentShield: Int
  let equippedWeaponID: String
  var currentLane: Int
}
