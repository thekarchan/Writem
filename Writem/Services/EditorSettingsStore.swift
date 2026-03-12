import Combine
import Foundation
import SwiftUI

enum EditorTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum ICloudSyncStatus: Equatable {
    case checking
    case available(URL?)
    case unavailable(String)

    var title: String {
        switch self {
        case .checking:
            return "Checking iCloud"
        case .available:
            return "iCloud Available"
        case .unavailable:
            return "iCloud Unavailable"
        }
    }

    var message: String {
        switch self {
        case .checking:
            return "Checking iCloud Drive and key-value sync availability."
        case .available(let url):
            if let url {
                return "Settings can sync through iCloud. Documents saved in iCloud Drive will sync across devices. Container: \(url.path)"
            }
            return "Settings can sync through iCloud. Documents saved in iCloud Drive will sync across devices."
        case .unavailable(let reason):
            return reason
        }
    }
}

@MainActor
final class EditorSettingsStore: ObservableObject {
    @Published var lineWidthPreset: LineWidthPreset
    @Published var preferredTheme: EditorTheme
    @Published var showToolbar: Bool
    @Published var autoThemeEnabled: Bool
    @Published var showCodeLineNumbers: Bool
    @Published var iCloudConfigSyncEnabled: Bool
    @Published private(set) var iCloudStatus: ICloudSyncStatus = .checking

    private let defaults: UserDefaults
    private let cloudStore: NSUbiquitousKeyValueStore
    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingExternalChange = false

    private enum Key {
        static let lineWidthPreset = "editor.lineWidthPreset"
        static let preferredTheme = "editor.preferredTheme"
        static let showToolbar = "editor.showToolbar"
        static let autoThemeEnabled = "editor.autoThemeEnabled"
        static let showCodeLineNumbers = "editor.showCodeLineNumbers"
        static let iCloudConfigSyncEnabled = "editor.iCloudConfigSyncEnabled"
    }

    init(
        defaults: UserDefaults = .standard,
        cloudStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        self.lineWidthPreset = LineWidthPreset(rawValue: defaults.string(forKey: Key.lineWidthPreset) ?? "") ?? .comfortable
        self.preferredTheme = EditorTheme(rawValue: defaults.string(forKey: Key.preferredTheme) ?? "") ?? .light
        self.showToolbar = defaults.object(forKey: Key.showToolbar) as? Bool ?? false
        self.autoThemeEnabled = defaults.object(forKey: Key.autoThemeEnabled) as? Bool ?? true
        self.showCodeLineNumbers = defaults.object(forKey: Key.showCodeLineNumbers) as? Bool ?? true
        self.iCloudConfigSyncEnabled = defaults.object(forKey: Key.iCloudConfigSyncEnabled) as? Bool ?? true

        cloudStore.synchronize()
        applyCloudValuesIfNeeded()
        bindChanges()
        refreshICloudStatus()

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.applyCloudValuesIfNeeded()
            }
        }
    }

    func refreshICloudStatus() {
        iCloudStatus = .checking

        DispatchQueue.global(qos: .utility).async {
            let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            let status: ICloudSyncStatus

            if let containerURL {
                status = .available(containerURL)
            } else {
                status = .unavailable("Enable the iCloud capability for this app in Signing & Capabilities to sync settings. Documents can also sync when opened from iCloud Drive.")
            }

            DispatchQueue.main.async {
                self.iCloudStatus = status
            }
        }
    }

    var resolvedColorScheme: ColorScheme? {
        guard !autoThemeEnabled else {
            return nil
        }

        switch preferredTheme {
        case .dark:
            return .dark
        case .light, .system:
            return .light
        }
    }

    private func bindChanges() {
        $lineWidthPreset
            .dropFirst()
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)

        $preferredTheme
            .dropFirst()
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)

        $showToolbar
            .dropFirst()
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)

        $autoThemeEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)

        $showCodeLineNumbers
            .dropFirst()
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)

        $iCloudConfigSyncEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.defaults.set(self?.iCloudConfigSyncEnabled, forKey: Key.iCloudConfigSyncEnabled)
                self?.persist()
                self?.refreshICloudStatus()
            }
            .store(in: &cancellables)
    }

    private func persist() {
        guard !isApplyingExternalChange else {
            return
        }

        defaults.set(lineWidthPreset.rawValue, forKey: Key.lineWidthPreset)
        defaults.set(preferredTheme.rawValue, forKey: Key.preferredTheme)
        defaults.set(showToolbar, forKey: Key.showToolbar)
        defaults.set(autoThemeEnabled, forKey: Key.autoThemeEnabled)
        defaults.set(showCodeLineNumbers, forKey: Key.showCodeLineNumbers)
        defaults.set(iCloudConfigSyncEnabled, forKey: Key.iCloudConfigSyncEnabled)

        guard iCloudConfigSyncEnabled else {
            return
        }

        cloudStore.set(lineWidthPreset.rawValue, forKey: Key.lineWidthPreset)
        cloudStore.set(preferredTheme.rawValue, forKey: Key.preferredTheme)
        cloudStore.set(showToolbar, forKey: Key.showToolbar)
        cloudStore.set(autoThemeEnabled, forKey: Key.autoThemeEnabled)
        cloudStore.set(showCodeLineNumbers, forKey: Key.showCodeLineNumbers)
        cloudStore.set(iCloudConfigSyncEnabled, forKey: Key.iCloudConfigSyncEnabled)
        cloudStore.synchronize()
    }

    private func applyCloudValuesIfNeeded() {
        guard iCloudConfigSyncEnabled else {
            return
        }

        isApplyingExternalChange = true
        defer { isApplyingExternalChange = false }

        if let raw = cloudStore.string(forKey: Key.lineWidthPreset),
           let preset = LineWidthPreset(rawValue: raw) {
            lineWidthPreset = preset
        }

        if let raw = cloudStore.string(forKey: Key.preferredTheme),
           let theme = EditorTheme(rawValue: raw) {
            preferredTheme = theme
        }

        if cloudStore.object(forKey: Key.showToolbar) != nil {
            showToolbar = cloudStore.bool(forKey: Key.showToolbar)
        }

        if cloudStore.object(forKey: Key.autoThemeEnabled) != nil {
            autoThemeEnabled = cloudStore.bool(forKey: Key.autoThemeEnabled)
        }

        if cloudStore.object(forKey: Key.showCodeLineNumbers) != nil {
            showCodeLineNumbers = cloudStore.bool(forKey: Key.showCodeLineNumbers)
        }
    }
}
