# Project conventions

- Read `README.md` and `AR-House-Project-Plan.md` before changing application scope.
- Use TypeScript strict mode and keep tracking-provider integration separate from model loading and placement controls.
- Preserve original supplied GLBs. Put runtime copies or derived assets in `public/models/`.
- Every model uses a verified front-left ground reference and retains life-size proportions. Do not assume a bounding-box corner is the architectural corner.
- Do not present unimplemented tracking, estimated scale, or unverified outdoor accuracy as supported behavior.
- Load catalog assets on demand, retain the current model on replacement failure, and dispose unused GPU resources.
- Treat camera permission denial and unsupported devices as normal recoverable states; retain a 3D fallback.
- Avoid secrets in client code or Vite environment variables.
- Run `npm run build` after source changes. Physical-phone and outdoor checks are required for AR claims; build success does not establish tracking accuracy.
