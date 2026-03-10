import SpriteKit

final class TransitTestScene: SKScene, SKPhysicsContactDelegate {
  private enum PhysicsCategory {
    static let playerProjectile: UInt32 = 1 << 0
    static let enemyBody: UInt32 = 1 << 1
  }

  private let ship: SKShapeNode = {
    let width: CGFloat = 72
    let height: CGFloat = 50
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 0, y: height / 2))
    path.addLine(to: CGPoint(x: width / 2, y: -height / 2))
    path.addLine(to: CGPoint(x: -width / 2, y: -height / 2))
    path.closeSubpath()

    let node = SKShapeNode(path: path)
    node.fillColor = .cyan
    node.strokeColor = .white
    node.lineWidth = 1.5
    node.name = "ship"
    node.zPosition = 8
    return node
  }()
  private let laneStatusLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
  private let targetsRemainingLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
  private let hullStatusLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
  private let rewardStatusLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
  private let encounterEventLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
  private let breachLine = SKShapeNode()
  private let damageFlashOverlay = SKSpriteNode(color: .systemRed, size: .zero)
  private let activeLaneCount: Int

  private var laneGuides: [SKShapeNode] = []
  private var laneCenters: [CGFloat] = []
  private var currentLaneIndex = 0

  private var controllingTouch: UITouch?
  private var controllingTouchX: CGFloat?

  private var shipVelocityX: CGFloat = 0
  private var lastShotTime: TimeInterval = 0
  private var lastUpdateTime: TimeInterval?
  private var currentSceneTime: TimeInterval = 0
  private var isPlayerAlive = true
  private var playerHull = BootstrapConfig.playerHullMax
  private var playerLoadout = PrototypeDefinitions.defaultShipLoadout
  private var isDraggingShip = false
  private var isInputAboveFireLine = false
  private var collectedSalvageTokens = 0
  private var collectedChargeTokens = 0
  private var chargeTokensTowardOvercharge = 0
  private var overchargeEndsAt: TimeInterval = 0
  private var targetRespawnPending = false
  private var nextTargetSpawnTime: TimeInterval?
  private let enemyDefinitionsByID = Dictionary(
    uniqueKeysWithValues: PrototypeDefinitions.enemies.map { ($0.id, $0) }
  )
  private let weaponDefinitionsByID = Dictionary(
    uniqueKeysWithValues: PrototypeDefinitions.weapons.map { ($0.id, $0) }
  )
  private let rewardDropProfilesByID = Dictionary(
    uniqueKeysWithValues: PrototypeDefinitions.rewardDropProfiles.map { ($0.id, $0) }
  )
  private var lastEncounterPatternID: String?

  init(size: CGSize, activeLaneCount: Int = BootstrapConfig.defaultActiveLaneCount) {
    self.activeLaneCount = BootstrapConfig.sanitizedActiveLaneCount(activeLaneCount)
    super.init(size: size)
  }

  required init?(coder aDecoder: NSCoder) {
    self.activeLaneCount = BootstrapConfig.defaultActiveLaneCount
    super.init(coder: aDecoder)
  }

  override func didMove(to view: SKView) {
    scaleMode = .resizeFill
    backgroundColor = .black
    configurePhysicsWorld()

    ship.position = CGPoint(x: frame.midX, y: 180)
    addChild(ship)

    configureLaneGuides()
    configureDamageOverlay()
    spawnEncounterEnemies()
    configureOverlayLabels()
    refreshCombatStatusUI()

    currentLaneIndex = nearestLaneIndex(to: ship.position.x)
    refreshLaneReadabilityUI()
  }

  override func update(_ currentTime: TimeInterval) {
    currentSceneTime = currentTime
    let dt: CGFloat
    if let lastUpdateTime {
      dt = min(max(CGFloat(currentTime - lastUpdateTime), 1.0 / 240.0), 1.0 / 30.0)
    } else {
      dt = 1.0 / 60.0
    }
    lastUpdateTime = currentTime

    let horizontalIntent = normalizedHorizontalIntent()
    shipVelocityX += horizontalIntent * BootstrapConfig.shipAcceleration * dt

    // Dampen velocity when intent is low to keep the prototype readable and low-twitch.
    if abs(horizontalIntent) < 0.01 {
      let damping = max(0, 1 - (BootstrapConfig.shipDampingPerSecond * dt))
      shipVelocityX *= damping
    }

    shipVelocityX = min(max(shipVelocityX, -BootstrapConfig.shipMaxSpeed), BootstrapConfig.shipMaxSpeed)
    ship.position.x += shipVelocityX * dt
    updateShipTilt(dt)

    let minX = BootstrapConfig.lanePadding
    let maxX = frame.width - BootstrapConfig.lanePadding
    ship.position.x = min(max(ship.position.x, minX), maxX)

    // Light lane magnetism when there is no active intent.
    if abs(horizontalIntent) < 0.01, !laneCenters.isEmpty {
      let targetX = laneCenters[currentLaneIndex]
      let toLane = targetX - ship.position.x
      ship.position.x += toLane * min(1, BootstrapConfig.laneMagnetStrength * dt)
    }

    updateLaneSelectionWithHysteresis()
    updateApproachingTargets(dt)
    updateEnemyWeaponFire(currentTime)
    updateEnemyProjectiles(dt)
    updateRewardDrops(currentTime: currentTime, dt: dt)
    updateSalvageCrates(currentTime: currentTime, dt: dt)
    evaluateTargetBreachRisk()
    updateTargetPracticeLoop(currentTime)

    if isPlayerAlive,
       isDraggingShip,
       isInputAboveFireLine,
       currentTime - lastShotTime >= currentPlayerFireInterval(at: currentTime) {
      fireProjectile()
      lastShotTime = currentTime
    }

    enumerateChildNodes(withName: "projectile") { node, _ in
      if node.position.y > self.frame.maxY + 100 {
        node.removeFromParent()
      }
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard isPlayerAlive else {
      clearPlayerInputState()
      return
    }
    if controllingTouch == nil {
      controllingTouch = touches.first
    }
    refreshControllingTouch(from: event)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard isPlayerAlive else {
      clearPlayerInputState()
      return
    }
    refreshControllingTouch(from: event)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard isPlayerAlive else {
      clearPlayerInputState()
      return
    }
    refreshControllingTouch(from: event)
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard isPlayerAlive else {
      clearPlayerInputState()
      return
    }
    refreshControllingTouch(from: event)
  }

  func didBegin(_ contact: SKPhysicsContact) {
    let firstBody = contact.bodyA
    let secondBody = contact.bodyB

    let projectileContact = [
      (firstBody, secondBody),
      (secondBody, firstBody),
    ].first {
      $0.0.categoryBitMask == PhysicsCategory.playerProjectile &&
        $0.1.categoryBitMask == PhysicsCategory.enemyBody
    }

    guard
      let (projectileBody, enemyBody) = projectileContact,
      let projectileNode = projectileBody.node,
      let enemyNode = enemyBody.node
    else {
      return
    }

    handleProjectileHit(projectile: projectileNode, target: enemyNode, at: contact.contactPoint)
  }

  private func normalizedHorizontalIntent() -> CGFloat {
    guard isPlayerAlive else { return 0 }
    guard let controllingTouchX else { return 0 }

    let delta = controllingTouchX - ship.position.x
    if abs(delta) <= BootstrapConfig.intentDeadzone {
      return 0
    }

    return min(max(delta / 220, -1), 1)
  }

  private func updateShipTilt(_ dt: CGFloat) {
    let normalizedVelocity = shipVelocityX / BootstrapConfig.shipMaxSpeed
    let targetTilt = -normalizedVelocity * BootstrapConfig.shipMaxTiltRadians
    let blend = min(1, BootstrapConfig.shipTiltResponsiveness * dt)
    ship.zRotation += (targetTilt - ship.zRotation) * blend
  }

  private func fireProjectile() {
    guard isPlayerAlive else { return }

    let isOvercharged = isOverchargeActive(at: currentSceneTime)
    let projectileSize = isOvercharged ? CGSize(width: 8, height: 22) : CGSize(width: 6, height: 18)
    let projectile = SKShapeNode(rectOf: projectileSize, cornerRadius: 3)
    projectile.fillColor = isOvercharged ? .systemMint : .white
    projectile.strokeColor = .clear
    projectile.glowWidth = isOvercharged ? 6 : 0
    projectile.position = CGPoint(x: ship.position.x, y: ship.position.y + 35)
    projectile.name = "projectile"
    projectile.zPosition = 10

    let body = SKPhysicsBody(rectangleOf: projectileSize)
    body.affectedByGravity = false
    body.isDynamic = true
    body.categoryBitMask = PhysicsCategory.playerProjectile
    body.contactTestBitMask = PhysicsCategory.enemyBody
    body.collisionBitMask = 0
    body.usesPreciseCollisionDetection = true
    projectile.physicsBody = body

    addChild(projectile)

    let travelDistance = frame.height + 200
    let travelTime = TimeInterval(travelDistance / BootstrapConfig.bulletSpeed)
    let moveUp = SKAction.moveBy(x: 0, y: travelDistance, duration: travelTime)
    let cleanup = SKAction.removeFromParent()
    projectile.run(.sequence([moveUp, cleanup]))
  }

  private func currentPlayerWeapon() -> WeaponDefinition? {
    weaponDefinitionsByID[playerLoadout.equippedWeaponID]
  }

  private func currentPlayerProjectileDamage() -> Int {
    let baseDamage = currentPlayerWeapon()?.damage ?? BootstrapConfig.playerProjectileDamage
    return isOverchargeActive(at: currentSceneTime) ? baseDamage + 1 : baseDamage
  }

  private func currentPlayerFireInterval(at currentTime: TimeInterval) -> TimeInterval {
    let baseInterval = currentPlayerWeapon()?.rateOfFire ?? BootstrapConfig.autoFireInterval
    if isOverchargeActive(at: currentTime) {
      return baseInterval * BootstrapConfig.overchargeFireIntervalMultiplier
    }
    return baseInterval
  }

  private func isOverchargeActive(at currentTime: TimeInterval) -> Bool {
    currentTime < overchargeEndsAt
  }

  private func configurePhysicsWorld() {
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
  }

  private func handleProjectileHit(projectile: SKNode, target: SKNode, at contactPoint: CGPoint) {
    projectile.removeFromParent()
    applyPrototypeDamage(currentPlayerProjectileDamage(), to: target, at: contactPoint)
  }

  private func applyPrototypeDamage(_ amount: Int, to target: SKNode, at point: CGPoint) {
    // Task 0002 integration hook: future enemy prototypes can set userData["hp"].
    if let currentHP = target.userData?["hp"] as? Int {
      let remainingHP = currentHP - amount
      target.userData?["hp"] = remainingHP
      if remainingHP <= 0 {
        destroyTarget(target, at: target.position, cueColor: .systemOrange)
        return
      }
    }

    playEnemyHitFeedback(on: target)
    spawnHitFlash(at: point, color: .systemYellow, radius: 10, zPosition: 13)
  }

  private func updateApproachingTargets(_ dt: CGFloat) {
    enumerateChildNodes(withName: "enemy-unit") { node, _ in
      let movementSpeed = (node.userData?["movementSpeed"] as? CGFloat) ?? BootstrapConfig.targetApproachSpeed
      node.position.y -= movementSpeed * dt
    }
  }

  private func updateEnemyWeaponFire(_ currentTime: TimeInterval) {
    enumerateChildNodes(withName: "enemy-unit") { node, _ in
      guard
        let weaponID = node.userData?["weaponID"] as? String,
        let weapon = self.weaponDefinitionsByID[weaponID]
      else {
        return
      }

      guard self.isEnemyFullyVisible(node) else {
        return
      }

      if (node.userData?["hasEnteredPlayfield"] as? Bool) != true {
        let initialFireDelay = (node.userData?["initialFireDelay"] as? TimeInterval) ?? weapon.rateOfFire
        node.userData?["hasEnteredPlayfield"] = true
        node.userData?["nextFireTime"] = currentTime + initialFireDelay
        return
      }

      let nextFireTime = (node.userData?["nextFireTime"] as? TimeInterval) ?? currentTime + weapon.rateOfFire
      let telegraphDuration = BootstrapConfig.enemyFireTelegraphDuration
      let pendingBurstShots = (node.userData?["burstShotsRemaining"] as? Int) ?? 0

      if pendingBurstShots == 0,
         (node.userData?["telegraphStarted"] as? Bool) != true,
         nextFireTime - currentTime <= telegraphDuration,
         nextFireTime > currentTime {
        self.startEnemyFireTelegraph(on: node, fireTime: nextFireTime)
      }

      if pendingBurstShots == 0,
         (node.userData?["telegraphStarted"] as? Bool) == true,
         let telegraphFireTime = node.userData?["telegraphFireTime"] as? TimeInterval,
         currentTime < telegraphFireTime {
        return
      }

      if currentTime < nextFireTime {
        return
      }

      self.fireEnemyProjectile(from: node, weapon: weapon)

      if let burstCount = weapon.burstCount,
         let burstInterval = weapon.burstInterval,
         let burstCooldown = weapon.burstCooldown,
         burstCount > 1 {
        if pendingBurstShots == 0 {
          let remainingShots = burstCount - 1
          node.userData?["burstShotsRemaining"] = remainingShots
          node.userData?["nextFireTime"] = currentTime + (remainingShots > 0 ? burstInterval : burstCooldown)
          self.finishEnemyFireTelegraph(on: node)
        } else {
          let remainingShots = pendingBurstShots - 1
          node.userData?["burstShotsRemaining"] = remainingShots
          node.userData?["nextFireTime"] = currentTime + (remainingShots > 0 ? burstInterval : burstCooldown)
        }
      } else {
        self.finishEnemyFireTelegraph(on: node)
        node.userData?["nextFireTime"] = currentTime + weapon.rateOfFire
      }
    }
  }

  private func updateEnemyProjectiles(_ dt: CGFloat) {
    var hitProjectiles: [SKNode] = []

    enumerateChildNodes(withName: "enemy-projectile") { node, _ in
      let projectileSpeed = (node.userData?["projectileSpeed"] as? CGFloat) ?? 320
      node.position.y -= projectileSpeed * dt

      if node.frame.intersects(self.ship.frame) {
        hitProjectiles.append(node)
      } else if node.position.y < self.frame.minY - 120 {
        node.removeFromParent()
      }
    }

    for projectile in hitProjectiles {
      let damage = (projectile.userData?["damage"] as? Int) ?? 1
      projectile.removeFromParent()
      applyHullDamage(damage)
      spawnHitFlash(at: ship.position, color: .systemRed, radius: 12, zPosition: 14)
    }
  }

  private func fireEnemyProjectile(from enemy: SKNode, weapon: WeaponDefinition) {
    let projectile = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 3)
    projectile.fillColor = colorForProjectileStyle(weapon.projectileStyleID)
    projectile.strokeColor = .white
    projectile.lineWidth = 1.2
    projectile.glowWidth = 5
    projectile.name = "enemy-projectile"
    projectile.zPosition = 9
    projectile.position = CGPoint(x: enemy.position.x, y: enemy.position.y - 34)
    projectile.userData = NSMutableDictionary(dictionary: [
      "damage": weapon.damage,
      "projectileSpeed": weapon.projectileSpeed,
    ])

    let trail = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
    trail.fillColor = projectile.fillColor.withAlphaComponent(0.45)
    trail.strokeColor = .clear
    trail.position = CGPoint(x: 0, y: 12)
    trail.zPosition = -1
    projectile.addChild(trail)

    addChild(projectile)
  }

  private func colorForProjectileStyle(_ styleID: String) -> SKColor {
    switch styleID {
    case "scout-needle":
      return .systemOrange
    default:
      return .systemPink
    }
  }

  private func evaluateTargetBreachRisk() {
    let breachLineY = ship.position.y + BootstrapConfig.targetBreachDistanceFromShip
    let missCleanupY = ship.position.y - BootstrapConfig.targetMissCleanupDistanceFromShip
    var breachedTargets: [SKNode] = []
    var missedTargets: [SKNode] = []

    enumerateChildNodes(withName: "enemy-unit") { node, _ in
      if node.position.y <= breachLineY {
        if self.isLaneMatchedForBreach(targetX: node.position.x) {
          breachedTargets.append(node)
        } else if node.position.y <= missCleanupY {
          missedTargets.append(node)
        }
      } else if node.frame.intersects(self.ship.frame), self.isLaneMatchedForBreach(targetX: node.position.x) {
        breachedTargets.append(node)
      }
    }

    for target in breachedTargets {
      handleTargetBreach(target)
    }

    for target in missedTargets {
      despawnTargetWithoutDamage(target)
    }
  }

  private func handleTargetBreach(_ target: SKNode) {
    let collisionDamage = (target.userData?["collisionDamage"] as? Int) ?? BootstrapConfig.targetBreachHullDamage
    applyHullDamage(collisionDamage)
    destroyTarget(target, at: target.position, cueColor: .systemRed)
  }

  private func despawnTargetWithoutDamage(_ target: SKNode) {
    target.removeAllActions()
    target.removeFromParent()
  }

  private func applyHullDamage(_ amount: Int) {
    guard isPlayerAlive else { return }

    playerHull = max(0, playerHull - amount)
    refreshCombatStatusUI()
    flashShipForHullHit()
    flashHullStatusLabel()
    flashDamageOverlay()

    if playerHull == 0 {
      handlePlayerDestroyed()
    }
  }

  private func isLaneMatchedForBreach(targetX: CGFloat) -> Bool {
    let targetLane = nearestLaneIndex(to: targetX)
    return laneMatchCandidates(forShipX: ship.position.x).contains(targetLane)
  }

  private func laneMatchCandidates(forShipX shipX: CGFloat) -> Set<Int> {
    guard !laneCenters.isEmpty else { return [] }

    let primaryLane = nearestLaneIndex(to: shipX)
    var candidates: Set<Int> = [primaryLane]

    let laneSpacing = distanceBetweenLaneCenters()
    guard laneSpacing > 0 else { return candidates }

    let laneCenterX = laneCenters[primaryLane]
    let offsetFromCenter = shipX - laneCenterX
    let transitionThreshold = laneSpacing * BootstrapConfig.laneTransitionMatchOffsetFactor

    if offsetFromCenter > transitionThreshold, primaryLane < laneCenters.count - 1 {
      candidates.insert(primaryLane + 1)
    } else if offsetFromCenter < -transitionThreshold, primaryLane > 0 {
      candidates.insert(primaryLane - 1)
    }

    return candidates
  }

  private func distanceBetweenLaneCenters() -> CGFloat {
    guard laneCenters.count > 1 else { return 0 }
    return laneCenters[1] - laneCenters[0]
  }

  private func spawnHitFlash(at point: CGPoint, color: SKColor = .white, radius: CGFloat = 8, zPosition: CGFloat = 12) {
    let flash = SKShapeNode(circleOfRadius: radius)
    flash.fillColor = color
    flash.strokeColor = .clear
    flash.alpha = 0.85
    flash.position = point
    flash.zPosition = zPosition
    addChild(flash)

    let fade = SKAction.fadeOut(withDuration: 0.12)
    flash.run(.sequence([fade, .removeFromParent()]))
  }

  private func destroyTarget(_ target: SKNode, at point: CGPoint, cueColor: SKColor) {
    let enemyID = target.userData?["enemyID"] as? String
    maybeSpawnRewardDrop(from: target, at: point)
    finishEnemyFireTelegraph(on: target)
    target.removeAllActions()
    target.removeFromParent()
    spawnTargetDestroyedCue(at: point, color: cueColor, isHeavyKill: enemyID == "brute-hauler")
  }

  private func spawnTargetDestroyedCue(at point: CGPoint, color: SKColor, isHeavyKill: Bool) {
    let flash = SKShapeNode(circleOfRadius: isHeavyKill ? 26 : 18)
    flash.fillColor = color.withAlphaComponent(0.85)
    flash.strokeColor = .clear
    flash.position = point
    flash.zPosition = 11
    addChild(flash)

    let ring = SKShapeNode(circleOfRadius: isHeavyKill ? 30 : 22)
    ring.fillColor = .clear
    ring.strokeColor = color
    ring.lineWidth = isHeavyKill ? 5 : 4
    ring.alpha = 0.9
    ring.position = point
    ring.zPosition = 11
    addChild(ring)

    if !isHeavyKill {
      for index in 0 ..< 4 {
        let shard = SKShapeNode(rectOf: CGSize(width: 5, height: 16), cornerRadius: 2)
        shard.fillColor = color
        shard.strokeColor = .clear
        shard.position = point
        shard.zPosition = 11
        shard.zRotation = (.pi * 2 / 4) * CGFloat(index)
        addChild(shard)

        let angle = shard.zRotation
        let move = SKAction.moveBy(x: cos(angle) * 28, y: sin(angle) * 28, duration: 0.18)
        let fade = SKAction.fadeOut(withDuration: 0.18)
        shard.run(.sequence([.group([move, fade]), .removeFromParent()]))
      }
    }

    let pop = SKAction.scale(to: isHeavyKill ? 1.55 : 1.45, duration: isHeavyKill ? 0.2 : 0.16)
    let fade = SKAction.fadeOut(withDuration: isHeavyKill ? 0.22 : 0.16)
    ring.run(.sequence([.group([pop, fade]), .removeFromParent()]))
    flash.run(.sequence([.group([SKAction.scale(to: isHeavyKill ? 1.7 : 1.4, duration: 0.1), fade]), .removeFromParent()]))
  }

  private func flashShipForHullHit() {
    ship.removeAction(forKey: "hull-hit-flash")

    let flashOn = SKAction.run { [weak self] in
      self?.ship.fillColor = .systemRed
      self?.ship.setScale(1.05)
    }
    let wait = SKAction.wait(forDuration: 0.12)
    let flashOff = SKAction.run { [weak self] in
      self?.ship.fillColor = .cyan
      self?.ship.setScale(1.0)
    }

    let recoil = SKAction.sequence([
      .moveBy(x: 0, y: -8, duration: 0.05),
      .moveBy(x: 0, y: 8, duration: 0.09),
    ])
    ship.run(.sequence([flashOn, wait, flashOff]), withKey: "hull-hit-flash")
    ship.run(recoil, withKey: "hull-hit-recoil")
  }

  private func spawnEncounterEnemies() {
    guard !laneCenters.isEmpty else { return }
    guard let pattern = nextEncounterPattern() else { return }

    for entry in pattern.entries {
      let activeLaneIndex = resolvedLaneIndex(forReferenceLaneIndex: entry.referenceLaneIndex)
      guard laneCenters.indices.contains(activeLaneIndex) else {
        continue
      }
      guard let definition = enemyDefinitionsByID[entry.enemyID] else {
        continue
      }

      let enemy = makeEnemyNode(definition: definition, initialFireDelay: entry.initialFireDelay)
      enemy.position = CGPoint(
        x: laneCenters[activeLaneIndex],
        y: frame.maxY + entry.spawnYOffset
      )
      addChild(enemy)
    }

    spawnSalvageCrateIfNeeded(for: pattern)
    lastEncounterPatternID = pattern.id
    presentEncounterEvent(pattern.displayName)
    refreshCombatStatusUI()
  }

  private func nextEncounterPattern() -> EncounterPatternDefinition? {
    let patterns = PrototypeDefinitions.encounterPatterns.filter { pattern in
      pattern.entries.allSatisfy { entry in
        laneCenters.indices.contains(resolvedLaneIndex(forReferenceLaneIndex: entry.referenceLaneIndex)) &&
          enemyDefinitionsByID[entry.enemyID] != nil
      }
    }

    guard !patterns.isEmpty else { return nil }
    let nonRepeatingPatterns = patterns.filter { $0.id != lastEncounterPatternID }
    return (nonRepeatingPatterns.isEmpty ? patterns : nonRepeatingPatterns).randomElement()
  }

  private func makeEnemyNode(definition: EnemyDefinition, initialFireDelay: TimeInterval?) -> SKShapeNode {
    let enemy = enemyShapeNode(for: definition)
    enemy.name = "enemy-unit"
    enemy.zPosition = 6
    enemy.userData = NSMutableDictionary(dictionary: [
      "enemyID": definition.id,
      "hp": definition.maxHull,
      "movementSpeed": definition.movementSpeed,
      "collisionDamage": definition.collisionDamage,
      "salvageValue": definition.salvageValue,
    ])
    if let rewardDropProfileID = definition.rewardDropProfileID {
      enemy.userData?["rewardDropProfileID"] = rewardDropProfileID
    }
    if let weaponID = definition.weaponID {
      enemy.userData?["weaponID"] = weaponID
      enemy.userData?["nextFireTime"] = TimeInterval.greatestFiniteMagnitude
      enemy.userData?["hasEnteredPlayfield"] = false
      enemy.userData?["initialFireDelay"] = initialFireDelay ?? weaponDefinitionsByID[weaponID]?.rateOfFire ?? 0
      enemy.userData?["burstShotsRemaining"] = 0
      enemy.userData?["telegraphStarted"] = false
    }

    let body: SKPhysicsBody
    if definition.styleID == "scout-delta", let path = enemy.path {
      body = SKPhysicsBody(polygonFrom: path)
    } else {
      body = SKPhysicsBody(rectangleOf: CGSize(width: 86, height: 48))
    }
    body.isDynamic = false
    body.affectedByGravity = false
    body.categoryBitMask = PhysicsCategory.enemyBody
    body.contactTestBitMask = PhysicsCategory.playerProjectile
    body.collisionBitMask = 0
    enemy.physicsBody = body

    return enemy
  }

  private func isEnemyFullyVisible(_ enemy: SKNode) -> Bool {
    let enemyFrame = enemy.calculateAccumulatedFrame()
    return frame.contains(enemyFrame)
  }

  private func startEnemyFireTelegraph(on enemy: SKNode, fireTime: TimeInterval) {
    guard (enemy.userData?["telegraphStarted"] as? Bool) != true else { return }

    enemy.userData?["telegraphStarted"] = true
    enemy.userData?["telegraphFireTime"] = fireTime

    guard let shape = enemy as? SKShapeNode else { return }
    storeBaseEnemyAppearanceIfNeeded(for: shape)

    let brighten = SKAction.run { [weak self] in
      self?.applyEnemyAppearance(shape, fillColor: .white, strokeColor: .systemYellow, lineWidth: 3, scale: 1.08)
    }
    let settle = SKAction.run { [weak self] in
      self?.applyEnemyAppearance(shape, fillColor: .systemMint, strokeColor: .white, lineWidth: 2.5, scale: 1.0)
    }
    let pulse = SKAction.sequence([
      .moveBy(x: 0, y: 8, duration: 0.05),
      .moveBy(x: 0, y: -8, duration: 0.08),
    ])
    shape.run(.sequence([brighten, .wait(forDuration: BootstrapConfig.enemyFireTelegraphDuration * 0.55), settle]), withKey: "enemy-telegraph-color")
    shape.run(pulse, withKey: "enemy-telegraph-recoil")
  }

  private func finishEnemyFireTelegraph(on enemy: SKNode) {
    enemy.userData?["telegraphStarted"] = false
    enemy.userData?.removeObject(forKey: "telegraphFireTime")
    enemy.removeAction(forKey: "enemy-telegraph-recoil")

    guard let shape = enemy as? SKShapeNode else { return }
    restoreEnemyAppearance(shape)
  }

  private func playEnemyHitFeedback(on enemy: SKNode) {
    guard let shape = enemy as? SKShapeNode else { return }

    storeBaseEnemyAppearanceIfNeeded(for: shape)
    shape.removeAction(forKey: "enemy-hit-feedback")
    shape.run(.sequence([
      .run { [weak self] in
        self?.applyEnemyAppearance(shape, fillColor: .white, strokeColor: .systemYellow, lineWidth: 3, scale: 1.1)
      },
      .wait(forDuration: 0.06),
      .run { [weak self] in
        self?.restoreEnemyAppearance(shape)
      },
    ]), withKey: "enemy-hit-feedback")
  }

  private func storeBaseEnemyAppearanceIfNeeded(for enemy: SKShapeNode) {
    if enemy.userData?["baseFillColor"] == nil {
      enemy.userData?["baseFillColor"] = enemy.fillColor
    }
    if enemy.userData?["baseStrokeColor"] == nil {
      enemy.userData?["baseStrokeColor"] = enemy.strokeColor
    }
    if enemy.userData?["baseLineWidth"] == nil {
      enemy.userData?["baseLineWidth"] = enemy.lineWidth
    }
  }

  private func applyEnemyAppearance(
    _ enemy: SKShapeNode,
    fillColor: SKColor,
    strokeColor: SKColor,
    lineWidth: CGFloat,
    scale: CGFloat
  ) {
    enemy.fillColor = fillColor
    enemy.strokeColor = strokeColor
    enemy.lineWidth = lineWidth
    enemy.setScale(scale)
  }

  private func restoreEnemyAppearance(_ enemy: SKShapeNode) {
    let fillColor = (enemy.userData?["baseFillColor"] as? SKColor) ?? enemy.fillColor
    let strokeColor = (enemy.userData?["baseStrokeColor"] as? SKColor) ?? enemy.strokeColor
    let lineWidth = (enemy.userData?["baseLineWidth"] as? CGFloat) ?? enemy.lineWidth
    applyEnemyAppearance(enemy, fillColor: fillColor, strokeColor: strokeColor, lineWidth: lineWidth, scale: 1.0)
  }

  private func enemyShapeNode(for definition: EnemyDefinition) -> SKShapeNode {
    switch definition.styleID {
    case "scout-delta":
      let width: CGFloat = 72
      let height: CGFloat = 44
      let path = CGMutablePath()
      path.move(to: CGPoint(x: 0, y: -height / 2))
      path.addLine(to: CGPoint(x: width / 2, y: height / 2))
      path.addLine(to: CGPoint(x: -width / 2, y: height / 2))
      path.closeSubpath()

      let node = SKShapeNode(path: path)
      node.fillColor = .systemRed
      node.strokeColor = .systemPink
      node.lineWidth = 2.5
      return node

    case "brute-block":
      let node = SKShapeNode(rectOf: CGSize(width: 110, height: 64), cornerRadius: 16)
      node.fillColor = SKColor(red: 0.42, green: 0.08, blue: 0.12, alpha: 1.0)
      node.strokeColor = .systemPink
      node.lineWidth = 3.5
      return node

    default:
      let node = SKShapeNode(rectOf: CGSize(width: 86, height: 48), cornerRadius: 12)
      node.fillColor = .systemPink
      node.strokeColor = .systemRed
      node.lineWidth = 2
      return node
    }
  }

  private func updateTargetPracticeLoop(_ currentTime: TimeInterval) {
    var remainingTargets = activeEnemyCount()

    if remainingTargets == 0, !targetRespawnPending {
      targetRespawnPending = true
      nextTargetSpawnTime = currentTime + BootstrapConfig.targetRespawnDelay
    }

    if targetRespawnPending,
       let nextTargetSpawnTime,
       currentTime >= nextTargetSpawnTime {
      targetRespawnPending = false
      self.nextTargetSpawnTime = nil
      spawnEncounterEnemies()
      remainingTargets = activeEnemyCount()
    }

    refreshCombatStatusUI(remainingTargets: remainingTargets)
  }

  private func activeEnemyCount() -> Int {
    children.reduce(into: 0) { count, node in
      if node.name == "enemy-unit" {
        count += 1
      }
    }
  }

  private func configureDamageOverlay() {
    damageFlashOverlay.removeFromParent()
    damageFlashOverlay.size = CGSize(width: frame.width, height: frame.height)
    damageFlashOverlay.position = CGPoint(x: frame.midX, y: frame.midY)
    damageFlashOverlay.alpha = 0
    damageFlashOverlay.zPosition = 18
    addChild(damageFlashOverlay)
  }

  private func configureLaneGuides() {
    breachLine.removeFromParent()
    laneGuides.forEach { $0.removeFromParent() }
    laneGuides.removeAll()
    laneCenters.removeAll()

    let minX = BootstrapConfig.lanePadding
    let maxX = frame.width - BootstrapConfig.lanePadding
    let laneCount = max(activeLaneCount, 2)
    let spacing = (maxX - minX) / CGFloat(laneCount - 1)

    for idx in 0 ..< laneCount {
      let laneX = minX + (CGFloat(idx) * spacing)
      laneCenters.append(laneX)

      let path = CGMutablePath()
      path.move(to: CGPoint(x: laneX, y: 100))
      path.addLine(to: CGPoint(x: laneX, y: frame.height - 90))

      let guide = SKShapeNode(path: path)
      guide.strokeColor = .darkGray
      guide.lineWidth = 2
      guide.alpha = 0.22
      addChild(guide)
      laneGuides.append(guide)
    }

    let breachLineY = ship.position.y + BootstrapConfig.targetBreachDistanceFromShip
    let breachPath = CGMutablePath()
    breachPath.move(to: CGPoint(x: minX, y: breachLineY))
    breachPath.addLine(to: CGPoint(x: maxX, y: breachLineY))

    breachLine.path = breachPath
    breachLine.strokeColor = .systemRed
    breachLine.lineWidth = 2
    breachLine.alpha = 0.35
    breachLine.zPosition = 4
    addChild(breachLine)
  }

  private func configureOverlayLabels() {
    let hintLabel = SKLabelNode(text: "Hold/drag left-right. Same-lane breaches damage hull.")
    hintLabel.fontName = "AvenirNext-Regular"
    hintLabel.fontSize = 24
    hintLabel.fontColor = .lightGray
    hintLabel.position = CGPoint(x: frame.midX, y: frame.height - 120)
    addChild(hintLabel)

    laneStatusLabel.fontSize = 26
    laneStatusLabel.fontColor = .cyan
    laneStatusLabel.position = CGPoint(x: frame.midX, y: frame.height - 165)
    addChild(laneStatusLabel)

    targetsRemainingLabel.fontSize = 24
    targetsRemainingLabel.fontColor = .white
    targetsRemainingLabel.position = CGPoint(x: frame.midX, y: frame.height - 205)
    addChild(targetsRemainingLabel)

    hullStatusLabel.fontSize = 24
    hullStatusLabel.fontColor = .systemGreen
    hullStatusLabel.position = CGPoint(x: frame.midX, y: frame.height - 240)
    addChild(hullStatusLabel)

    rewardStatusLabel.fontSize = 22
    rewardStatusLabel.fontColor = .systemMint
    rewardStatusLabel.position = CGPoint(x: frame.midX, y: frame.height - 275)
    addChild(rewardStatusLabel)

    encounterEventLabel.fontSize = 28
    encounterEventLabel.fontColor = .systemOrange
    encounterEventLabel.alpha = 0
    encounterEventLabel.position = CGPoint(x: frame.midX, y: frame.height - 78)
    encounterEventLabel.zPosition = 16
    addChild(encounterEventLabel)
  }

  private func refreshCombatStatusUI(remainingTargets: Int? = nil) {
    let targets = remainingTargets ?? activeEnemyCount()

    if targetRespawnPending {
      targetsRemainingLabel.text = "Targets: \(targets) | Reforming..."
    } else {
      targetsRemainingLabel.text = "Targets: \(targets)"
    }

    hullStatusLabel.text = "Hull: \(playerHull)/\(BootstrapConfig.playerHullMax)"

    if playerHull <= 1 {
      hullStatusLabel.fontColor = .systemRed
    } else if playerHull <= 3 {
      hullStatusLabel.fontColor = .systemYellow
    } else {
      hullStatusLabel.fontColor = .systemGreen
    }

    let overchargeText: String
    if isOverchargeActive(at: currentSceneTime) {
      let timeRemaining = max(0, overchargeEndsAt - currentSceneTime)
      overchargeText = String(format: " | Overcharge %.1fs", timeRemaining)
      rewardStatusLabel.fontColor = .systemYellow
    } else {
      overchargeText = ""
      rewardStatusLabel.fontColor = .systemMint
    }

    rewardStatusLabel.text = "Salvage: \(collectedSalvageTokens) | Charge: \(collectedChargeTokens) | OVR \(chargeTokensTowardOvercharge)/\(BootstrapConfig.overchargeTokenThreshold)\(overchargeText)"
  }

  private func flashHullStatusLabel() {
    hullStatusLabel.removeAction(forKey: "hull-status-flash")
    hullStatusLabel.run(.sequence([
      .scale(to: 1.12, duration: 0.06),
      .scale(to: 1.0, duration: 0.12),
    ]), withKey: "hull-status-flash")
  }

  private func flashDamageOverlay() {
    damageFlashOverlay.removeAllActions()
    damageFlashOverlay.alpha = 0.18
    damageFlashOverlay.run(.sequence([
      .fadeAlpha(to: 0.05, duration: 0.08),
      .fadeOut(withDuration: 0.18),
    ]))
  }

  private func refreshControllingTouch(from event: UIEvent?) {
    guard isPlayerAlive else {
      clearPlayerInputState()
      return
    }

    guard let allTouches = event?.allTouches else {
      clearPlayerInputState()
      return
    }

    let activeTouches = allTouches.filter {
      $0.phase == .began || $0.phase == .moved || $0.phase == .stationary
    }

    if let controllingTouch,
       let matchedTouch = activeTouches.first(where: { $0 === controllingTouch }) {
      let location = matchedTouch.location(in: self)
      controllingTouchX = location.x
      isDraggingShip = true
      isInputAboveFireLine = location.y >= fireGateLineY()
      return
    }

    controllingTouch = activeTouches.first
    if let controllingTouch {
      let location = controllingTouch.location(in: self)
      controllingTouchX = location.x
      isDraggingShip = true
      isInputAboveFireLine = location.y >= fireGateLineY()
    } else {
      clearPlayerInputState()
    }
  }

  private func clearPlayerInputState() {
    controllingTouch = nil
    controllingTouchX = nil
    isDraggingShip = false
    isInputAboveFireLine = false
  }

  private func handlePlayerDestroyed() {
    guard isPlayerAlive else { return }

    isPlayerAlive = false
    clearPlayerInputState()
    shipVelocityX = 0
    lastShotTime = currentSceneTime
  }

  private func fireGateLineY() -> CGFloat {
    ship.position.y + BootstrapConfig.targetBreachDistanceFromShip
  }

  private func nearestLaneIndex(to x: CGFloat) -> Int {
    guard !laneCenters.isEmpty else { return 0 }
    var bestIndex = 0
    var bestDistance = abs(x - laneCenters[0])

    for idx in 1 ..< laneCenters.count {
      let distance = abs(x - laneCenters[idx])
      if distance < bestDistance {
        bestDistance = distance
        bestIndex = idx
      }
    }
    return bestIndex
  }

  private func updateLaneSelectionWithHysteresis() {
    guard !laneCenters.isEmpty else { return }

    let nearestIndex = nearestLaneIndex(to: ship.position.x)
    if nearestIndex != currentLaneIndex {
      let switchDistance = abs(ship.position.x - laneCenters[currentLaneIndex])
      if switchDistance > BootstrapConfig.laneSwitchHysteresis {
        currentLaneIndex = nearestIndex
        refreshLaneReadabilityUI()
      }
    } else {
      laneStatusLabel.text = "Lane \(currentLaneIndex + 1) / \(laneCenters.count)"
    }
  }

  private func refreshLaneReadabilityUI() {
    for (index, lane) in laneGuides.enumerated() {
      if index == currentLaneIndex {
        lane.strokeColor = .cyan
        lane.alpha = 0.62
      } else {
        lane.strokeColor = .darkGray
        lane.alpha = 0.22
      }
    }

    laneStatusLabel.text = "Lane \(currentLaneIndex + 1) / \(laneCenters.count)"
  }

  private func resolvedLaneIndex(forReferenceLaneIndex referenceLaneIndex: Int) -> Int {
    let totalLaneCount = max(BootstrapConfig.totalSupportedLaneCount, 2)
    let clampedReferenceLane = min(max(referenceLaneIndex, 0), totalLaneCount - 1)
    let normalizedPosition = CGFloat(clampedReferenceLane) / CGFloat(totalLaneCount - 1)
    let mappedIndex = Int(round(normalizedPosition * CGFloat(max(activeLaneCount - 1, 0))))
    return min(max(mappedIndex, 0), max(activeLaneCount - 1, 0))
  }

  private func presentEncounterEvent(_ title: String) {
    encounterEventLabel.removeAllActions()
    encounterEventLabel.text = title.uppercased()
    encounterEventLabel.setScale(0.96)
    encounterEventLabel.alpha = 0
    encounterEventLabel.run(.group([
      .fadeAlpha(to: 0.95, duration: 0.12),
      .scale(to: 1.0, duration: 0.12),
    ]))
    encounterEventLabel.run(.sequence([
      .wait(forDuration: 1.0),
      .fadeOut(withDuration: 0.25),
    ]))
  }

  private func spawnSalvageCrateIfNeeded(for pattern: EncounterPatternDefinition) {
    guard childNode(withName: "salvage-crate") == nil else { return }
    guard let referenceLaneIndex = pattern.salvageCrateReferenceLaneIndex else { return }
    guard Double.random(in: 0 ..< 1) < pattern.salvageCrateSpawnChance else { return }

    let activeLaneIndex = resolvedLaneIndex(forReferenceLaneIndex: referenceLaneIndex)
    guard laneCenters.indices.contains(activeLaneIndex) else { return }

    let crate = salvageCrateNode()
    let spawnPoint = CGPoint(x: laneCenters[activeLaneIndex], y: frame.maxY - 150)
    crate.position = spawnPoint
    crate.zPosition = 10
    crate.name = "salvage-crate"
    crate.userData = NSMutableDictionary(dictionary: [
      "laneIndex": activeLaneIndex,
      "expiresAt": currentSceneTime + BootstrapConfig.salvageCrateLifetime,
      "salvageValue": BootstrapConfig.salvageCrateSalvageValue,
    ])
    addChild(crate)
    spawnHitFlash(at: spawnPoint, color: .systemOrange, radius: 18, zPosition: 14)
    showFloatingPickupText("SALVAGE CRATE", at: CGPoint(x: spawnPoint.x, y: spawnPoint.y + 44), color: .systemOrange)
  }

  private func maybeSpawnRewardDrop(from enemy: SKNode, at point: CGPoint) {
    guard enemy.name == "enemy-unit" else { return }
    guard let rewardDropType = rewardDropType(for: enemy) else { return }

    let drop = rewardDropNode(for: rewardDropType)
    drop.name = "reward-drop"
    drop.position = point
    drop.zPosition = 10
    drop.userData = NSMutableDictionary(dictionary: [
      "dropType": rewardDropType.rawValue,
      "laneIndex": nearestLaneIndex(to: point.x),
      "expiresAt": currentSceneTime + BootstrapConfig.rewardDropLifetime,
    ])
    addChild(drop)
    spawnHitFlash(at: point, color: dropColor(for: rewardDropType), radius: 16, zPosition: 14)
  }

  private func salvageCrateNode() -> SKNode {
    let container = SKNode()

    let box = SKShapeNode(rectOf: CGSize(width: 58, height: 44), cornerRadius: 8)
    box.fillColor = SKColor(red: 0.86, green: 0.42, blue: 0.08, alpha: 1.0)
    box.strokeColor = SKColor(red: 0.36, green: 0.18, blue: 0.05, alpha: 1.0)
    box.lineWidth = 4
    container.addChild(box)

    let strapPath = CGMutablePath()
    strapPath.move(to: CGPoint(x: -22, y: 8))
    strapPath.addLine(to: CGPoint(x: 22, y: 8))
    strapPath.move(to: CGPoint(x: -22, y: -8))
    strapPath.addLine(to: CGPoint(x: 22, y: -8))
    strapPath.move(to: CGPoint(x: 0, y: 18))
    strapPath.addLine(to: CGPoint(x: 0, y: -18))
    let straps = SKShapeNode(path: strapPath)
    straps.strokeColor = .systemYellow
    straps.lineWidth = 3.5
    container.addChild(straps)

    for offsetX in [-20, 20] {
      for offsetY in [-14, 14] {
        let bolt = SKShapeNode(circleOfRadius: 2.6)
        bolt.fillColor = .black.withAlphaComponent(0.75)
        bolt.strokeColor = .clear
        bolt.position = CGPoint(x: CGFloat(offsetX), y: CGFloat(offsetY))
        container.addChild(bolt)
      }
    }

    let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    label.text = "CR"
    label.fontSize = 16
    label.fontColor = .black
    label.verticalAlignmentMode = .center
    label.zPosition = 1
    container.addChild(label)

    container.run(.repeatForever(.sequence([
      .scale(to: 1.06, duration: 0.42),
      .scale(to: 0.99, duration: 0.42),
    ])), withKey: "crate-pulse")
    container.run(.repeatForever(.sequence([
      .moveBy(x: 0, y: 7, duration: 0.52),
      .moveBy(x: 0, y: -7, duration: 0.52),
    ])), withKey: "crate-bob")
    return container
  }

  private func rewardDropType(for enemy: SKNode) -> RewardDropType? {
    guard let rewardDropProfileID = enemy.userData?["rewardDropProfileID"] as? String else { return nil }
    guard let profile = rewardDropProfilesByID[rewardDropProfileID] else { return nil }

    let roll = Double.random(in: 0 ..< 1)
    if roll < profile.salvageChance {
      return .salvageToken
    }
    if roll < profile.salvageChance + profile.chargeChance {
      return .chargeToken
    }

    // Hook for future elite rewards. This milestone does not spawn upgrade drops yet.
    if roll < profile.salvageChance + profile.chargeChance + profile.upgradeChanceHook {
      return .upgradeHook
    }

    return nil
  }

  private func rewardDropNode(for dropType: RewardDropType) -> SKNode {
    let color: SKColor
    let labelText: String
    let token: SKShapeNode

    switch dropType {
    case .salvageToken:
      color = .systemYellow
      labelText = "S"
      token = SKShapeNode(path: collectibleDiamondPath(size: CGSize(width: 20, height: 20)))
    case .chargeToken:
      color = .systemMint
      labelText = "XP"
      token = SKShapeNode(path: collectibleHexPath(radius: 12))
    case .upgradeHook:
      color = .systemPurple
      labelText = "U"
      token = SKShapeNode(path: collectibleHexPath(radius: 12))
    }

    token.fillColor = color
    token.strokeColor = .white
    token.lineWidth = 2
    token.glowWidth = 3

    let inner = SKShapeNode(circleOfRadius: 3.2)
    inner.fillColor = .white.withAlphaComponent(0.9)
    inner.strokeColor = .clear
    token.addChild(inner)

    let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    label.text = labelText
    label.fontSize = dropType == .chargeToken ? 10 : 12
    label.fontColor = .black
    label.verticalAlignmentMode = .center
    label.zPosition = 1
    token.addChild(label)

    let sparkle = SKShapeNode(circleOfRadius: 1.8)
    sparkle.fillColor = .white
    sparkle.strokeColor = .clear
    sparkle.position = CGPoint(x: 5, y: 5)
    sparkle.alpha = 0.7
    token.addChild(sparkle)

    token.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 1.6)), withKey: "reward-spin")
    sparkle.run(.repeatForever(.sequence([
      .fadeAlpha(to: 0.2, duration: 0.18),
      .fadeAlpha(to: 0.85, duration: 0.22),
    ])), withKey: "reward-sparkle")
    return token
  }

  private func collectibleDiamondPath(size: CGSize) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 0, y: size.height / 2))
    path.addLine(to: CGPoint(x: size.width / 2, y: 0))
    path.addLine(to: CGPoint(x: 0, y: -size.height / 2))
    path.addLine(to: CGPoint(x: -size.width / 2, y: 0))
    path.closeSubpath()
    return path
  }

  private func collectibleHexPath(radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    for index in 0 ..< 6 {
      let angle = (CGFloat(index) * (.pi / 3)) - (.pi / 6)
      let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
      if index == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    path.closeSubpath()
    return path
  }

  private func dropColor(for dropType: RewardDropType) -> SKColor {
    switch dropType {
    case .salvageToken:
      return .systemYellow
    case .chargeToken:
      return .systemMint
    case .upgradeHook:
      return .systemPurple
    }
  }

  private func updateRewardDrops(currentTime: TimeInterval, dt: CGFloat) {
    var collectedDrops: [SKNode] = []

    enumerateChildNodes(withName: "reward-drop") { node, _ in
      node.position.y -= BootstrapConfig.rewardDropDriftSpeed * dt

      if let expiresAt = node.userData?["expiresAt"] as? TimeInterval, currentTime >= expiresAt {
        node.removeFromParent()
        return
      }

      if node.position.y < self.frame.minY - 100 {
        node.removeFromParent()
        return
      }

      let dropLane = (node.userData?["laneIndex"] as? Int) ?? self.nearestLaneIndex(to: node.position.x)
      let shipLanes = self.laneMatchCandidates(forShipX: self.ship.position.x)
      let isWithinCollectionBand = abs(node.position.y - self.ship.position.y) <= BootstrapConfig.rewardCollectionDistanceFromShip
      if isWithinCollectionBand, shipLanes.contains(dropLane) {
        collectedDrops.append(node)
      }
    }

    for drop in collectedDrops {
      collectRewardDrop(drop)
    }
  }

  private func updateSalvageCrates(currentTime: TimeInterval, dt: CGFloat) {
    var collectedCrates: [SKNode] = []

    enumerateChildNodes(withName: "salvage-crate") { node, _ in
      node.position.y -= BootstrapConfig.salvageCrateDriftSpeed * dt

      if let expiresAt = node.userData?["expiresAt"] as? TimeInterval, currentTime >= expiresAt {
        node.removeFromParent()
        return
      }

      if node.position.y < self.frame.minY - 100 {
        node.removeFromParent()
        return
      }

      let crateLane = (node.userData?["laneIndex"] as? Int) ?? self.nearestLaneIndex(to: node.position.x)
      let shipLanes = self.laneMatchCandidates(forShipX: self.ship.position.x)
      let isWithinCollectionBand = abs(node.position.y - self.ship.position.y) <= BootstrapConfig.rewardCollectionDistanceFromShip
      if isWithinCollectionBand, shipLanes.contains(crateLane) {
        collectedCrates.append(node)
      }
    }

    for crate in collectedCrates {
      collectSalvageCrate(crate)
    }
  }

  private func collectRewardDrop(_ drop: SKNode) {
    guard let rawType = drop.userData?["dropType"] as? String, let dropType = RewardDropType(rawValue: rawType) else {
      drop.removeFromParent()
      return
    }

    switch dropType {
    case .salvageToken:
      collectedSalvageTokens += 1
      showFloatingPickupText("SALVAGE +1", at: drop.position, color: .systemYellow)
    case .chargeToken:
      collectedChargeTokens += 1
      chargeTokensTowardOvercharge += 1
      triggerPlayerOverchargeIfNeeded()
      showFloatingPickupText("CHARGE +1", at: drop.position, color: .systemMint)
    case .upgradeHook:
      break
    }

    spawnHitFlash(at: drop.position, color: .systemMint, radius: 12, zPosition: 15)
    drop.removeAllActions()
    drop.removeFromParent()
    rewardStatusLabel.removeAction(forKey: "reward-status-pulse")
    rewardStatusLabel.run(.sequence([
      .scale(to: 1.1, duration: 0.08),
      .scale(to: 1.0, duration: 0.12),
    ]), withKey: "reward-status-pulse")
    refreshCombatStatusUI()
  }

  private func collectSalvageCrate(_ crate: SKNode) {
    let salvageValue = (crate.userData?["salvageValue"] as? Int) ?? BootstrapConfig.salvageCrateSalvageValue
    collectedSalvageTokens += salvageValue
    showFloatingPickupText("SALVAGE +\(salvageValue)", at: crate.position, color: .systemOrange)
    spawnHitFlash(at: crate.position, color: .systemOrange, radius: 18, zPosition: 15)
    crate.removeAllActions()
    crate.removeFromParent()
    rewardStatusLabel.removeAction(forKey: "reward-status-pulse")
    rewardStatusLabel.run(.sequence([
      .scale(to: 1.14, duration: 0.08),
      .scale(to: 1.0, duration: 0.14),
    ]), withKey: "reward-status-pulse")
    refreshCombatStatusUI()
  }

  private func triggerPlayerOverchargeIfNeeded() {
    guard chargeTokensTowardOvercharge >= BootstrapConfig.overchargeTokenThreshold else { return }

    chargeTokensTowardOvercharge = 0
    overchargeEndsAt = max(overchargeEndsAt, currentSceneTime) + BootstrapConfig.overchargeDuration
    rewardStatusLabel.removeAction(forKey: "reward-status-pulse")
    rewardStatusLabel.run(.sequence([
      .scale(to: 1.18, duration: 0.08),
      .scale(to: 1.0, duration: 0.18),
    ]), withKey: "reward-status-pulse")
    spawnHitFlash(at: ship.position, color: .systemMint, radius: 18, zPosition: 15)
  }

  private func showFloatingPickupText(_ text: String, at point: CGPoint, color: SKColor) {
    let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    label.text = text
    label.fontSize = 18
    label.fontColor = color
    label.position = CGPoint(x: point.x, y: point.y + 18)
    label.zPosition = 16
    addChild(label)

    label.run(.sequence([
      .group([
        .moveBy(x: 0, y: 26, duration: 0.55),
        .fadeOut(withDuration: 0.55),
      ]),
      .removeFromParent(),
    ]))
  }
}
