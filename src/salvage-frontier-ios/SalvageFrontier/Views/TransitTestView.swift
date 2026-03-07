import SpriteKit
import SwiftUI

struct TransitTestView: View {
  private let scene = TransitTestScene(size: CGSize(width: 1080, height: 1920))

  var body: some View {
    ZStack(alignment: .topLeading) {
      SpriteView(scene: scene)
        .ignoresSafeArea()

      Text("Transit Target Practice Slice")
        .font(.headline)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding()
    }
  }
}
