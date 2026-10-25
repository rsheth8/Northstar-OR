import Foundation
import Observation

/// One recognition window owns one immutable recording target. Never retarget a preview.
@Observable final class VoiceCommandRouter {
    private(set) var pending: SessionCommand?
    private(set) var heard: String?
    private var consumed = Set<UUID>()

    func receive(id: UUID, transcript: String, isFinal: Bool, captured: SessionCommand?) {
        guard isFinal, consumed.insert(id).inserted else { return }
        heard = transcript
        guard let intent = VoiceCommand.parse(transcript), let captured else { return }
        let action: SessionCommandAction
        switch intent {
        case .complete: action = .recordConfirmation
        case .skip: action = .deferItem
        case .confirm:
            guard case .acknowledgeWarning = captured.action else { return }
            action = captured.action
        }
        // While acknowledgment is pinned, only its explicit phrase is eligible.
        if case .acknowledgeWarning = captured.action, intent != .confirm { return }
        pending = SessionCommand(id: captured.id, identity: captured.identity, actor: captured.actor,
            source: .voice, issuedAt: captured.issuedAt, expectedVersion: captured.expectedVersion,
            targetItemID: captured.targetItemID, action: action)
    }

    func take() -> SessionCommand? {
        defer { pending = nil }
        return pending
    }

    func invalidate() { pending = nil; heard = nil }
}
