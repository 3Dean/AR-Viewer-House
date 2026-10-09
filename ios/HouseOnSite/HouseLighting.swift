import ARKit
import Combine
import Foundation
import RealityKit

/// Automatic environment lighting with a bounded virtual-scene brightness offset.
/// Does not change camera exposure, source materials, or placement transforms.
@MainActor
final class HouseLighting: ObservableObject {
    @Published var brightnessStops: Double = 0
    var brightnessPercent: Int { Int((pow(2, brightnessStops) * 100).rounded()) }
    var isAuto: Bool { abs(brightnessStops) < 0.001 }

    func configure(_ configuration: ARWorldTrackingConfiguration) {
        configuration.isLightEstimationEnabled = true
        configuration.environmentTexturing = .automatic
    }

    func apply(to view: ARView) {
        guard view.cameraMode == .ar else { return }
        view.renderOptions.remove(.disableAREnvironmentLighting)
        // RealityKit defines IBL intensity as 2^exponent: -2…+2 = 25%…400%.
        view.environment.lighting.intensityExponent = Float(min(2, max(-2, brightnessStops)))
    }

    func resetToAuto() { brightnessStops = 0 }
}
