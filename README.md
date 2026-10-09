# House on Site

Mobile-first outdoor house visualization prototype using TypeScript, Three.js, Vite, and a separate Zappar Universal AR adapter.

## Run locally

Use Node.js 22.12 or newer. Install dependencies with `npm install`, then run `npm run dev`. Open the address printed by Vite. Run `npm run build` for strict TypeScript checking and a production build; `npm run preview` serves the built files locally.

For reproducible installs after the lockfile is created, use `npm ci`. Commit `package-lock.json`. No credentials are required for the 3D preview.

## Current capabilities

- Interactive 3D preview of the supplied house, with touch/desktop orbit and zoom.
- Three-entry catalog: House 1 available; Houses 2 and 3 await supplied exports.
- Rotation and foundation-height controls, reset, and origin visualization.
- On-demand model loading, progress/error reporting, stale-load protection, and resource disposal.
- On-demand Zappar tracking adapter with experimental ground placement, phone-height input, movement, lock/unlock, and exit controls.

AR placement is available after the model loads. Enter approximate phone-camera height, start AR, aim down, and tap nearby ground. Adjust rotation, movement, and elevation, then lock. Phone height and flat-ground assumptions estimate scale; actual metric accuracy remains unverified. The model's front direction and foundation reference require visual confirmation; its current origin is a provisional bounding-box corner. See `docs/AR-TEST-CHECKLIST.md` for device trials.

## Project layout

- `src/catalog.ts`: model entries and normalization metadata.
- `src/model.ts`: GLB loading, provisional ground/corner normalization, and disposal.
- `src/main.ts`: preview scene and touch interface.
- `src/ar/zappar.ts`: isolated tracking-provider boundary.
- `src/style.css`: responsive presentation and touch controls.
- `public/models/`: deployed model assets; files here are publicly accessible.
- `house2story.glb`: original source retained unchanged.
- `AR-House-Project-Plan.md`: scope, phases, and field acceptance criteria.
- `house2story-inspection.json`: original structural inspection.

## Add the other houses

Place the GLBs under `public/models/`, then add their URLs to `src/catalog.ts`. Use `import.meta.env.BASE_URL` so paths respect deployments under a subdirectory. Set each entry's dimensions and verified front rotation. Until normalization is verified, leave `originVerified` false. Keep geometry, scale, and transforms identical for the initial color variants. Do not rename an unrelated model to overwrite the original source.

The intended axes after normalization are +Y up, +X left-to-right across the facade, and +Z front-to-back. Each house must share the semantic front-left ground reference, even when dimensions differ. A bounding-box corner may include steps or overhangs and requires review.

## AR integration requirements

Camera access on phones requires HTTPS (desktop localhost is a development exception). A LAN HTTP address is sufficient for previewing 3D but generally cannot start phone camera access. Use an approved HTTPS deployment or trusted local HTTPS setup for device trials.

Confirm Zappar production licensing and domain requirements before enabling a public AR build. Camera/motion permission requests use the SDK's permission interface for a user gesture. Camera processing stops when exiting AR. Vite emits the SDK's WebAssembly and worker assets; the local production browser check requested those resources successfully. Verify delivery again on the chosen HTTPS deployment.

The adapter provides camera updates and camera-relative anchoring, not a verified metric ground hit-test. Phone-height/orientation initialization rejects near-horizontal rays and estimated placement distances beyond eight meters. Validate scale and drift before presenting one-foot accuracy as supported. Hiding the page ends AR and requires new placement.

Official references:

- https://docs.zap.works/universal-ar/threejs/getting-started/installation/
- https://docs.zap.works/universal-ar/threejs/getting-started/camera-setup/
- https://docs.zap.works/universal-ar/threejs/tracking/instant-world-tracking/

## Checks before release

1. Run `npm run build`.
2. Preview on desktop and test touch interaction on iPhone Safari and Android Chrome.
3. Verify front facade, ground reference, proportions, and materials.
4. Test successful, failed, and repeated model selection once all exports are available.
5. Test camera denial, unsupported devices, session interruptions, and return to preview after AR is implemented.
6. Measure field placement error and drift on walks up to 100 feet using independent temporary references.

No backend, location permissions, persistent physical anchors, or analytics are included. Client-side configuration is public; never place secrets in Vite environment variables or deployed assets.
