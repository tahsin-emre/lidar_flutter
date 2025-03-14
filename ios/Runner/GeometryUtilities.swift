import Foundation
import SceneKit

// MARK: - SceneKit Geometri Uzantıları

extension SCNGeometry {
  /// İki vektör arasında çizgi geometrisi oluşturur
  class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3, radius: CGFloat) -> SCNGeometry {
    let indices: [Int32] = [0, 1]
    
    let source = SCNGeometrySource(vertices: [vector1, vector2])
    let element = SCNGeometryElement(indices: indices, primitiveType: .line)
    
    let line = SCNGeometry(sources: [source], elements: [element])
    return line
  }
}

// MARK: - SceneKit Vektör Uzantıları

extension SCNVector3 {
  /// Vektörü normalize eder
  func normalized() -> SCNVector3 {
    let length = sqrt(x * x + y * y + z * z)
    guard length > 0 else { return self }
    return SCNVector3(x / length, y / length, z / length)
  }
  
  /// İki vektör arasındaki mesafeyi hesaplar
  func distance(to other: SCNVector3) -> Float {
    let dx = self.x - other.x
    let dy = self.y - other.y
    let dz = self.z - other.z
    return sqrt(dx*dx + dy*dy + dz*dz)
  }
}

/// Vektör normalize etme fonksiyonu
func normalize(_ vector: SCNVector3) -> SCNVector3 {
  let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
  guard length > 0 else { return SCNVector3(0, 0, 0) }
  return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
} 