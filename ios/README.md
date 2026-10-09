# Native iPhone field prototype

Open `HouseOnSite.xcodeproj` in Xcode on a Mac. The project targets iOS 17+ on iPhone and bundles `../public/models/ios/house2story.usdz`; keep that relative repository layout. No Zappar SDK, paid AR SDK, or package installation is needed.

## Free personal-device testing

1. In Xcode Settings → Accounts, sign in with your Apple Account.
2. Select target HouseOnSite → Signing & Capabilities. Select your Personal Team and change `com.example.HouseOnSite` to a unique bundle identifier. Leave automatic signing enabled. The repository intentionally contains no team ID.
3. Connect and trust the iPhone. Enable Developer Mode on the phone when prompted, then choose it as the run destination and Run.
4. Allow camera access when tapping Start AR. Scan textured nearby ground. Tap a detected horizontal surface within 8 m, then align the green corner, adjust, and lock.
5. If denied, use Open camera settings or continue in 3D. Backgrounding/interruption resets AR placement.

Free Personal Team testing is for personal devices and has provisioning limits, including seven-day expiry; re-run from Xcode when provisioning expires. It is not TestFlight or public distribution. See [Apple's membership comparison](https://developer.apple.com/support/compare-memberships/). Windows cannot build/sign this iOS app locally; retain Windows for source editing and the web prototype.

## Behavior

The USDZ has metre units and a baked front-left **side-wing foundation** ground origin; +X right, -Z rear, +Z front. See `../docs/MODEL-REFERENCE.md`. The selected corner is on the recessed side-wing foundation, behind the central facade. Rotation stays around that reference. Movement buttons change one foot along the current house axes; elevation changes three inches (bounded from −5′ to +10′). Scaling is fixed. Initial facade orientation faces the visitor.

Lock blocks placement taps and transform edits while tracking continues. Guides remain a display option. Raycasts require normal tracking and detected horizontal geometry; visitors must choose ground rather than another horizontal surface. No printed marker or phone-height estimate is used. Each visitor independently establishes a new temporary session.

The 3D fallback uses the actual USDZ and drag-to-orbit. AR requires physical hardware; simulator preview does not establish tracking accuracy. Unavailable AR, denied camera, interruptions, and errors retain preview/restart paths. Only one supplied house exists; catalog, footprint/translucency modes, occlusion, terrain fitting, geographic/persistent/shared anchors, and Android are future work.

## Build and preparation

Unsigned compilation (not phone installation):

```sh
xcodebuild -project ios/HouseOnSite.xcodeproj -scheme HouseOnSite \
  -sdk iphoneos -configuration Debug -derivedDataPath /tmp/house-ios-build \
  CODE_SIGNING_ALLOWED=NO build
```

Rebuild the specific source asset on macOS with Python 3 + Pillow and Apple's `usdcat`/`usdzip`:

```sh
python3 ios/tools/prepare_house.py --convert
```

Conversion intermediates are ignored under `public/models/ios/conversion/`. Commit the USDZ and metadata. Never overwrite the original GLB. `ios/tools/create_project.py` reproduces the minimal project; avoid regenerating after personal signing changes unless you intend to reset them.

Optional macOS native loader/render check:

```sh
swiftc -module-cache-path /tmp/house-swift-cache ios/tools/review_asset.swift -o /tmp/house-review
/tmp/house-review "$PWD"
```

Run the root `npm run build` to verify the preserved web app after source changes. Follow `../docs/AR-TEST-CHECKLIST.md` on the physical phone before making scale, outdoor, or one-foot accuracy claims.

Placement math check (on macOS):

```sh
swiftc -module-cache-path /tmp/house-swift-cache ios/HouseOnSite/Placement.swift ios/tests/main.swift -o /tmp/house-placement-tests
/tmp/house-placement-tests
```

Local validation on October 8, 2026: Xcode 26.3 unsigned iPhone build succeeded; RealityKit macOS loaded the USDZ at the expected bounds; native SceneKit textured render reviewed; placement checks and web tests/build passed. No physical-phone or outdoor trial has been performed.
