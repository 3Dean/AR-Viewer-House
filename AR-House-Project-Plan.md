# Outdoor AR House Viewer — Project Plan

## Objective

Build a browser-based experience that lets visitors place a life-size house on a lot and walk toward the street to view it. Each visitor establishes placement for their own session by tapping the camera view. No printed marker or app installation is required.

The initial targets are iPhone Safari and Android Chrome on supported devices. Provide an ordinary interactive 3D viewer when AR is unavailable.

## Agreed requirements

- Initial source model: `house2story.glb`. Plan for three selectable test houses; the user will supply differently colored GLB exports. Later entries may have different designs and dimensions.
- Intended overall dimensions: approximately 50 feet wide × 45 feet deep × 27 feet high.
- Placement origin: front-left corner at ground level, as viewed while facing the house's front.
- Placement controls: position, rotation around the vertical axis, and foundation elevation.
- Walking distance: up to 100 feet (30.48 meters) from the origin.
- Desired alignment error: approximately one foot (0.3048 meters).
- Each visitor places the house independently; shared or persistent physical anchors are outside the first version.
- No measured calibration distance is currently available.
- Ground slope and foundation elevation are unknown.

## Technical approach

Use TypeScript, Three.js, Zappar Universal AR, and Vite. Develop in VS Code on Windows and test on physical phones. Serve the experience over HTTPS for camera access. Confirm Zappar licensing and hosting requirements before public deployment.

Keep tracking integration behind a small interface so a different tracking provider can be evaluated if the outdoor trial fails. Keep model preparation and placement controls independent of the tracking provider.

### Important feasibility constraint

A screen tap selects an image location but does not, by itself, measure its physical distance from the camera. Zappar's documented Instant World Tracking API uses a camera-relative anchor offset, and that offset affects anchor scale. Accurate metric placement therefore needs an explicit initialization strategy; do not assume a ground hit-test or metric world scale is available until verified against the SDK.

For the first experiment, ask the visitor for approximate phone height above the ground and use device orientation plus an assumed horizontal ground plane to estimate the placement point. Reject placement when the viewing ray is close to horizontal, where the estimate becomes unstable. This is an approximation and must be tested on the actual phones and site.

One-foot accuracy over a 100-foot walk is a target, not an established capability. The feasibility trial is a gate before further product development.

Reference: https://docs.zap.works/universal-ar/threejs/tracking/instant-world-tracking/

## Model inspection and preparation

The initial structural inspection found:

| Property | Result |
| --- | --- |
| File size | 7,381,344 bytes |
| Format | GLB 2.0, Blender export |
| Triangle count | 14,987 |
| Meshes / material primitives | 1 / 11 |
| Materials | 11 |
| Embedded images | 30 JPEGs |
| External resources / required extensions | None |
| Transformed bounds dimensions | X 15.2991, Y 8.3009, Z 13.7675 |

Assuming standard glTF meter units, those bounds correspond to approximately 50.19 feet wide, 27.23 feet high, and 45.17 feet deep. These are close to the agreed nominal dimensions. Preserve proportions; do not independently stretch axes to force nominal sizes.

The lowest geometry is at Y ≈ 2.7513, and the model is horizontally offset. Its exported origin is unsuitable for direct ground placement.

Preparation tasks:

1. Load the model in a desktop Three.js viewer and visually identify the front facade and left side. Bounding-box inspection alone does not establish the front direction.
2. Confirm that the lowest geometry is the appropriate foundation reference; steps or other protrusions may affect the bounding box.
3. Add a normalization wrapper that accounts for the existing node transform, moves the agreed ground reference to Y=0, and places the front-left reference at X=0, Z=0.
4. Define the canonical model axes: +Y up, +X from left to right across the facade, and +Z from the front toward the rear.
5. Keep tracking, user placement, and model normalization as separate transform groups. Rotate around the chosen corner rather than the model center.
6. Inspect texture dimensions, decoded memory, glass appearance, normals, and mobile rendering. Optimize textures and unnecessary double-sided materials only where the visual result supports it.
7. Preserve the original GLB; use a derived asset only if optimization is needed.

Inspection artifacts: `house2story-inspection.json` and `inspect_glb.py`.

## House catalog and export conventions

Start with three catalog entries, named House 1, House 2, and House 3 until final names are supplied. Use the current GLB as the first available entry. Add the other two when their exports arrive; do not present unavailable files as working choices. Distinct colors will make model selection and replacement easy to verify during testing.

For the three color variants, preserve the same geometry, scale, front direction, and origin across exports. Suggested filenames are `house-01.glb`, `house-02.glb`, and `house-03.glb`. Embed textures in each file. Keep color changes limited to intended materials so windows and other finishes remain recognizable.

Define a TypeScript catalog with a stable ID, display name, asset URL, thumbnail, nominal dimensions, and per-model normalization data (unit scale, front direction, and ground-level front-left reference). This lets future houses have different sizes without changing the placement interface. Inspect every supplied model rather than assuming its export transform matches the first house.

When switching houses, preserve the tracking anchor, placement rotation, horizontal adjustment, and elevation adjustment. Replace only the normalized model and its footprint. Align every model at its own front-left corner. Retain the current house if loading a replacement fails, and release unused model resources to limit mobile memory use. Load models on demand rather than downloading all three at startup.

## Interaction interface

Build a mobile-first interface from the initial prototype onward, with large touch targets, readable outdoor contrast, and controls clear of device safe areas. Support portrait use first and accommodate landscape layouts.

| Interface area | Controls and behavior |
| --- | --- |
| House selection | Three house cards with name, thumbnail/color cue, and dimensions; available houses open in a 3D preview; unavailable entries show Coming soon |
| 3D preview | Orbit inspection, selected house details, and a primary Place in AR button |
| AR setup | Short instructions, camera access, approximate phone-height input, and ground placement guidance |
| Placement | Pin, footprint, front arrow, and confirmation control |
| Adjustment panel | Rotate dial and fine buttons; move controls with clearly labeled house-relative directions; raise/lower foundation; displayed adjustment values |
| Viewing | Compact house picker, selected house name, solid/translucent/footprint display options, Adjust placement, and Place again |
| Feedback | Model loading progress, permission recovery, unsupported-device fallback, and recoverable load errors |

Keep adjustment controls in a collapsible bottom panel so the camera view remains useful. Model switching should work both before and after placement, including while placement is locked; switching must not restart tracking. Do not offer free model scaling in the normal interface because the houses are intended to remain life-size.

## Visitor flow

1. **Open:** show the house catalog, choose an available house, and preview it in 3D with model-loading progress.
2. **Start AR:** explain camera access and check browser/device support. Offer the 3D viewer if unavailable.
3. **Initialize:** request approximate phone height and guide a short scan of nearby surroundings.
4. **Place:** aim at nearby ground and tap to place a pin representing the front-left corner.
5. **Align:** show a transparent footprint and front-direction arrow. Provide rotation drag/dial, fine rotation buttons, horizontal adjustment, and foundation-height adjustment.
6. **Preview:** show the house while allowing a footprint-only or translucent view for alignment.
7. **Lock:** freeze user placement edits while continuing camera tracking.
8. **View:** allow walking and switching houses at the same origin, with visible controls for opacity, realignment, and restarting placement. Where the SDK exposes useful tracking status, show it without claiming unsupported confidence measurements.

Keep the house upright on a horizontal reference plane for version one. Foundation-height adjustment does not model sloping terrain. Real-world occlusion by trees, cars, and terrain is outside the initial scope.

## Implementation phases

### Phase 1 — Asset viewer and normalization

Create the Vite/TypeScript project, house catalog, and mobile selection/preview interface. Load the GLB with Three.js, add touch/desktop orbit controls, and verify its appearance and front-left ground reference. Add footprint and dimension helpers for development. Start with the available model and add the two supplied variants without blocking initial work.

**Deliverable:** a working desktop/mobile 3D viewer with correct model axes and placement origin.

### Phase 2 — Minimal AR feasibility prototype

Integrate Zappar camera and Instant World Tracking. Implement initialization, phone-height input, pin placement, footprint preview, rotation, position/elevation adjustment, lock, and reset through the mobile interface. Start with simple house bounds to isolate tracking behavior, then load the actual model. Support replacing the selected house while preserving placement and tracking.

**Deliverable:** an HTTPS phone-accessible prototype, ready for outdoor trials.

### Phase 3 — Outdoor validation gate

Test on the iPhone 13 Pro Max and at least one representative Android phone. Trials should cover textured pavement and grass, bright sun and shade, initial placement, movement toward the street, return to the origin, camera turns, and interrupted tracking.

For validation, arrange temporary measured ground references even though visitors will not use them in the normal flow. Without independent reference measurements, one-foot accuracy cannot be objectively confirmed. Record initial placement error and later drift separately, along with device, phone-height estimate, distance, and environmental conditions.

**Decision:** continue with Zappar if the workflow and measured results meet the agreed tolerance under representative conditions. Otherwise evaluate more suitable tracking/calibration options, introduce an optional measured reference, or revise the supported distance/accuracy. Do not hide scale error by allowing arbitrary house resizing.

### Phase 4 — Product interface and performance

Refine instructions, touch controls, loading/error states, accessible labels, and 3D fallback. Optimize model/texture delivery as justified by physical-device tests. Handle camera permission denial, unsupported browsers, session interruptions, and restart recovery.

**Deliverable:** a usable browser experience with documented supported devices and tested limitations.

### Phase 5 — Deployment and handoff

Select HTTPS hosting, confirm SDK production licensing, deploy the reviewed build, and provide a shareable URL. Document setup, model replacement, placement assumptions, and outdoor test results. Publishing details will be selected once hosting and licensing are known.

## Acceptance criteria

- The model loads and renders correctly on tested iPhone and Android devices.
- All three supplied test houses can be selected and visually distinguished; unavailable entries are clearly identified until delivered.
- Switching houses preserves the front-left anchor and user placement settings, updates the footprint, and handles load failures without losing the current house.
- Selection, 3D preview, placement, adjustment, and viewing controls work with touch on phone screens.
- The pin represents the verified front-left ground reference.
- House proportions and nominal life-size dimensions remain consistent.
- Visitors can adjust rotation, horizontal position, and foundation height, then lock and reset placement.
- The page provides a usable 3D fallback and clear permission/error recovery.
- Representative outdoor trials quantify initial alignment, scale error, and drift over walks up to 100 feet.
- Approximately one-foot alignment is demonstrated before describing it as a supported capability. If not achieved, the limitation and revised approach are explicitly documented.

## Remaining decisions

- Verify the model's front facade and exact foundation/corner reference visually.
- Receive the two additional colored GLB exports and verify consistent transforms for the test variants.
- Confirm whether nominal dimensions include roof overhangs and steps.
- Obtain Zappar development/production access and determine hosting.
- Identify an Android test device and an outdoor test location.
- Decide whether approximate phone-height entry is acceptable after trying the prototype.

## Immediate next step

Build the asset viewer and minimal tracking prototype, then validate outdoor placement before expanding the interface. No backend, geographic anchoring, multi-user synchronization, or persistent physical placement is needed for this first version.
