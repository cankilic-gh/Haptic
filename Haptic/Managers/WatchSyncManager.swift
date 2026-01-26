import Foundation
import WatchConnectivity
import Combine

/// WatchSyncManager - Real-time iPhone ↔ Watch Communication
/// Handles bidirectional sync of BPM, play state, time signatures, and accent patterns.
///
/// Uses WCSession for immediate message delivery and application context
/// for state persistence when the companion app isn't active.

final class WatchSyncManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = WatchSyncManager()

    // MARK: - Published State
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var activationState: WCSessionActivationState = .notActivated
    @Published private(set) var lastSyncTime: Date?

    // MARK: - Sync State
    @Published var syncedState: MetronomeState = .default

    // MARK: - Session
    private var session: WCSession?

    // MARK: - Callbacks
    var onStateReceived: ((MetronomeState) -> Void)?
    var onCommandReceived: ((MetronomeCommand) -> Void)?

    // MARK: - Message Keys
    private enum MessageKey {
        static let messageType = "type"
        static let bpm = "bpm"
        static let isPlaying = "isPlaying"
        static let timeSignatureBeats = "timeSignatureBeats"
        static let timeSignatureUnit = "timeSignatureUnit"
        static let accentPattern = "accentPattern"
        static let subdivisionEnabled = "subdivisionEnabled"
        static let subdivisionType = "subdivisionType"
        static let command = "command"
        static let timestamp = "timestamp"
    }

    private enum MessageType: String {
        case stateSync = "stateSync"
        case command = "command"
        case ping = "ping"
        case pong = "pong"
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("WatchSyncManager: WatchConnectivity not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Public API

    /// Send current metronome state to Watch
    func syncState(_ state: MetronomeState) {
        guard let session = session, session.activationState == .activated else {
            print("WatchSyncManager: Session not activated")
            return
        }

        let message = createStateMessage(state)

        // Use sendMessage for immediate delivery if reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("WatchSyncManager: Failed to send message: \(error)")
            }
        }

        // Also update application context for persistent sync
        do {
            try session.updateApplicationContext(message)
            syncedState = state
            lastSyncTime = Date()
        } catch {
            print("WatchSyncManager: Failed to update context: \(error)")
        }
    }

    /// Send a command to Watch (play, stop, etc.)
    func sendCommand(_ command: MetronomeCommand) {
        guard let session = session, session.isReachable else {
            print("WatchSyncManager: Cannot send command - not reachable")
            return
        }

        let message: [String: Any] = [
            MessageKey.messageType: MessageType.command.rawValue,
            MessageKey.command: command.rawValue,
            MessageKey.timestamp: Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("WatchSyncManager: Failed to send command: \(error)")
        }
    }

    /// Request current state from Watch
    func requestStateFromWatch() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            MessageKey.messageType: MessageType.ping.rawValue
        ]

        session.sendMessage(message, replyHandler: { [weak self] reply in
            if let state = self?.parseStateMessage(reply) {
                DispatchQueue.main.async {
                    self?.syncedState = state
                    self?.onStateReceived?(state)
                }
            }
        }, errorHandler: { error in
            print("WatchSyncManager: Ping failed: \(error)")
        })
    }

    // MARK: - Message Creation

    private func createStateMessage(_ state: MetronomeState) -> [String: Any] {
        return [
            MessageKey.messageType: MessageType.stateSync.rawValue,
            MessageKey.bpm: state.bpm,
            MessageKey.isPlaying: state.isPlaying,
            MessageKey.timeSignatureBeats: state.timeSignature.beatsPerBar,
            MessageKey.timeSignatureUnit: state.timeSignature.beatUnit,
            MessageKey.accentPattern: state.accentPattern,
            MessageKey.subdivisionEnabled: state.subdivisionEnabled,
            MessageKey.subdivisionType: state.subdivisionType.rawValue,
            MessageKey.timestamp: Date().timeIntervalSince1970
        ]
    }

    // MARK: - Message Parsing

    private func parseStateMessage(_ message: [String: Any]) -> MetronomeState? {
        guard
            let bpm = message[MessageKey.bpm] as? Int,
            let isPlaying = message[MessageKey.isPlaying] as? Bool,
            let tsBeats = message[MessageKey.timeSignatureBeats] as? Int,
            let tsUnit = message[MessageKey.timeSignatureUnit] as? Int,
            let accentPattern = message[MessageKey.accentPattern] as? [Bool]
        else {
            return nil
        }

        let subdivisionEnabled = message[MessageKey.subdivisionEnabled] as? Bool ?? false
        let subdivisionRaw = message[MessageKey.subdivisionType] as? Int ?? 2
        let subdivisionType = SubdivisionType(rawValue: subdivisionRaw) ?? .eighth

        return MetronomeState(
            bpm: bpm,
            isPlaying: isPlaying,
            timeSignature: TimeSignature(beatsPerBar: tsBeats, beatUnit: tsUnit),
            accentPattern: accentPattern,
            subdivisionEnabled: subdivisionEnabled,
            subdivisionType: subdivisionType
        )
    }

    private func parseCommand(_ message: [String: Any]) -> MetronomeCommand? {
        guard let commandRaw = message[MessageKey.command] as? String else {
            return nil
        }
        return MetronomeCommand(rawValue: commandRaw)
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.activationState = activationState

            #if os(iOS)
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif

            self.isReachable = session.isReachable
        }

        if let error = error {
            print("WatchSyncManager: Activation error: \(error)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session for watchOS 6.0+
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // MARK: - Receiving Messages

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleMessage(message, replyHandler: nil)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleMessage(message, replyHandler: replyHandler)
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        handleMessage(applicationContext, replyHandler: nil)
    }

    private func handleMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let typeRaw = message[MessageKey.messageType] as? String,
              let type = MessageType(rawValue: typeRaw) else {
            return
        }

        switch type {
        case .stateSync:
            if let state = parseStateMessage(message) {
                DispatchQueue.main.async {
                    self.syncedState = state
                    self.lastSyncTime = Date()
                    self.onStateReceived?(state)
                }
            }

        case .command:
            if let command = parseCommand(message) {
                DispatchQueue.main.async {
                    self.onCommandReceived?(command)
                }
            }

        case .ping:
            // Reply with current state
            let response = createStateMessage(syncedState)
            replyHandler?(response)

        case .pong:
            break
        }
    }
}

// MARK: - Supporting Types

/// Represents the complete metronome state for sync
struct MetronomeState: Equatable, Codable {
    var bpm: Int
    var isPlaying: Bool
    var timeSignature: TimeSignature
    var accentPattern: [Bool]
    var subdivisionEnabled: Bool
    var subdivisionType: SubdivisionType

    static let `default` = MetronomeState(
        bpm: 120,
        isPlaying: false,
        timeSignature: .common,
        accentPattern: [true, false, false, false],
        subdivisionEnabled: false,
        subdivisionType: .eighth
    )
}

/// Commands that can be sent between devices
enum MetronomeCommand: String, Codable {
    case play
    case stop
    case toggle
    case incrementBPM
    case decrementBPM
    case resetToDefaults
}
