import SpriteKit

final class TransitTestScene: SKScene {
  private let ship = SKShapeNode(rectOf: CGSize(width: 70, height: 34), cornerRadius: 8)
  private var pressedLeft = false
  private var pressedRight = false
  private var lastShotTime: TimeInterval = 0

  override func didMove(to view: SKView) {
    scaleMode = .resizeFill
    backgroundColor = .black

    ship.fillColor = .cyan
    ship.strokeColor = .clear
    ship.position = CGPoint(x: frame.midX, y: 180)
    ship.name = "ship"
    addChild(ship)

    addTestLanes()
    addInputHints()
  }

  override func update(_ currentTime: TimeInterval) {
    var dx: CGFloat = 0
    if pressedLeft { dx -= 1 }
    if pressedRight { dx += 1 }

    ship.position.x += dx * BootstrapConfig.shipSpeed * CGFloat(1.0 / 60.0)

    let minX = BootstrapConfig.lanePadding
    let maxX = frame.width - BootstrapConfig.lanePadding
    ship.position.x = min(max(ship.position.x, minX), maxX)

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
    for touch in touches {
      let x = touch.location(in: self).x
      if x < frame.midX {
        pressedLeft = true
      } else {
        pressedRight = true
      }
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    pressedLeft = false
    pressedRight = false
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    pressedLeft = false
    pressedRight = false
  }

  private func fireProjectile() {
    let projectile = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 3)
    projectile.fillColor = .white
    projectile.strokeColor = .clear
    projectile.position = CGPoint(x: ship.position.x, y: ship.position.y + 35)
    projectile.name = "projectile"

    addChild(projectile)

    let travelDistance = frame.height + 200
    let travelTime = TimeInterval(travelDistance / BootstrapConfig.bulletSpeed)
    let moveUp = SKAction.moveBy(x: 0, y: travelDistance, duration: travelTime)
    let cleanup = SKAction.removeFromParent()
    projectile.run(.sequence([moveUp, cleanup]))
  }

  private func addTestLanes() {
    let laneWidth = frame.width - (BootstrapConfig.lanePadding * 2)
    let guide = SKShapeNode(rectOf: CGSize(width: laneWidth, height: 3), cornerRadius: 1)
    guide.fillColor = .darkGray
    guide.strokeColor = .clear
    guide.position = CGPoint(x: frame.midX, y: 125)
    addChild(guide)
  }

  private func addInputHints() {
    let label = SKLabelNode(text: "Tap left/right to move. Auto-fire is active.")
    label.fontName = "AvenirNext-Regular"
    label.fontSize = 24
    label.fontColor = .lightGray
    label.position = CGPoint(x: frame.midX, y: frame.height - 120)
    addChild(label)
  }
}
