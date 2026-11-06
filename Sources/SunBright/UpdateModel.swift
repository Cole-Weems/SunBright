import Combine
import Foundation
import Sparkle

struct UpdateConfiguration {
    let unavailableReason: String?

    init(bundle: Bundle = .main) {
        self.init(
            bundleURL: bundle.bundleURL,
            feedURL: bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            publicKey: bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        )
    }

    init(bundleURL: URL, feedURL: String?, publicKey: String?) {
        if bundleURL.pathExtension != "app" {
            unavailableReason = "In-app updates require SunBright.app. Move the app to Applications and open that copy."
        } else if let feedURL, let url = URL(string: feedURL),
                  url.scheme == "https", url.host != nil, url.user == nil, url.password == nil,
                  let publicKey, Data(base64Encoded: publicKey)?.count == 32 {
            unavailableReason = nil
        } else {
            unavailableReason = "In-app updates are not available in this build. Download the latest app from GitHub Releases."
        }
    }
}

@MainActor
protocol AppUpdateService: AnyObject {
    var canCheckForUpdates: AnyPublisher<Bool, Never> { get }
    var willInstallUpdate: (() -> Void)? { get set }
    func start() throws
    func checkForUpdates()
}

@MainActor
private final class SparkleUpdateService: NSObject, AppUpdateService, SPUUpdaterDelegate {
    var willInstallUpdate: (() -> Void)?
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil
    )

    var canCheckForUpdates: AnyPublisher<Bool, Never> {
        controller.updater.publisher(for: \.canCheckForUpdates).eraseToAnyPublisher()
    }

    func start() throws { try controller.updater.start() }
    func checkForUpdates() { controller.checkForUpdates(nil) }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        willInstallUpdate?()
    }
}

/// Sparkle owns version comparison, prompts, signature verification, installation,
/// and relaunch. This model only exposes the manual action and its availability.
@MainActor
final class UpdateModel: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var errorMessage: String?
    let configuration: UpdateConfiguration
    var willInstallUpdate: (() -> Void)?
    private let makeService: () -> any AppUpdateService
    private var service: (any AppUpdateService)?
    private var subscription: AnyCancellable?
    private var started = false

    init(
        configuration: UpdateConfiguration = UpdateConfiguration(),
        makeService: (() -> any AppUpdateService)? = nil
    ) {
        self.configuration = configuration
        self.makeService = makeService ?? { SparkleUpdateService() }
    }

    func start() {
        guard !started, configuration.unavailableReason == nil else { return }
        let service = service ?? makeService()
        self.service = service
        service.willInstallUpdate = { [weak self] in self?.willInstallUpdate?() }
        do {
            try service.start()
            started = true
            errorMessage = nil
            subscription = service.canCheckForUpdates.sink { [weak self] in
                self?.canCheckForUpdates = $0
            }
        } catch {
            canCheckForUpdates = false
            errorMessage = "The updater could not start. Quit and reopen SunBright, or download the latest app from GitHub Releases."
        }
    }

    func checkForUpdates() {
        guard started, canCheckForUpdates else { return }
        service?.checkForUpdates()
    }
}
