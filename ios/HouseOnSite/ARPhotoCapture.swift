import Combine
import Photos
import RealityKit
import UIKit

struct PhotoCaptureNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    var offerSettings = false
}

/// Snapshots the rendered AR camera/model composite; Photos access is add-only.
@MainActor
final class ARPhotoCapture: ObservableObject {
    @Published private(set) var busy = false
    @Published private(set) var permissionPromptActive = false
    @Published private(set) var hasUnsavedPhoto = false
    @Published var notice: PhotoCaptureNotice?
    private var retainedImage: UIImage?

    func capture(view: ARView?) {
        guard !busy else { return }
        guard let view, view.cameraMode == .ar, view.session.currentFrame != nil else {
            notice = PhotoCaptureNotice(title: "Capture unavailable", message: "Start AR and place the house before capturing a photo.")
            return
        }
        busy = true
        // Capture first so a permission prompt cannot change the requested composition.
        view.snapshot(saveToHDR: false) { [weak self] image in
            Task { @MainActor in
                guard let self else { return }
                guard let image else {
                    self.busy = false
                    self.notice = PhotoCaptureNotice(title: "Could not capture", message: "The AR view did not return an image. Try again while the house is visible.")
                    return
                }
                self.retainedImage = image
                self.hasUnsavedPhoto = true
                await self.saveRetainedPhoto()
            }
        }
    }

    func retrySave() {
        guard !busy, retainedImage != nil else { return }
        busy = true
        Task { await saveRetainedPhoto() }
    }

    private func saveRetainedPhoto() async {
        defer { busy = false }
        guard let image = retainedImage else { return }
        var authorization = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if authorization == .notDetermined {
            permissionPromptActive = true
            authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            permissionPromptActive = false
        }
        guard authorization == .authorized || authorization == .limited else {
            notice = PhotoCaptureNotice(
                title: "Photo not saved",
                message: authorization == .restricted
                    ? "This device restricts saving to Photos. Your captured image is kept for retry while the app stays open."
                    : "Allow adding photos in Settings, then tap Retry saving photo. Your captured image is kept while the app stays open.",
                offerSettings: authorization == .denied
            )
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            retainedImage = nil
            hasUnsavedPhoto = false
            notice = PhotoCaptureNotice(title: "Photo saved", message: "Your AR view of the house was saved to Photos.")
        } catch {
            notice = PhotoCaptureNotice(title: "Photo not saved", message: "\(error.localizedDescription) Tap Retry saving photo to save the captured image again.")
        }
    }
}
