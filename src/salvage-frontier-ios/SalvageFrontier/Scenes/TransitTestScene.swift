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
  private let breachLine = SKShapeNode()

  private var laneGuides: [SKShapeNode] = []
  private var laneCenters: [CGFloat] = []
  private var currentLaneIndex = 0

  private var controllingTouch: UITouch?
  private var controllingTouchX: CGFloat?

  private var shipVelocityX: CGFloat = 0
  private var lastShotTime: TimeInterval = 0
  private var lastUpdateTime: TimeInterval?
  private var playerHull = BootstrapConfig.playerHullMax
  private var targetRespawnPending = false
  private var nextTargetSpawnTime: TimeInterval?
  private let enemyDefinitionsByID = Dictionary(
    uniqueKeysWithValues: PrototypeDefinitions.enemies.map { ($0.id, $0) }
  )
  private let weaponDefinitionsByID = Dictionary(
    uniqueKeysWithValues: PrototypeDefinitions.weapons.map { ($0.id, $0) }
  )
  private var lastEncounterPatternID: String?

  override func didMove(to view: SKView) {
    scaleMode = .resizeFill
    backgroundColor = .black
    configurePhysicsWorld()

    ship.position = CGPoint(x: frame.midX, y: 180)
    addChild(ship)

    configureLaneGuides()
    spawnEncounterEnemies()
    configureOverlayLabels()
    refreshCombatStatusUI()

    currentLaneIndex = nearestLaneIndex(to: ship.position.x)
    refreshLaneReadabilityUI()
  }

  override func update(_ currentTime: TimeInterval) {
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
    evaluateTargetBreachRisk()
    updateTargetPracticeLoop(currentTime)

    if currentTime - lastShotTime >= BootstrapConfig.autoFireInterval {
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
    if controllingTouch == nil {
      controllingTouch = touches.first
    }
    refreshControllingTouch(from: event)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    refreshControllingTouch(from: event)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    refreshControllingTouch(from: event)
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    let projectile = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 3)
    projectile.fillColor = .white
    projectile.strokeColor = .clear
    projectile.position = CGPoint(x: ship.position.x, y: ship.position.y + 35)
    projectile.name = "projectile"
    projectile.zPosition = 10

    let body = SKPhysicsBody(rectangleOf: CGSize(width: 6, height: 18))
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

  private func configurePhysicsWorld() {
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
  }

  private func handleProjectileHit(projectile: SKNode, target: SKNode, at contactPoint: CGPoint) {
    projectile.removeFromParent()
    applyPrototypeDamage(BootstrapConfig.playerProjectileDamage, to: target, at: contactPoint)
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

    spawnHitFlash(at: point)
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
      if currentTime < nextFireTime {
        return
      }

      self.fireEnemyProjectile(from: node, weapon: weapon)
      node.userData?["nextFireTime"] = currentTime + weapon.rateOfFire
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
      spawnHitFlash(at: ship.position)
    }
  }

  private func fireEnemyProjectile(from enemy: SKNode, weapon: WeaponDefinition) {
    let projectile = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 2)
    projectile.fillColor = colorForProjectileStyle(weapon.projectileStyleID)
    projectile.strokeColor = .clear
    projectile.name = "enemy-projectile"
    projectile.zPosition = 9
    projectile.position = CGPoint(x: enemy.position.x, y: enemy.position.y - 34)
    projectile.userData = NSMutableDictionary(dictionary: [
      "damage": weapon.damage,
      "projectileSpeed": weapon.projectileSpeed,
    ])
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
    playerHull = max(0, playerHull - amount)
    refreshCombatStatusUI()
    flashShipForHullHit()
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

  private func spawnHitFlash(at point: CGPoint) {
    let flash = SKShapeNode(circleOfRadius: 8)
    flash.fillColor = .white
    flash.strokeColor = .clear
    flash.alpha = 0.85
    flash.position = point
    flash.zPosition = 12
    addChild(flash)

    let fade = SKAction.fadeOut(withDuration: 0.12)
    flash.run(.sequence([fade, .removeFromParent()]))
  }

  private func destroyTarget(_ target: SKNode, at point: CGPoint, cueColor: SKColor) {
    target.removeAllActions()
    target.removeFromParent()
    spawnTargetDestroyedCue(at: point, color: cueColor)
  }

  private func spawnTargetDestroyedCue(at point: CGPoint, color: SKColor) {
    let ring = SKShapeNode(circleOfRadius: 22)
    ring.fillColor = .clear
    ring.strokeColor = color
    ring.lineWidth = 4
    ring.alpha = 0.9
    ring.position = point
    ring.zPosition = 11
    addChild(ring)

    let pop = SKAction.scale(to: 1.45, duration: 0.16)
    let fade = SKAction.fadeOut(withDuration: 0.16)
    ring.run(.sequence([.group([pop, fade]), .removeFromParent()]))
  }

  private func flashShipForHullHit() {
    ship.removeAction(forKey: "hull-hit-flash")

    let flashOn = SKAction.run { [weak self] in
      self?.ship.fillColor = .systemRed
    }
    let wait = SKAction.wait(forDuration: 0.12)
    let flashOff = SKAction.run { [weak self] in
      self?.ship.fillColor = .cyan
    }

    ship.run(.sequence([flashOn, wait, flashOff]), withKey: "hull-hit-flash")
  }

  private func spawnEncounterEnemies() {
    guard !laneCenters.isEmpty else { return }
    guard let pattern = nextEncounterPattern() else { return }

    for entry in pattern.entries {
      guard laneCenters.indices.contains(entry.laneIndex) else {
        continue
      }
      guard let definition = enemyDefinitionsByID[entry.enemyID] else {
        continue
      }

      let enemy = makeEnemyNode(definition: definition, initialFireDelay: entry.initialFireDelay)
      enemy.position = CGPoint(
        x: laneCenters[entry.laneIndex],
        y: frame.maxY + entry.spawnYOffset
      )
      addChild(enemy)
    }

    lastEncounterPatternID = pattern.id
    refreshCombatStatusUI()
  }

  private func nextEncounterPattern() -> EncounterPatternDefinition? {
    let patterns = PrototypeDefinitions.encounterPatterns.filter { pattern in
      pattern.entries.allSatisfy { entry in
        laneCenters.indices.contains(entry.laneIndex) && enemyDefinitionsByID[entry.enemyID] != nil
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
    ])
    if let weaponID = definition.weaponID {
      enemy.userData?["weaponID"] = weaponID
      enemy.userData?["nextFireTime"] = 0.0
      enemy.userData?["hasEnteredPlayfield"] = false
      enemy.userData?["initialFireDelay"] = initialFireDelay ?? weaponDefinitionsByID[weaponID]?.rateOfFire ?? 0
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
      node.fillColor = .systemTeal
      node.strokeColor = .white
      node.lineWidth = 2
      return node

    default:
      let node = SKShapeNode(rectOf: CGSize(width: 86, height: 48), cornerRadius: 12)
      node.fillColor = .systemRed
      node.strokeColor = .white
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

  private func configureLaneGuides() {
    breachLine.removeFromParent()
    laneGuides.forEach { $0.removeFromParent() }
    laneGuides.removeAll()
    laneCenters.removeAll()

    let minX = BootstrapConfig.lanePadding
    let maxX = frame.width - BootstrapConfig.lanePadding
    let laneCount = max(BootstrapConfig.laneCount, 2)
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
  }

  private func refreshControllingTouch(from event: UIEvent?) {
    guard let allTouches = event?.allTouches else {
      controllingTouch = nil
      controllingTouchX = nil
      return
    }

    let activeTouches = allTouches.filter {
      $0.phase == .began || $0.phase == .moved || $0.phase == .stationary
    }

    if let controllingTouch,
       let matchedTouch = activeTouches.first(where: { $0 === controllingTouch }) {
      controllingTouchX = matchedTouch.location(in: self).x
      return
    }

    controllingTouch = activeTouches.first
    controllingTouchX = controllingTouch?.location(in: self).x
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
}
