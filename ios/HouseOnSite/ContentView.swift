import SwiftUI
import RealityKit

private enum HouseBrand {
    static let navy = Color(red: 0.024, green: 0.09, blue: 0.17)
    static let panel = Color(red: 0.055, green: 0.145, blue: 0.24)
    static let cyan = Color(red: 0.25, green: 0.91, blue: 0.96)
    static let secondary = Color(red: 0.72, green: 0.80, blue: 0.88)
}

struct ContentView: View {
    @StateObject private var asset = HouseAsset()
    @StateObject private var session = HouseSession()
    @StateObject private var photoCapture = ARPhotoCapture()
    @StateObject private var lighting = HouseLighting()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var orbit: Float = 0
    @State private var lastOrbit: Float = 0
    @State private var showControls = false
    private var compact: Bool { verticalSizeClass == .compact }

    var body: some View {
        Group {
            if session.isAR { fieldLens }
            else { cyanStudio }
        }
        .background(HouseBrand.navy)
        .foregroundStyle(.white)
        .tint(HouseBrand.cyan)
        .buttonStyle(HouseButtonStyle())
        .preferredColorScheme(.dark)
        .task { asset.load() }
        .alert(item: $photoCapture.notice) { notice in
            if notice.offerSettings {
                return Alert(title: Text(notice.title), message: Text(notice.message),
                             primaryButton: .default(Text("Open Settings")) { openSettings() },
                             secondaryButton: .cancel())
            }
            return Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("OK")))
        }
        .onChange(of: scenePhase) { _, phase in
            if session.isAR && (phase == .background || (phase == .inactive && !photoCapture.permissionPromptActive)) {
                session.exitAR(message: "App left foreground. Start AR and place again.")
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            Image("BrandMark")
                .resizable().scaledToFit().frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("House on Site").font(.headline)
                Text(session.isAR ? "ON-SITE VIEW" : "SEE YOUR FUTURE HOME")
                    .font(.caption2.weight(.medium)).tracking(1.7)
                    .foregroundStyle(HouseBrand.cyan)
            }
            Spacer(minLength: 0)
        }
    }

    private var modelHeading: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(asset.displayName).font(compact ? .headline : .title.bold())
            if !compact {
                Text(asset.dimensionSummary).font(.subheadline).foregroundStyle(HouseBrand.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var viewer: some View {
        Group {
            if let model = asset.entity {
                HouseView(session: session, lighting: lighting, model: model, orbit: orbit)
                    .id(session.isAR)
                    .gesture(DragGesture().onChanged { value in
                        if !session.isAR { orbit = lastOrbit + Float(value.translation.width) * 0.008 }
                    }.onEnded { _ in lastOrbit = orbit })
            } else {
                ZStack {
                    HouseBrand.navy
                    if asset.loading { ProgressView("Loading \(asset.displayName)…") }
                }
            }
        }
    }

    private var cyanStudio: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: compact ? 12 : 20) {
                    brandHeader
                    modelHeading
                    viewer
                        .frame(height: max(compact ? 180 : 240, geometry.size.height * (compact ? 0.55 : 0.43)))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .topLeading) {
                            Label("3D preview · drag to orbit", systemImage: "rotate.3d")
                                .font(.caption.weight(.medium)).padding(10)
                                .background(HouseBrand.panel, in: RoundedRectangle(cornerRadius: 9))
                                .padding(12)
                        }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bring \(asset.displayName) onto your lot").font(.headline)
                        Text("Place the front-left foundation corner, then adjust the facade.")
                            .font(.subheadline).foregroundStyle(HouseBrand.secondary)
                        Button { session.startAR() } label: {
                            Label("Start AR", systemImage: "viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HouseButtonStyle(prominent: true))
                        .disabled(asset.entity == nil)
                        recoveryActions
                    }
                    .padding(18).background(HouseBrand.panel, in: RoundedRectangle(cornerRadius: 20))
                    Text("AR field prototype. Outdoor accuracy needs field testing. Each visitor places independently.")
                        .font(.caption).foregroundStyle(HouseBrand.secondary)
                }
                .padding(compact ? 12 : 20)
            }
        }
    }

    private var fieldLens: some View {
        viewer
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                Button { photoCapture.capture(view: session.view) } label: {
                    Label(photoCapture.busy ? "Saving…" : "Capture", systemImage: "camera.fill")
                }
                .disabled(!session.placed || photoCapture.busy)
                .accessibilityLabel("Capture AR photo to Photos")
                .padding(16)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    if !compact { brandHeader }
                    HStack(alignment: .top) {
                        modelHeading
                        Text("AR FIELD\nPROTOTYPE")
                            .font(.caption2.weight(.medium)).multilineTextAlignment(.trailing)
                            .foregroundStyle(HouseBrand.cyan)
                    }
                }
                .padding(compact ? 10 : 16)
                .background(HouseBrand.navy.opacity(0.94))
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Placement").font(.headline)
                                Spacer()
                                Text(session.locked ? "Edits locked" : "Editing")
                                    .font(.caption).foregroundStyle(HouseBrand.cyan)
                            }
                            recoveryActions
                            DisclosureGroup("House controls", isExpanded: $showControls) {
                                houseControls.padding(.top, 12)
                            }
                        }
                    }
                    .frame(maxHeight: showControls ? (compact ? 110 : 300) : (compact ? 60 : 130))
                    HStack(spacing: 10) {
                        Button("3D preview") { session.exitAR() }
                        Button { session.toggleLock() } label: {
                            Label(session.locked ? "Unlock placement" : "Lock placement",
                                  systemImage: session.locked ? "lock.open" : "lock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HouseButtonStyle(prominent: true))
                        .disabled(!session.placed)
                    }
                }
                .padding(compact ? 10 : 16)
                .background(HouseBrand.panel, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
            }
    }

    private var recoveryActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(session.status).font(.caption).foregroundStyle(HouseBrand.secondary)
            if let error = asset.error {
                Text(error).font(.caption).foregroundStyle(.red)
                Button("Retry house loading") { asset.load() }
            }
            if photoCapture.hasUnsavedPhoto && !photoCapture.busy {
                Button("Retry saving photo") { photoCapture.retrySave() }
            }
            if session.cameraDenied {
                Button("Open camera settings") { openSettings() }
            }
        }
    }

    private var houseControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lighting").font(.subheadline.weight(.semibold))
                Spacer()
                Button("Auto") { lighting.resetToAuto() }.disabled(lighting.isAuto)
            }
            HStack {
                Text("House brightness")
                Spacer()
                Text("\(lighting.brightnessPercent)%").monospacedDigit()
            }.font(.subheadline)
            Slider(value: $lighting.brightnessStops, in: -2...2, step: 0.1)
                .accessibilityLabel("House brightness")
                .accessibilityValue("\(lighting.brightnessPercent) percent of automatic lighting")
            Text(lighting.isAuto ? "Auto · lighting follows your surroundings" : "Auto lighting with brightness adjustment")
                .font(.caption).foregroundStyle(HouseBrand.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("Green pin: marked front-left foundation. Yellow: front. Red: right. Blue: rear.")
                    .font(.caption).foregroundStyle(HouseBrand.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    adjustment("Rotate −1°") { session.rotate(-1) }
                    adjustment("Rotate +1°") { session.rotate(1) }
                    adjustment("Left 1′") { session.move(right: -0.3048) }
                    adjustment("Right 1′") { session.move(right: 0.3048) }
                    adjustment("Forward 1′") { session.move(rear: -0.3048) }
                    adjustment("Rear 1′") { session.move(rear: 0.3048) }
                    adjustment("Lower 3″") { session.elevate(-0.0762) }
                    adjustment("Raise 3″") { session.elevate(0.0762) }
                }
                Text(String(format: "Rotation %.1f° · elevation %.2f′", session.placement.yaw * 180 / .pi, session.placement.elevation / 0.3048))
                    .font(.caption).monospacedDigit()
            }.disabled(!session.canAdjust)
            Toggle("Corner and direction guides", isOn: $session.showReference).font(.subheadline)
            Button("Place again") { session.placeAgain() }.disabled(session.locked)
            Text("Lock freezes edits; tracking can still drift. Accuracy needs field testing.")
                .font(.caption).foregroundStyle(HouseBrand.secondary)
        }
    }

    private func adjustment(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).frame(maxWidth: .infinity) }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

private struct HouseButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(minHeight: 44)
            .foregroundStyle(prominent ? HouseBrand.navy : Color.white)
            .background(prominent ? HouseBrand.cyan : Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
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
