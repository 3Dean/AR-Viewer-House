# AR prototype device and outdoor trial

## Active prototype: native iPhone

The Swift/ARKit/RealityKit app is in `ios/`. The web baseline at `5174008` is preserved; Zappar commercial deployment is deferred because of cost. Use `ios/README.md` for free Personal Team signing. Installation/signing needs Xcode on macOS. A build or native asset loader check does not establish outdoor accuracy.

### Local checks

- [x] Unsigned iOS device-SDK build passes: Xcode 26.3, iPhoneOS 26.2 SDK, iOS 17 deployment target.
- [x] RealityKit macOS loader confirms USDZ dimensions; SceneKit native textured render reviewed; source SHA matches both unchanged GLBs.
- [x] Root `npm test` (3 checks) and `npm run build` pass for the preserved web prototype.
- [x] Native placement-math checks pass for metric steps, rotated directions, elevation and corner pivot.
- The user supplied a corrected GLB and red-arrow corner reference. Corrected native rendering identifies the balcony/garage facade and the marked front-bay foundation vertex. See `MODEL-REFERENCE.md`. Physical-device visual confirmation remains required.

### Physical iPhone checks — formal checklist pending

On October 9, 2026, the user reported successful outdoor use at approximately 50′ to the street. Device/iOS, lighting, surface and independent error measurements were not supplied; this report does not establish one-foot accuracy or 100′ performance. That trial used the earlier asset, whose facade was subsequently reported reversed. The corrected asset needs a fresh phone/field check.

- [ ] Install on iPhone 13 Pro Max with Personal Team signing; record iOS and app revision.
- [ ] Orbit the 3D preview. Check texture orientation, glass, normals, materials, ground and overall shape against the source.
- [ ] Rebuild with the corrected USDZ. Confirm initial placement shows the balcony/garage facade (garage on right), and the green pin matches the red-arrow front-bay corner beside the downspout. Rotation must pivot at that point.
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

### AR photo capture — physical checks pending

- [ ] With the house placed, tap Capture; confirm Photos contains the camera background and house at the framing shown in the viewer, without app text/buttons.
- [ ] Test unlocked/locked placement, portrait/landscape, and visible/hidden guides. Capture should work while locked and include guides only when visible.
- [ ] First save requests only add-photo permission. Grant it and confirm success feedback; saving another frame should not ask again.
- [ ] Deny add-photo permission: confirm recoverable feedback, retained image, Settings link and Retry saving photo. After enabling access, retry should save the original captured frame, even if AR was reset while opening Settings.
- [ ] The Photos permission prompt should not itself reset placement. Actually backgrounding, or an AR session interruption, must still reset placement safely.
- [ ] Tap rapidly: only one capture/save should be in flight. Test interrupted capture and save failures; retry should remain available on failure.

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
| 2026-10-09 / revision not confirmed | Not recorded | Not recorded | User-reported outdoor use to street; working well | Not measured | Not measured | ≈50 | Not measured | Not measured | 100′ trial pending |

Ground slope fitting, real-world occlusion, geographic anchoring, shared/persistent placement and Android are not supported in this prototype. Free personal testing is not public visitor distribution.

## Preserved web checks (historical)

The earlier local work reported strict TypeScript/build and ground-estimation tests passing, GLB preview loading, emitted Zappar WASM/worker requests, and camera-denial recovery. Re-run web checks when changing that implementation. Its phone-height/flat-plane scale estimate and bounding corner remain provisional. Web physical trials still need HTTPS and appropriate Zappar domain/licensing access; they are separate from the active native feasibility gate.
