import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var asset = HouseAsset()
    @StateObject private var session = HouseSession()
    @StateObject private var photoCapture = ARPhotoCapture()
    @StateObject private var lighting = HouseLighting()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var orbit: Float = 0
    @State private var lastOrbit: Float = 0
    @State private var showControls = true

    var body: some View {
        VStack(spacing: 8) {
            Text("House on Site").font(.title2.bold())
            if verticalSizeClass != .compact {
                Text("≈ 50′ wide × 45′ deep × 27′ high").font(.subheadline)
            }
            if let model = asset.entity {
                HouseView(session: session, lighting: lighting, model: model, orbit: orbit)
                    .id(session.isAR)
                    .gesture(DragGesture().onChanged { value in
                        if !session.isAR { orbit = lastOrbit + Float(value.translation.width) * 0.008 }
                    }.onEnded { _ in lastOrbit = orbit })
                    .overlay(alignment: .topLeading) {
                        Text(session.isAR ? "AR field prototype" : "3D preview • drag to orbit")
                            .font(.caption.bold()).padding(8).background(.regularMaterial).cornerRadius(8).padding(8)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if session.isAR {
                            Button {
                                photoCapture.capture(view: session.view)
                            } label: {
                                Label(photoCapture.busy ? "Saving…" : "Capture", systemImage: "camera.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!session.placed || photoCapture.busy)
                            .accessibilityLabel("Capture AR photo to Photos")
                            .padding(8)
                        }
                    }
            } else {
                Spacer()
                if asset.loading { ProgressView("Loading house…") }
                Spacer()
            }
            if let error = asset.error {
                Text(error).font(.caption).foregroundStyle(.red)
                Button("Retry house loading") { asset.load() }
            }
            Text(session.status).font(.callout)
            if photoCapture.hasUnsavedPhoto && !photoCapture.busy {
                Button("Retry saving photo") { photoCapture.retrySave() }
            }
            if session.cameraDenied {
                Button("Open camera settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            if session.isAR {
                HStack {
                    Button("3D preview") { session.exitAR() }
                    Spacer()
                    Button(session.locked ? "Unlock" : "Lock placement") { session.toggleLock() }
                        .disabled(!session.placed)
                }
                ScrollView {
                DisclosureGroup("House controls", isExpanded: $showControls) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lighting").font(.headline)
                            Spacer()
                            Button("Auto") { lighting.resetToAuto() }
                                .disabled(lighting.isAuto)
                        }
                        HStack {
                            Text("House brightness")
                            Spacer()
                            Text("\(lighting.brightnessPercent)%").monospacedDigit()
                        }
                        Slider(value: $lighting.brightnessStops, in: -2...2, step: 0.1)
                            .accessibilityLabel("House brightness")
                            .accessibilityValue("\(lighting.brightnessPercent) percent of automatic lighting")
                        Text(lighting.isAuto ? "Auto • lighting follows your surroundings" : "Auto lighting with brightness adjustment")
                            .font(.caption)
                        Divider()
                        Text("Placement").font(.headline)
                    }

                    VStack(spacing: 8) {
                        Text("Green pin: marked front-left foundation. Yellow: front. Red: right. Blue: rear.")
                            .font(.caption)
                        HStack {
                            Button("Rotate −1°") { session.rotate(-1) }
                            Button("Rotate +1°") { session.rotate(1) }
                        }
                        HStack {
                            Button("Left 1′") { session.move(right: -0.3048) }
                            Button("Right 1′") { session.move(right: 0.3048) }
                        }
                        HStack {
                            Button("Forward 1′") { session.move(rear: -0.3048) }
                            Button("Rear 1′") { session.move(rear: 0.3048) }
                        }
                        HStack {
                            Button("Lower 3″") { session.elevate(-0.0762) }
                            Button("Raise 3″") { session.elevate(0.0762) }
                        }
                        Text(String(format: "Rotation %.1f° • elevation %.2f′", session.placement.yaw * 180 / .pi, session.placement.elevation / 0.3048))
                            .font(.caption).monospacedDigit()
                    }.disabled(!session.canAdjust)
                    Toggle("Corner and direction guides", isOn: $session.showReference)
                    Button("Place again") { session.placeAgain() }.disabled(session.locked)
                }
                }.frame(maxHeight: showControls ? (verticalSizeClass == .compact ? 100 : 260) : 44)
            } else {
                Button("Start AR") { session.startAR() }
                    .buttonStyle(.borderedProminent).disabled(asset.entity == nil)
                Text("Each visitor places independently. No printed target. One-foot alignment over walks up to 100′ requires outdoor testing.")
                    .font(.caption)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(verticalSizeClass == .compact ? 8 : 16)
        .task { asset.load() }
        .alert(item: $photoCapture.notice) { notice in
            if notice.offerSettings {
                return Alert(title: Text(notice.title), message: Text(notice.message),
                             primaryButton: .default(Text("Open Settings")) {
                                 if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                             }, secondaryButton: .cancel())
            }
            return Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("OK")))
        }
        .onChange(of: scenePhase) { _, phase in
            if session.isAR && (phase == .background || (phase == .inactive && !photoCapture.permissionPromptActive)) {
                session.exitAR(message: "App left foreground. Start AR and place again.")
            }
        }
    }
}

private struct HouseView: UIViewRepresentable {
    @ObservedObject var session: HouseSession
    @ObservedObject var lighting: HouseLighting
    let model: Entity
    let orbit: Float
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: session.isAR ? .ar : .nonAR, automaticallyConfigureSession: false)
        session.attach(view, model: model, lighting: lighting)
        return view
    }
    func updateUIView(_ view: ARView, context: Context) {
        if session.isAR {
            session.installHouse(model)
            lighting.apply(to: view)
        }
        else { session.orbit(orbit) }
    }
    static func dismantleUIView(_ view: ARView, coordinator: ()) {
        view.session.pause()
        view.session.delegate = nil
        view.scene.anchors.removeAll()
    }
}
