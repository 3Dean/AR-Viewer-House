import AppKit
import SceneKit
import RealityKit

let root = CommandLine.arguments[1]
let url = URL(fileURLWithPath: root + "/public/models/ios/house2story.usdz")
let entity = try Entity.load(contentsOf: url)
let bounds = entity.visualBounds(relativeTo: nil)
print("RealityKit bounds: \(bounds.min) to \(bounds.max); size \(bounds.extents)")
precondition(abs(bounds.extents.x - 15.299134) < 0.01)
precondition(abs(bounds.extents.y - 8.30093) < 0.01)
precondition(abs(bounds.extents.z - 13.767526) < 0.01)
let scene = try SCNScene(url: url)
let camera = SCNNode()
camera.camera = SCNCamera()
camera.camera!.usesOrthographicProjection = true
camera.camera!.orthographicScale = 11
camera.position = SCNVector3(-28, 17, 26)
let target = SCNNode(); target.position = SCNVector3(7, 4, -3); scene.rootNode.addChildNode(target)
let look = SCNLookAtConstraint(target: target); look.isGimbalLockEnabled = true
camera.constraints = [look]; scene.rootNode.addChildNode(camera)
let light = SCNNode(); light.light = SCNLight(); light.light!.type = .omni
light.light!.intensity = 1500; light.position = SCNVector3(18,20,15); scene.rootNode.addChildNode(light)
let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light!.type = .ambient
ambient.light!.intensity = 500; scene.rootNode.addChildNode(ambient)
scene.background.contents = NSColor(calibratedRed: 0.82, green: 0.88, blue: 0.92, alpha: 1)
let pin = SCNNode(geometry: SCNSphere(radius: 0.22))
pin.geometry!.firstMaterial!.diffuse.contents = NSColor.systemGreen
pin.geometry!.firstMaterial!.emission.contents = NSColor.systemGreen
pin.position = SCNVector3(0, 0.22, 0)
scene.rootNode.addChildNode(pin)
let renderer = SCNRenderer(device: nil, options: nil)
renderer.scene = scene; renderer.pointOfView = camera
let image = renderer.snapshot(atTime: 0, with: CGSize(width: 1000,height: 900), antialiasingMode: .multisampling4X)
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: root + "/docs/model-review/usdz-native.png"))
