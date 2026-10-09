# AR prototype device trial

## Verified locally

- Strict TypeScript and production build pass.
- Ground-estimation tests pass for downward/angled rays, invalid heights, near-horizontal rays, and excessive distances.
- Production preview loads the GLB and enables Start AR.
- Starting AR requests the emitted Zappar WebAssembly and worker resources.
- Denied/unavailable camera access returns to the 3D preview with recovery instructions.

## Physical device checks still required

Use an HTTPS URL and confirm Zappar domain/licensing requirements first. Test on iPhone Safari and Android Chrome. The local LAN HTTP URL cannot provide normal phone camera access.

1. Confirm facade orientation and the green pin's architectural front-left corner. Current bounding-box normalization remains provisional.
2. Enter phone camera height above ground in feet, start AR, and accept camera/motion access.
3. Briefly scan textured surroundings, then aim down and tap nearby ground. A horizon tap should be rejected with guidance.
4. Check the pin stays on estimated ground and the house remains upright. Check portrait and landscape.
5. Try footprint view, rotation, house-relative movement, elevation, lock/unlock, place again, and exit.
6. Lock the house, walk gradually away, turn the camera, and return. Start with short distances before a 100-foot trial.
7. Deny permissions, hide/restore the page, and repeat AR startup. Check the camera stops and new placement is required.
8. Add the two later exports and test replacement without losing the anchor or adjustment values.

Run `npm test` for placement math and `npm run build` before a trial. Record device/browser, phone-height estimate, ground slope, lighting, initial scale/alignment error, walking distance, and observed drift. Independent measured references are needed to establish one-foot accuracy. Current placement does not account for terrain slope or real-world occlusion.
