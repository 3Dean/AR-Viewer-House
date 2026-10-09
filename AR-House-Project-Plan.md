# Outdoor AR House Viewer — Project Plan

## Direction and objective

As of October 8, 2026, the active prototype is a native iPhone app using Swift, SwiftUI, ARKit, and RealityKit. Zapworks commercial pricing exceeds the project budget. Preserve the TypeScript/Three.js/Zappar web prototype at baseline commit `5174008`; it remains a separate experimental viewer, not the active production AR path. No web implementation is removed or migrated in place.

Visitors independently place a life-size house on a lot, align it, and walk up to 100 feet (30.48 m). Each session is local and temporary. No printed target, geographic anchor, persistent map, or shared placement is required. Approximately one-foot (0.3048 m) alignment is a **field-test target**, not an established capability. Native app installation is now required; the earlier no-install browser requirement is superseded.

Begin with free Xcode Personal Team testing on the owner's iPhone. Distribution to visitors is a later decision. Android support is considered after the iPhone feasibility gate, likely through a separately implemented native ARCore adapter; it is not currently implemented.

## Requirements

- Source: original `house2story.glb`, unchanged. Derived RealityKit asset: `public/models/ios/house2story.usdz`, bundled by the Xcode project in `ios/`.
- Nominal dimensions: approximately 50′ wide × 45′ deep × 27′ high. Actual transformed bounds: 15.2991 × 13.7675 × 8.3009 m (width × depth × height), approximately 50.19′ × 45.17′ × 27.23′. Preserve glTF metre units and proportions; do not stretch axes or offer visitor scaling.
- Corner: front-left **outer side-wing foundation ground corner** while facing the entrance facade. The leftmost wing is recessed relative to the central entrance facade. Use its actual front-left foundation vertex, not the empty corner of the overall footprint bounds or the entry steps on the right. Document the selected feature explicitly rather than substituting the bounding corner.
- Controls: initial ground tap, rotation, house-relative horizontal movement, elevation, lock/unlock, place again, and return to 3D preview.
- Lock freezes visitor edits; it does not freeze tracking or eliminate drift.
- Unsupported devices and camera denial retain the interactive 3D preview.
- Unknown terrain slope; keep the house upright. Elevation is a vertical offset, not terrain fitting.

## Architecture and current implementation

`ios/HouseOnSite.xcodeproj` is an iOS 17+ iPhone app with no external SDK, package manager, server, or licence key. Xcode on macOS builds and signs it. Windows can edit source and retain the web workflow, but cannot run Xcode/device signing locally.

- `HouseAsset.swift`: demand-driven USDZ loading, reusable entity, retry and retained entity on loading failure.
- `Placement.swift`: independent metric placement math; yaw, house-relative movement, and elevation about the normalized reference.
- `HouseSession.swift`: ARKit world tracking and session lifecycle, detected-horizontal-plane raycasts, tracking feedback, and RealityKit display.
- `ContentView.swift`: SwiftUI preview, instructions, permission recovery, and placement controls.
- `ios/tools/prepare_house.py`: reproducible converter for this specific inspected GLB, with geometry, normals, UVs, embedded textures, and USD Preview Surface material mapping. It is not a general GLB importer.

ARKit provides a metric world-tracking session. Place on detected horizontal plane geometry near the visitor (within 8 m), with normal tracking. There is no approximate phone-height input. Estimated-plane raycasts are deliberately not used. Horizontal surfaces still require the visitor to choose ground: a table or raised surface is not automatically classified as ground. Position the reference on a nearby detected surface, then use the controls for alignment. Do not interpret normal tracking as a quantified accuracy guarantee.

Scene interruptions, backgrounding, and session errors pause tracking and discard placement. The visitor returns to preview and starts a fresh session. No silent reuse of an interrupted placement. No real-world occlusion, terrain mesh fitting, location access, analytics, or network service is implemented.

## Asset preparation and visual reference

The source contains 14,987 triangles, 11 material primitives, and 30 embedded JPEG textures. The converter bakes the supplied node transform once, subtracts the reviewed corner, then rotates 180° about Y. It does not resize the house. USD uses Y up and `metersPerUnit = 1`.

Review elevations and diagonal geometry views in `docs/model-review/`. The entrance facade faces source -Z. When viewed from there, source +X is screen-left. Conversion rotates 180° about Y, so native +X is facade-right, +Z front and -Z rear. This right-handed native convention differs from the earlier provisional web convention. A matching vertex in the first-floor wall primitive supports the selected side-wing foundation reference at source-world coordinates approximately `(10.657180, 2.751341, -3.515790)` metres. The overall bounds start at `(-4.574090, 2.751341, -7.801472)` and include gutter/roof protrusions; that bounding corner is not the selected feature. Some geometry consequently has negative normalized X or Z coordinates, as it should.

`docs/model-review/front-reference.png` marks the selected corner. `public/models/ios/house2story-metadata.json` records reference, dimensions, and source/asset hashes. See `docs/MODEL-REFERENCE.md` for review evidence and limitations. Visual geometry review does not certify architectural survey accuracy or substitute for checking the textured house on an iPhone.

## Implementation phases

1. **Native asset and prototype:** preserve web, prepare USDZ, add Xcode project, preview and placement controls, and compile an unsigned device build. Geometry review establishes the selected facade/corner; physical-device materials, orientation, and UX still need review.
2. **Personal-device trial:** use free Personal Team signing on the iPhone 13 Pro Max. Verify house load, life-size dimensions, corner, touch controls, camera denial, interruption recovery, and thermal/memory performance. Start on textured pavement in shade with short walks.
3. **Outdoor feasibility gate:** separately measure initial error, scale agreement, and drift at 10′, 25′, 50′, and 100′. Cover grass/pavement, sun/shade, camera turns, return to origin, and tracking loss. Independent measured references are required for validation, although visitors use no printed target. Record results in `docs/AR-TEST-CHECKLIST.md`.
4. **Refinement and catalog:** only after the gate, refine coarse/fine controls, footprint/translucency modes, onboarding, and performance. Add the two forthcoming color variants with independently reviewed origins. Catalog replacement must preserve placement, retain the current model on failure, load on demand, and release unused entities/resources.
5. **Distribution and Android decision:** select a distribution route and budget after feasibility. Free personal testing does not provide public visitor distribution. Evaluate ARCore for Android with separate device/outdoor trials rather than claiming feature parity from shared placement math.

## Acceptance gate

- Native app installs and renders the real asset on the tested iPhone.
- User confirms the entrance facade and selected front-left side-wing foundation corner; no bounding-box corner substitution.
- Proportions and approximately life-size dimensions agree with independent measurements.
- Rotation, movement, elevation, lock/unlock, place again, and preview recovery work in portrait and landscape.
- Camera denial, unsupported AR, backgrounding, interrupted tracking, and loading errors remain recoverable.
- Repeated sessions do not accumulate session anchors or unused scenes.
- Outdoor trials quantify placement error and drift on walks up to 100′.
- Only describe approximately one-foot alignment as supported after representative results meet the target; otherwise document limits and revise placement/calibration, distance, or scope.

## Remaining decisions

Confirm the side-wing foundation corner is the intended architectural reference; obtain the two colored variants; determine whether the nominal dimensions include steps and overhangs; select a field location and independent measurements; assess outdoor tracking; then choose visitor distribution and an Android test device.

Official references: [ARKit world tracking](https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration), [raycast targets](https://developer.apple.com/documentation/arkit/arraycastquery/target-swift.enum), and [Apple membership comparison / Personal Team limits](https://developer.apple.com/support/compare-memberships/).
