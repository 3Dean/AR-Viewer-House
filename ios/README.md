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

The USDZ has metre units and a baked user-marked front-left **front-bay foundation** ground origin; +X right, -Z rear, +Z front. See `../docs/MODEL-REFERENCE.md`. The selected corner is beside the front-bay downspout, left of the entry porch, as marked in the supplied reference. The corrected balcony/garage facade is the front. Rotation stays around that reference. Movement buttons change one foot along the current house axes; elevation changes three inches (bounded from −5′ to +10′). Scaling is fixed. Initial facade orientation faces the visitor.

Lock blocks placement taps and transform edits while tracking continues. Guides remain a display option. Raycasts require normal tracking and detected horizontal geometry; visitors must choose ground rather than another horizontal surface. No printed marker or phone-height estimate is used. Each visitor independently establishes a new temporary session.

The 3D fallback uses the actual USDZ and drag-to-orbit. AR requires physical hardware; simulator preview does not establish tracking accuracy. Unavailable AR, denied camera, interruptions, and errors retain preview/restart paths. Only one supplied house exists; catalog, footprint/translucency modes, occlusion, terrain fitting, geographic/persistent/shared anchors, and Android are future work.

## Auto lighting and House Brightness

In AR, expand **House controls** and use the **House brightness** slider. The default is **Auto / 100%**, with light estimation and automatic environment texturing enabled. Scan nearby surroundings briefly to give the camera-based environment lighting time to update.

The slider adjusts virtual-scene image-based lighting from 25% to 400% of the automatic baseline. Tap **Auto** to return to 100%. It does not change camera exposure, material colors or placement. The adjustment is available while placement is locked and does not restart the AR session. It persists across Place again and AR exit/re-entry within the open app; a fresh app launch defaults to Auto. The 3D preview keeps its separate inspection lighting. Captured AR photos include the current lighting adjustment.

This initial feature uses RealityKit's environment-light intensity adjustment, which also applies to lit virtual guides. It does not add a manually positioned sun, color-temperature controls or fixed-lighting mode. Matching direct sunlight across a house-sized asset still requires physical-phone testing; automatic environmental lighting is not a guarantee of photographic matching.

Implementation references: [automatic environment texturing](https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/environmenttexturing-swift.enum), [RealityKit environment probes](https://developer.apple.com/documentation/realitykit/arview/renderoptions-swift.struct/disablearenvironmentlighting), and [image-based light intensity](https://developer.apple.com/documentation/realitykit/arview/environment-swift.struct/imagebasedlight/intensityexponent).

## Capture an AR photo

After placing the house, tap **Capture** at the bottom-right of the AR viewer. The saved image contains the camera view and rendered house, including any visible corner/direction guides. Hide guides with the existing toggle if desired. The capture uses the viewer's current framing and resolution; app buttons and text are outside the captured ARView.

The first save asks for permission to add photos. The app requests add-only access and does not read your library. A success alert confirms the save to Photos. Repeated taps are disabled while capturing/saving. If permission or saving fails, the captured image stays in memory and **Retry saving photo** can save that same frame after recovery. A new capture replaces an unsaved image; closing the app discards it. Opening Settings backgrounds the app, so restarting AR requires placement again, but saving the retained photo does not.

The Photos permission prompt itself is exempt from the normal inactive-state reset; actually backgrounding or an AR session interruption still resets placement. Test permission, capture framing and saving on the physical phone.

## Build and preparation

Unsigned compilation (not phone installation):

```sh
xcodebuild -project ios/HouseOnSite.xcodeproj -scheme HouseOnSite \
  -sdk iphoneos -configuration Debug -derivedDataPath /tmp/house-ios-build \
  CODE_SIGNING_ALLOWED=NO build
```

The active source is `house2story-front-corrected.glb`. `ios/tools/house-reference.json` defines its exact marked corner and source-to-native axis mapping; do not reuse normalization metadata from the old export. Rebuild this source asset on macOS with Python 3 + Pillow and Apple's `usdcat`/`usdzip`:

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

Local validation on October 8, 2026: Xcode 26.3 unsigned iPhone build succeeded; RealityKit macOS loaded the USDZ at the expected bounds; native SceneKit textured render reviewed; placement checks and web tests/build passed. At that time no physical-phone or outdoor trial had been performed. On October 9 the user reported the prototype working outdoors at approximately 50′ to the street; measured error and the 100′ trial remain pending.

On October 9, 2026 the corrected source replaced the native runtime USDZ. The original GLBs and preserved web assets remain unchanged. The corrected native render and RealityKit bounds were reviewed locally; confirm initial facade direction and the marked pivot on the iPhone after rebuilding in Xcode.
