import Foundation
import simd

/// Metres; canonical +X facade-right, -Z rear, +Z front. Rotate and elevate around the foundation corner.
struct Placement {
    var yaw: Float = 0
    var offset = SIMD3<Float>.zero
    var elevation: Float = 0
    var rotation: simd_quatf { simd_quatf(angle: yaw, axis: [0, 1, 0]) }
    mutating func move(right: Float, rear: Float) {
        offset += rotation.act([right, 0, -rear])
    }
    var transform: simd_float4x4 {
        var result = simd_float4x4(rotation)
        result.columns.3 = SIMD4(offset.x, elevation, offset.z, 1)
        return result
    }
}
