import ARKit
import AVFoundation
import Combine
import RealityKit
import UIKit

@MainActor
final class HouseSession: NSObject, ObservableObject, ARSessionDelegate {
    @Published private(set) var isAR = false
    @Published private(set) var placed = false
    @Published private(set) var locked = false
    @Published private(set) var trackingNormal = false
    @Published private(set) var status = "3D preview. Start AR to scan nearby ground."
    @Published private(set) var placement = Placement()
    @Published var showReference = true { didSet { reference?.isEnabled = showReference } }
    @Published private(set) var cameraDenied = false
    weak var view: ARView?
    private var anchor: AnchorEntity?
    private var placementAnchor: ARAnchor?
    private var adjustments: Entity?
    private var reference: Entity?
    private var permissionPending = false

    func startAR() {
        guard !permissionPending else { return }
        guard ARWorldTrackingConfiguration.isSupported else {
            status = "AR is unavailable on this device. Use the 3D preview."
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: beginAR(); cameraDenied = false
        case .notDetermined:
            permissionPending = true
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    self.permissionPending = false
                    self.cameraDenied = !granted
                    if granted { self.beginAR() }
                    else { self.status = "Camera access denied. Enable it in Settings or use 3D preview." }
                }
            }
        default:
            cameraDenied = true
            status = "Camera access denied. Enable it in Settings or use 3D preview."
        }
    }

    private func beginAR() {
        trackingNormal = false
        status = "Scan textured nearby ground, then tap the marked front-left foundation location."
        isAR = true
    }

    func attach(_ view: ARView, model: Entity, lighting: HouseLighting) {
        self.view = view
        adjustments = nil
        reference = nil
        view.session.delegate = self
        view.session.delegateQueue = .main
        if isAR {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.worldAlignment = .gravity
            lighting.configure(configuration)
            lighting.apply(to: view)
            // No geographic anchors, printed targets, stored maps, or LiDAR requirement.
            view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            view.addGestureRecognizer(tap)
        } else {
            let world = AnchorEntity(world: .zero)
            let pivot = Entity()
            let house = model.clone(recursive: true)
            let bounds = house.visualBounds(relativeTo: nil)
            house.position = -bounds.center
            pivot.addChild(house)
            world.addChild(pivot)
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 50
            camera.look(at: .zero, from: [-23, 15, 27], relativeTo: nil)
            world.addChild(camera)
            let light = DirectionalLight()
            light.light.intensity = 2500
            light.look(at: .zero, from: [-10, 20, -10], relativeTo: nil)
            world.addChild(light)
            view.scene.addAnchor(world)
            adjustments = pivot
        }
    }

    func orbit(_ radians: Float) {
        guard !isAR else { return }
        adjustments?.orientation = simd_quatf(angle: radians, axis: [0, 1, 0])
    }

    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        guard isAR, !locked, trackingNormal, let view else { return }
        guard let hit = view.raycast(from: gesture.location(in: view), allowing: .existingPlaneGeometry,
                                     alignment: .horizontal).first,
              let camera = view.session.currentFrame?.camera else {
            status = "No detected horizontal surface here. Scan more ground and tap nearby."
            return
        }
        let point = SIMD3(hit.worldTransform.columns.3.x, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
        let cameraPoint = SIMD3(camera.transform.columns.3.x, camera.transform.columns.3.y, camera.transform.columns.3.z)
        guard simd_distance(point, cameraPoint) <= 8 else {
            status = "Place within 8 metres first, then walk away."
            return
        }
        // Replace the session anchor only when the visitor explicitly taps/replaces placement.
        clearPlacement()
        let arAnchor = ARAnchor(name: "House front-left foundation", transform: simd_float4x4(translation: point))
        view.session.add(anchor: arAnchor)
        placementAnchor = arAnchor
        let root = AnchorEntity(anchor: arAnchor)
        let group = Entity()
        placement = Placement()
        let delta = cameraPoint - point
        placement.yaw = atan2(delta.x, delta.z)
        group.transform.matrix = placement.transform
        root.addChild(group)
        anchor = root; adjustments = group
        view.scene.addAnchor(root)
        placed = true
        status = "Adjust the corner and facade, then lock. Accuracy needs field testing."
        // The view wrapper installs the already-loaded asset after placement changes.
    }

    func installHouse(_ model: Entity) {
        guard isAR, placed, let group = adjustments, group.children.isEmpty else { return }
        group.addChild(model.clone(recursive: true))
        let guide = Entity()
        let pin = ModelEntity(mesh: .generateSphere(radius: 0.10), materials: [SimpleMaterial(color: .systemGreen, isMetallic: false)])
        pin.position.y = 0.10
        guide.addChild(pin)
        // Arrow stem points toward the facade (+Z); red X points right, blue Z points rear.
        for (size, position, color) in [
            (SIMD3<Float>(1, 0.025, 0.025), SIMD3<Float>(0.5, 0.025, 0), UIColor.systemRed),
            (SIMD3<Float>(0.025, 0.025, 1), SIMD3<Float>(0, 0.025, -0.5), UIColor.systemBlue),
            (SIMD3<Float>(0.05, 0.025, 1), SIMD3<Float>(0, 0.025, 0.5), UIColor.systemYellow)
        ] {
            let bar = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, isMetallic: false)])
            bar.position = position; guide.addChild(bar)
        }
        guide.isEnabled = showReference
        reference = guide; group.addChild(guide)
    }

    var canAdjust: Bool { isAR && placed && !locked && trackingNormal }
    func rotate(_ degrees: Float) {
        guard canAdjust else { return }
        placement.yaw += degrees * .pi / 180
        updateTransform()
    }
    func move(right: Float = 0, rear: Float = 0) {
        guard canAdjust else { return }
        placement.move(right: right, rear: rear); updateTransform()
    }
    func elevate(_ metres: Float) {
        guard canAdjust else { return }
        placement.elevation = min(3.048, max(-1.524, placement.elevation + metres))
        updateTransform()
    }
    private func updateTransform() { adjustments?.transform.matrix = placement.transform }
    func toggleLock() { guard placed else { return }; locked.toggle() }
    func placeAgain() {
        guard isAR, !locked else { return }
        clearPlacement(); status = "Scan ground and tap a new corner."
    }
    private func clearPlacement() {
        if let anchor {
            if let placementAnchor { view?.session.remove(anchor: placementAnchor) }
            view?.scene.removeAnchor(anchor)
        }
        anchor = nil; placementAnchor = nil; adjustments = nil; reference = nil
        placed = false; locked = false; placement = Placement()
    }
    func exitAR(message: String = "3D preview. Placement is reset for each new session.") {
        view?.session.pause()
        clearPlacement()
        trackingNormal = false; isAR = false; status = message
    }
    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let state = camera.trackingState
        Task { @MainActor [weak self] in
            guard let self, self.isAR else { return }
            switch state {
            case .normal:
                self.trackingNormal = true
                self.status = self.placed ? "Tracking normal. One-foot alignment remains unverified." : "Tap detected nearby ground to place the front-left foundation."
            case .notAvailable:
                self.trackingNormal = false; self.status = "Tracking unavailable. Keep still or restart AR."
            case .limited(let reason):
                self.trackingNormal = false
                self.status = "Tracking limited (\(reason)). Move slowly and scan textured surroundings."
            }
        }
    }
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor [weak self] in self?.exitAR(message: "AR interrupted. Start again and place a new corner.") }
    }
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in self?.exitAR(message: "AR stopped: \(message). Use preview or restart.") }
    }
}

private extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4(translation, 1)
    }
}
