import Foundation
import ARKit
import simd

// MARK: - ARKit Yardımcı Fonksiyonlar

/// simd transformasyon matrisinin üst sol 3x3 kısmını çıkarır
func simd_matrix_upper_left_3x3(_ matrix: simd_float4x4) -> simd_float3x3 {
  return simd_float3x3(
    simd_float3(matrix[0][0], matrix[0][1], matrix[0][2]),
    simd_float3(matrix[1][0], matrix[1][1], matrix[1][2]),
    simd_float3(matrix[2][0], matrix[2][1], matrix[2][2])
  )
}

/// 3D dünya koordinatlarını hesaplar
func transformPointToWorldSpace(_ point: simd_float3, frame: ARFrame) -> simd_float3 {
  let cameraIntrinsics = frame.camera.intrinsics
  let cameraTransform = frame.camera.transform
  
  // 3D koordinata dönüştür
  let x = (point.x - 0.5) * point.z / cameraIntrinsics[0][0]
  let y = (0.5 - point.y) * point.z / cameraIntrinsics[1][1]
  let z = point.z
  
  // Kameraya göre koordinatlar
  let cameraPoint = simd_float4(x, y, z, 1)
  
  // Dünya koordinatlarına dönüştür
  let worldPoint = simd_mul(cameraTransform, cameraPoint)
  
  return simd_float3(worldPoint.x, worldPoint.y, worldPoint.z)
}

/// Derinlik haritasından normal tahmini yapar
func estimateNormalFromDepthMap(x: Int, y: Int, depthMap: CVPixelBuffer, bytesPerRow: Int) -> simd_float3? {
  guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return nil }
  
  // Merkez pikselin derinliği
  let centerOffset = y * bytesPerRow + x * MemoryLayout<Float32>.size
  let centerDepth = baseAddress.load(fromByteOffset: centerOffset, as: Float32.self)
  
  // Geçerli bir derinlik değilse hesaplama yapma
  if centerDepth <= 0 { return nil }
  
  // Komşu piksellerin derinlikleri
  let leftOffset = y * bytesPerRow + (x-1) * MemoryLayout<Float32>.size
  let rightOffset = y * bytesPerRow + (x+1) * MemoryLayout<Float32>.size
  let topOffset = (y-1) * bytesPerRow + x * MemoryLayout<Float32>.size
  let bottomOffset = (y+1) * bytesPerRow + x * MemoryLayout<Float32>.size
  
  let leftDepth = baseAddress.load(fromByteOffset: leftOffset, as: Float32.self)
  let rightDepth = baseAddress.load(fromByteOffset: rightOffset, as: Float32.self)
  let topDepth = baseAddress.load(fromByteOffset: topOffset, as: Float32.self)
  let bottomDepth = baseAddress.load(fromByteOffset: bottomOffset, as: Float32.self)
  
  // Geçerli derinlik değerleri kontrolü
  if leftDepth <= 0 || rightDepth <= 0 || topDepth <= 0 || bottomDepth <= 0 {
    return nil
  }
  
  // X ve Y yönünde derinlik gradyanları
  let dzdx = (rightDepth - leftDepth) / 2.0
  let dzdy = (bottomDepth - topDepth) / 2.0
  
  // Normal vektör hesabı
  let normal = simd_normalize(simd_float3(-dzdx, -dzdy, 1.0))
  return normal
} 