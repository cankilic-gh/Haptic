import Foundation
import HealthKit
import Combine

/// WorkoutSessionManager - Background Persistence Engine for watchOS
/// Uses HKWorkoutSession to keep the app alive and haptics running
/// even when the wrist is lowered or screen turns off.
///
/// This is the KEY to uninterrupted metronome performance on Apple Watch.

final class WorkoutSessionManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var sessionState: HKWorkoutSessionState = .notStarted
    @Published private(set) var error: WorkoutError?

    // MARK: - HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // MARK: - Configuration
    private let workoutConfiguration: HKWorkoutConfiguration = {
        let config = HKWorkoutConfiguration()
        // Using .mindAndBody keeps the session lightweight
        // while still maintaining background execution rights
        config.activityType = .mindAndBody
        config.locationType = .indoor
        return config
    }()

    // MARK: - Error Types
    enum WorkoutError: LocalizedError {
        case healthKitNotAvailable
        case authorizationDenied
        case sessionCreationFailed(Error)
        case sessionStartFailed(Error)
        case alreadyRunning
        case notRunning

        var errorDescription: String? {
            switch self {
            case .healthKitNotAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            case .sessionCreationFailed(let error):
                return "Failed to create workout session: \(error.localizedDescription)"
            case .sessionStartFailed(let error):
                return "Failed to start workout session: \(error.localizedDescription)"
            case .alreadyRunning:
                return "A workout session is already running"
            case .notRunning:
                return "No workout session is currently running"
            }
        }
    }

    // MARK: - Initialization
    override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Request HealthKit authorization for workout sessions
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WorkoutError.healthKitNotAvailable
        }

        // We only need workout type - no actual health data reading/writing
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = []

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    // MARK: - Session Management

    /// Start a workout session for background execution
    /// This MUST be called before starting the metronome on watchOS
    func startSession() async throws {
        guard !isSessionActive else {
            throw WorkoutError.alreadyRunning
        }

        do {
            // Create the workout session
            let session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: workoutConfiguration
            )

            // Create the workout builder for the session
            let builder = session.associatedWorkoutBuilder()

            // Set delegates
            session.delegate = self
            builder.delegate = self

            // Configure builder data source
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: workoutConfiguration
            )

            // Store references
            self.workoutSession = session
            self.workoutBuilder = builder

            // Start the session
            session.startActivity(with: Date())

            // Begin data collection (required for the session to persist)
            try await builder.beginCollection(at: Date())

            await MainActor.run {
                self.isSessionActive = true
                self.error = nil
            }

        } catch {
            await MainActor.run {
                self.error = .sessionCreationFailed(error)
            }
            throw WorkoutError.sessionCreationFailed(error)
        }
    }

    /// Stop the workout session
    func stopSession() async throws {
        guard isSessionActive, let session = workoutSession, let builder = workoutBuilder else {
            throw WorkoutError.notRunning
        }

        // End the workout session
        session.end()

        // End data collection
        try await builder.endCollection(at: Date())

        // Finish the workout (discard it - we don't need to save metronome "workouts")
        try await builder.finishWorkout()

        await MainActor.run {
            self.isSessionActive = false
            self.workoutSession = nil
            self.workoutBuilder = nil
        }
    }

    /// Pause the workout session (maintains background rights but pauses tracking)
    func pauseSession() {
        workoutSession?.pause()
    }

    /// Resume a paused workout session
    func resumeSession() {
        workoutSession?.resume()
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutSessionManager: HKWorkoutSessionDelegate {

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async {
            self.sessionState = toState

            switch toState {
            case .running:
                self.isSessionActive = true
            case .ended, .stopped:
                self.isSessionActive = false
            default:
                break
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.error = .sessionStartFailed(error)
            self.isSessionActive = false
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        // We don't need to process any health data
        // This delegate method is required but can be empty
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // We don't process workout events
    }
}
