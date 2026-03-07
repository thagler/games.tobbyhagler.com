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

struct EncounterSpawnDefinition: Codable, Equatable {
  let enemyID: String
  let laneIndex: Int
  let spawnYOffset: CGFloat
  let initialFireDelay: TimeInterval?
}

struct EncounterPatternDefinition: Codable, Equatable {
  let id: String
  let displayName: String
  let entries: [EncounterSpawnDefinition]
}

enum PrototypeDefinitions {
  static let weapons: [WeaponDefinition] = [
    WeaponDefinition(
      id: "starter-autocannon",
      displayName: "Starter Autocannon",
      damage: 1,
      rateOfFire: 0.34,
      projectileSpeed: 800,
      ammoCapacity: nil,
      projectileStyleID: "player-bolt",
      fireMode: .auto,
      allowedFaction: .player
    ),
    WeaponDefinition(
      id: "scout-needle",
      displayName: "Scout Needle",
      damage: 1,
      rateOfFire: 2.0,
      projectileSpeed: 280,
      ammoCapacity: nil,
      projectileStyleID: "scout-needle",
      fireMode: .single,
      allowedFaction: .hostile
    ),
  ]

  static let enemies: [EnemyDefinition] = [
    EnemyDefinition(
      id: "dummy-target",
      displayName: "Target Dummy",
      maxHull: BootstrapConfig.targetDummyHP,
      movementSpeed: BootstrapConfig.targetApproachSpeed,
      laneChangeBehavior: .hold,
      styleID: "dummy-rect",
      weaponID: nil,
      collisionDamage: BootstrapConfig.targetBreachHullDamage,
      salvageValue: 1
    ),
    EnemyDefinition(
      id: "scout-mk1",
      displayName: "Scout MK-I",
      maxHull: 2,
      movementSpeed: BootstrapConfig.targetApproachSpeed + 10,
      laneChangeBehavior: .hold,
      styleID: "scout-delta",
      weaponID: "scout-needle",
      collisionDamage: BootstrapConfig.targetBreachHullDamage,
      salvageValue: 2
    ),
  ]

  static let encounterPatterns: [EncounterPatternDefinition] = [
    EncounterPatternDefinition(
      id: "scout-centerline",
      displayName: "Scout Centerline",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          laneIndex: 2,
          spawnYOffset: 180,
          initialFireDelay: 0.35
        ),
      ]
    ),
    EncounterPatternDefinition(
      id: "split-pressure",
      displayName: "Split Pressure",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          laneIndex: 1,
          spawnYOffset: 150,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          laneIndex: 3,
          spawnYOffset: 240,
          initialFireDelay: 0.5
        ),
      ]
    ),
    EncounterPatternDefinition(
      id: "center-screen",
      displayName: "Center Screen",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          laneIndex: 1,
          spawnYOffset: 130,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          laneIndex: 3,
          spawnYOffset: 130,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          laneIndex: 2,
          spawnYOffset: 290,
          initialFireDelay: 0.65
        ),
      ]
    ),
    EncounterPatternDefinition(
      id: "stacked-center",
      displayName: "Stacked Center",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          laneIndex: 2,
          spawnYOffset: 120,
          initialFireDelay: 0.25
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          laneIndex: 2,
          spawnYOffset: 320,
          initialFireDelay: nil
        ),
      ]
    ),
  ]

  static let defaultShipLoadout = ShipLoadout(
    maxHull: BootstrapConfig.playerHullMax,
    currentHull: BootstrapConfig.playerHullMax,
    hasShieldGenerator: false,
    currentShield: 0,
    equippedWeaponID: "starter-autocannon",
    currentLane: 0
  )
}
