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
  let movementSpeed: TimeInterval
  let laneChangeBehavior: LaneChangeBehavior
  let styleID: String
  let weaponID: String?
  let collisionDamage: Int
  let salvageValue: Int
  let rewardDropProfileID: String?
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
  let burstCount: Int?
  let burstInterval: TimeInterval?
  let burstCooldown: TimeInterval?
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
  let referenceLaneIndex: Int
  let spawnYOffset: CGFloat
  let initialFireDelay: TimeInterval?
}

struct EncounterPatternDefinition: Codable, Equatable {
  let id: String
  let displayName: String
  let entries: [EncounterSpawnDefinition]
  let salvageCrateReferenceLaneIndex: Int?
  let salvageCrateSpawnChance: Double
}

enum RewardDropType: String, Codable {
  case salvageToken
  case chargeToken
  case upgradeHook
}

struct RewardDropProfile: Codable, Equatable {
  let id: String
  let salvageChance: Double
  let chargeChance: Double
  let upgradeChanceHook: Double
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
      allowedFaction: .player,
      burstCount: nil,
      burstInterval: nil,
      burstCooldown: nil
    ),
    WeaponDefinition(
      id: "scout-needle",
      displayName: "Scout Needle",
      damage: 1,
      rateOfFire: 2.2,
      projectileSpeed: 280,
      ammoCapacity: nil,
      projectileStyleID: "scout-needle",
      fireMode: .single,
      allowedFaction: .hostile,
      burstCount: nil,
      burstInterval: nil,
      burstCooldown: nil
    ),
  ]

  static let enemies: [EnemyDefinition] = [
    EnemyDefinition(
      id: "dummy-target",
      displayName: "Target Dummy",
      maxHull: BootstrapConfig.targetDummyHP,
      movementSpeed: BootstrapConfig.targetTraversalDuration,
      laneChangeBehavior: .hold,
      styleID: "dummy-rect",
      weaponID: nil,
      collisionDamage: BootstrapConfig.targetBreachHullDamage,
      salvageValue: 1,
      rewardDropProfileID: nil
    ),
    EnemyDefinition(
      id: "scout-mk1",
      displayName: "Scout MK-I",
      maxHull: 2,
      movementSpeed: BootstrapConfig.scoutTraversalDuration,
      laneChangeBehavior: .hold,
      styleID: "scout-delta",
      weaponID: "scout-needle",
      collisionDamage: BootstrapConfig.scoutBreachHullDamage,
      salvageValue: 2,
      rewardDropProfileID: "scout-light"
    ),
    EnemyDefinition(
      id: "brute-hauler",
      displayName: "Brute Hauler",
      maxHull: BootstrapConfig.bruteHull,
      movementSpeed: BootstrapConfig.bruteTraversalDuration,
      laneChangeBehavior: .hold,
      styleID: "brute-block",
      weaponID: nil,
      collisionDamage: BootstrapConfig.bruteBreachHullDamage,
      salvageValue: 4,
      rewardDropProfileID: "brute-heavy"
    ),
  ]

  static let rewardDropProfiles: [RewardDropProfile] = [
    RewardDropProfile(
      id: "scout-light",
      salvageChance: 0.7,
      chargeChance: 0.18,
      upgradeChanceHook: 0.0
    ),
    RewardDropProfile(
      id: "brute-heavy",
      salvageChance: 1.0,
      chargeChance: 0.0,
      upgradeChanceHook: 0.0
    ),
  ]

  static let encounterPatterns: [EncounterPatternDefinition] = [
    EncounterPatternDefinition(
      id: "scout-centerline",
      displayName: "Scout Centerline",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 3,
          spawnYOffset: 180,
          initialFireDelay: 0.35
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "split-pressure",
      displayName: "Split Pressure",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 1,
          spawnYOffset: 150,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 5,
          spawnYOffset: 240,
          initialFireDelay: 0.5
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "center-screen",
      displayName: "Center Screen",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 1,
          spawnYOffset: 130,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 5,
          spawnYOffset: 130,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 3,
          spawnYOffset: 290,
          initialFireDelay: 0.65
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "stacked-center",
      displayName: "Stacked Center",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 3,
          spawnYOffset: 120,
          initialFireDelay: 0.25
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 3,
          spawnYOffset: 320,
          initialFireDelay: nil
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "breacher-crossload",
      displayName: "Breacher Crossload",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 1,
          spawnYOffset: 150,
          initialFireDelay: 0.4
        ),
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 5,
          spawnYOffset: 240,
          initialFireDelay: nil
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "salvage-bait",
      displayName: "Salvage Bait",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 1,
          spawnYOffset: 120,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 3,
          spawnYOffset: 300,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 5,
          spawnYOffset: 160,
          initialFireDelay: 0.35
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "stacked-breach-choice",
      displayName: "Stacked Breach Choice",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 3,
          spawnYOffset: 160,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 3,
          spawnYOffset: 340,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 1,
          spawnYOffset: 140,
          initialFireDelay: 0.38
        ),
      ],
      salvageCrateReferenceLaneIndex: nil,
      salvageCrateSpawnChance: 0
    ),
    EncounterPatternDefinition(
      id: "scout-swarm",
      displayName: "Scout Swarm",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 1,
          spawnYOffset: 120,
          initialFireDelay: 0.24
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 3,
          spawnYOffset: 220,
          initialFireDelay: 0.38
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 5,
          spawnYOffset: 320,
          initialFireDelay: 0.52
        ),
      ],
      salvageCrateReferenceLaneIndex: 3,
      salvageCrateSpawnChance: 0.4
    ),
    EncounterPatternDefinition(
      id: "double-brute-pressure",
      displayName: "Double Brute Pressure",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 1,
          spawnYOffset: 150,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 3,
          spawnYOffset: 270,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 5,
          spawnYOffset: 210,
          initialFireDelay: nil
        ),
      ],
      salvageCrateReferenceLaneIndex: 3,
      salvageCrateSpawnChance: 0.55
    ),
    EncounterPatternDefinition(
      id: "center-blockade",
      displayName: "Center Blockade",
      entries: [
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 2,
          spawnYOffset: 110,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "brute-hauler",
          referenceLaneIndex: 3,
          spawnYOffset: 240,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "dummy-target",
          referenceLaneIndex: 4,
          spawnYOffset: 110,
          initialFireDelay: nil
        ),
        EncounterSpawnDefinition(
          enemyID: "scout-mk1",
          referenceLaneIndex: 5,
          spawnYOffset: 320,
          initialFireDelay: 0.48
        ),
      ],
      salvageCrateReferenceLaneIndex: 1,
      salvageCrateSpawnChance: 0.45
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
