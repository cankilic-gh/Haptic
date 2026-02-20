import Foundation

/// PresetManager - Handles persistence of MetronomePresets via UserDefaults
/// Provides CRUD operations for user-created presets with automatic sync
final class PresetManager: ObservableObject {

    // MARK: - Singleton
    static let shared = PresetManager()

    // MARK: - Published State
    @Published private(set) var userPresets: [MetronomePreset] = []

    // MARK: - Storage Keys
    private enum StorageKeys {
        static let userPresets = "haptic.userPresets"
        static let lastUsedPresetId = "haptic.lastUsedPresetId"
    }

    // MARK: - Factory Presets (read-only)
    let factoryPresets: [MetronomePreset] = [
        .progMetal,
        .djent,
        .waltz
    ]

    // MARK: - Initialization

    private init() {
        loadPresets()
    }

    // MARK: - CRUD Operations

    /// Save a new preset or update existing one
    func save(_ preset: MetronomePreset) {
        var updatedPreset = preset
        updatedPreset.updatedAt = Date()

        if let index = userPresets.firstIndex(where: { $0.id == preset.id }) {
            userPresets[index] = updatedPreset
        } else {
            userPresets.append(updatedPreset)
        }

        persistPresets()
    }

    /// Create a new preset from current metronome state
    func createPreset(
        name: String,
        bpm: Int,
        timeSignature: TimeSignature,
        accentPattern: [Bool],
        subdivisionEnabled: Bool = false,
        subdivisionType: SubdivisionType = .eighth
    ) -> MetronomePreset {
        let preset = MetronomePreset(
            name: name,
            bpm: bpm,
            timeSignature: timeSignature,
            accentPattern: accentPattern,
            subdivisionEnabled: subdivisionEnabled,
            subdivisionType: subdivisionType
        )
        save(preset)
        return preset
    }

    /// Delete a preset by ID
    func delete(_ presetId: UUID) {
        userPresets.removeAll { $0.id == presetId }
        persistPresets()
    }

    /// Delete a preset
    func delete(_ preset: MetronomePreset) {
        delete(preset.id)
    }

    /// Get all presets (factory + user)
    var allPresets: [MetronomePreset] {
        factoryPresets + userPresets
    }

    /// Find preset by ID
    func preset(withId id: UUID) -> MetronomePreset? {
        allPresets.first { $0.id == id }
    }

    // MARK: - Last Used Preset

    /// Save last used preset ID for quick recall
    func setLastUsed(_ preset: MetronomePreset) {
        UserDefaults.standard.set(preset.id.uuidString, forKey: StorageKeys.lastUsedPresetId)
    }

    /// Get last used preset
    var lastUsedPreset: MetronomePreset? {
        guard let idString = UserDefaults.standard.string(forKey: StorageKeys.lastUsedPresetId),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return preset(withId: id)
    }

    // MARK: - Persistence

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.userPresets) else {
            userPresets = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userPresets = try decoder.decode([MetronomePreset].self, from: data)
        } catch {
            print("PresetManager: Failed to decode presets: \(error)")
            userPresets = []
        }
    }

    private func persistPresets() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(userPresets)
            UserDefaults.standard.set(data, forKey: StorageKeys.userPresets)
        } catch {
            print("PresetManager: Failed to encode presets: \(error)")
        }
    }

    // MARK: - Export/Import

    /// Export all user presets as JSON data
    func exportPresets() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(userPresets)
        } catch {
            print("PresetManager: Export failed: \(error)")
            return nil
        }
    }

    /// Import presets from JSON data
    func importPresets(from data: Data, replaceExisting: Bool = false) -> Int {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedPresets = try decoder.decode([MetronomePreset].self, from: data)

            if replaceExisting {
                userPresets = importedPresets
            } else {
                // Merge, avoiding duplicates by ID
                for preset in importedPresets {
                    if !userPresets.contains(where: { $0.id == preset.id }) {
                        userPresets.append(preset)
                    }
                }
            }

            persistPresets()
            return importedPresets.count
        } catch {
            print("PresetManager: Import failed: \(error)")
            return 0
        }
    }

    // MARK: - Reset

    /// Clear all user presets
    func clearAllUserPresets() {
        userPresets = []
        UserDefaults.standard.removeObject(forKey: StorageKeys.userPresets)
        UserDefaults.standard.removeObject(forKey: StorageKeys.lastUsedPresetId)
    }
}
