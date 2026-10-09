import Foundation
import simd

func near(_ actual: SIMD3<Float>, _ expected: SIMD3<Float>) {
    precondition(simd_distance(actual, expected) < 0.00001, "\(actual) != \(expected)")
}
var p = Placement()
p.move(right: 0.3048, rear: 0.3048)
near(p.offset, [0.3048, 0, -0.3048])
p = Placement()
p.yaw = .pi / 2
p.move(right: 0.3048, rear: 0)
near(p.offset, [0, 0, -0.3048])
p.move(right: 0, rear: 0.3048)
near(p.offset, [-0.3048, 0, -0.3048])
p.elevation = 0.0762
let origin = p.transform * SIMD4<Float>(0, 0, 0, 1)
near(SIMD3(origin.x, origin.y, origin.z), [-0.3048, 0.0762, -0.3048])
let front = p.rotation.act([0, 0, 1])
near(front, [1, 0, 0])
print("Native placement checks passed: metre steps, rotated directions, elevation, corner pivot, facade direction.")
