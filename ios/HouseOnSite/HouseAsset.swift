import Combine
import RealityKit

/// Asset ownership stays independent of AR tracking. Replacement failure retains the last entity.
@MainActor
final class HouseAsset: ObservableObject {
    // Details belong to this supplied model, not to the app or a fixed-size catalog.
    let displayName = "The Madison"
    let dimensionSummary = "≈ 50′ wide × 45′ deep × 27′ high"
    @Published private(set) var entity: Entity?
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    private var request: AnyCancellable?

    func load() {
        guard !loading else { return }
        loading = true
        error = nil
        request = Entity.loadAsync(named: "house2story.usdz").sink(
            receiveCompletion: { [weak self] result in
                guard let self else { return }
                self.loading = false
                if case .failure(let failure) = result {
                    self.error = "House could not load: \(failure.localizedDescription)"
                }
            },
            receiveValue: { [weak self] entity in self?.entity = entity }
        )
    }
}
