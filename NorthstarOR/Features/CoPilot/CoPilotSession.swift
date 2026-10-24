import Foundation
import Observation

/// State machine for one procedure on the iPad co-pilot.
/// Prompts and documents only. It never makes clinical decisions.
@Observable
final class CoPilotSession {
    let procedure: Procedure
    private(set) var statuses: [String: StepStatus]
    private(set) var currentIndex: Int = 0
    private(set) var log: [LogEntry] = []
    /// Set when a required step was skipped and the team hasn't acknowledged it yet.
    private(set) var pendingAlert: ProcedureStep?
    private(set) var reducedSupport: Bool
    let startedAt: Date

    init(procedure: Procedure, reducedSupport: Bool = false, now: Date = .now) {
        self.procedure = procedure
        self.reducedSupport = reducedSupport
        self.startedAt = now
        var s: [String: StepStatus] = [:]
        for (i, step) in procedure.steps.enumerated() { s[step.id] = i == 0 ? .current : .upcoming }
        self.statuses = s
    }

    var currentStep: ProcedureStep? {
        procedure.steps.indices.contains(currentIndex) ? procedure.steps[currentIndex] : nil
    }
    var isFinished: Bool { currentStep == nil }

    func status(of step: ProcedureStep) -> StepStatus { statuses[step.id] ?? .upcoming }

    func completeCurrentStep(at time: Date = .now) {
        guard let step = currentStep else { return }
        statuses[step.id] = .completed
        log.append(LogEntry(.stepCompleted, "\(step.title) complete", at: time))
        advance()
    }

    func skipCurrentStep(at time: Date = .now) {
        guard let step = currentStep else { return }
        statuses[step.id] = .skipped
        log.append(LogEntry(.stepSkipped, "\(step.title) skipped", at: time))
        if step.isRequired {
            pendingAlert = step
            log.append(LogEntry(.alert, "Required step skipped: \(step.title). Confirm to continue.", at: time))
        }
        advance()
    }

    /// Team confirms they saw the skipped-step alert.
    func acknowledgeAlert(at time: Date = .now) {
        guard let step = pendingAlert else { return }
        log.append(LogEntry(.note, "Team acknowledged skipped step: \(step.title)", at: time))
        pendingAlert = nil
    }

    /// Flipped by the planner's storm flag (via SyncService) or by hand.
    func setReducedSupport(_ on: Bool, at time: Date = .now) {
        guard on != reducedSupport else { return }
        reducedSupport = on
        log.append(LogEntry(.modeChange, on ? "Reduced-support mode on" : "Reduced-support mode off", at: time))
    }

    /// Message pushed from the remote rep via the Remote Support Link.
    func receiveRemoteMessage(_ text: String, from name: String, at time: Date = .now) {
        log.append(LogEntry(.remoteMessage, "\(name): \(text)", at: time))
    }

    private func advance() {
        currentIndex += 1
        if let next = currentStep { statuses[next.id] = .current }
    }
}
