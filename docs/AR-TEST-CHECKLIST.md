# AR prototype device and outdoor trial

## Active prototype: native iPhone

The Swift/ARKit/RealityKit app is in `ios/`. The web baseline at `5174008` is preserved; Zappar commercial deployment is deferred because of cost. Use `ios/README.md` for free Personal Team signing. Installation/signing needs Xcode on macOS. A build or native asset loader check does not establish outdoor accuracy.

### Local checks

- [x] Unsigned iOS device-SDK build passes: Xcode 26.3, iPhoneOS 26.2 SDK, iOS 17 deployment target.
- [x] RealityKit macOS loader confirms USDZ dimensions; SceneKit native textured render reviewed; source SHA matches both unchanged GLBs.
- [x] Root `npm test` (3 checks) and `npm run build` pass for the preserved web prototype.
- [x] Native placement-math checks pass for metric steps, rotated directions, elevation and corner pivot.
- Geometry-only review identified the -Z entrance facade and front-left side-wing foundation ground vertex. See `MODEL-REFERENCE.md`. Physical-device visual confirmation remains required.

### Physical iPhone checks — not yet completed

- [ ] Install on iPhone 13 Pro Max with Personal Team signing; record iOS and app revision.
- [ ] Orbit the 3D preview. Check texture orientation, glass, normals, materials, ground and overall shape against the source.
- [ ] Confirm green reference is the front-left outer side-wing foundation corner, not the roof/gutter bounding corner or right-side entry steps; confirm owner agrees with that reference.
- [ ] Verify independent overall dimensions. Nominal 50′ × 45′ × 27′; source bounds ≈50.19′ × 45.17′ × 27.23′. No arbitrary scaling.
- [ ] Start AR, grant camera access, scan textured nearby ground. No printed target and no phone-height entry.
- [ ] Place on detected horizontal ground within 8 m. Taps without a detected surface or normal tracking should not place; visitors must distinguish ground from tables/raised surfaces.
- [ ] Initial facade faces the visitor. Rotation pivots at the pin; house-relative movement changes by 1′; elevation changes by 3″. Check signs and displayed values.
- [ ] Lock prevents taps, rotation, movement, elevation, and Place again; tracking continues. Unlock and place again work.
- [ ] Check portrait/landscape, safe areas, outdoor readability, VoiceOver labels, control reachability, frame rate, thermal load and memory over repeated sessions.
- [ ] Deny camera permission: preview remains usable; Settings link and retry recover after permission is granted.
- [ ] Exit AR stops camera. Background/foreground, phone call and forced session interruption return to preview and require a new placement.
- [ ] Cover the camera or face a featureless area: limited tracking is visible and editing is disabled; no quantified accuracy claim follows from “normal.”
- [ ] Unsupported AR device/simulator retains real-model 3D preview.
- [ ] Remove/rename bundled asset in a temporary test build: useful load error and retry. Do not commit the intentionally broken asset.

### Outdoor accuracy gate

Use independent temporary tape-measured ground references for evaluation; these are measurement tools, not a printed tracking target in the visitor experience. Keep the virtual corner/reference definition consistent with the measured real-world reference.

- [ ] Measure initial horizontal corner error and heading error before walking.
- [ ] Independently check metric scale against known house dimensions/footprint references; log separately from corner error.
- [ ] Walk progressively to 10′, 25′, 50′ and 100′ (30.48 m). At each distance, measure observed alignment error using fixed references; turn the camera and return to the corner.
- [ ] Repeat independent placements/sessions on pavement and grass, in shade and bright sun. Record slope and feature quality.
- [ ] Record return-to-origin drift, tracking losses, recovery, and any anchor jumps separately from initial placement error.
- [ ] Accept approximately one-foot alignment only if representative trials demonstrate ≤0.3048 m error under the intended conditions. Otherwise document achieved distance/tolerance and revise approach.

| Date / app revision | iPhone / iOS | Surface / slope / light | Trial | Initial error m / heading ° | Scale error | Distance ft | Error at distance m | Return drift m | Tracking / performance notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Not run | | | | | | | | | |

Ground slope fitting, real-world occlusion, geographic anchoring, shared/persistent placement and Android are not supported in this prototype. Free personal testing is not public visitor distribution.

## Preserved web checks (historical)

The earlier local work reported strict TypeScript/build and ground-estimation tests passing, GLB preview loading, emitted Zappar WASM/worker requests, and camera-denial recovery. Re-run web checks when changing that implementation. Its phone-height/flat-plane scale estimate and bounding corner remain provisional. Web physical trials still need HTTPS and appropriate Zappar domain/licensing access; they are separate from the active native feasibility gate.
