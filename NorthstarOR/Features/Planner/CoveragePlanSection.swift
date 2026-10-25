import SwiftUI

struct CoveragePlanSection: View {
    @Environment(AppModel.self) private var model
    let procedure: Procedure
    let options: [CoverageMatcher.Option]
    @State private var replacement: Proposed?
    @State private var error: String?

    private struct Proposed {
        let mode: CoveragePlan.Mode
        let recipientID: String?
        let expectedRevision: Int?
    }
    private var current: CoveragePlan? { model.coveragePlan(for: procedure.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s4) {
            Text("Coordinator support plan").font(Northstar.Fonts.title).accessibilityAddTraits(.isHeader)
            if let current {
                CoveragePlanSummary(plan: current)
                if current.delivery == .failed || current.delivery == .waitingForPeer {
                    Button("Retry current request") {
                        do { try model.retryCoverage(planID: current.id, revision: current.revision); error = nil }
                        catch { self.error = error.localizedDescription }
                    }.buttonStyle(NorthstarSecondaryButtonStyle())
                }
            } else {
                Text("No plan requested. Choose one option; other contacts remain unrequested.")
                    .font(Northstar.Fonts.body)
            }
            if let current {
                let history = model.coveragePlans.filter { $0.workspaceID == current.workspaceID && $0.id == current.id && $0.revision < current.revision }.sorted { $0.revision > $1.revision }
                if !history.isEmpty {
                    DisclosureGroup("Previous revisions (superseded)") {
                        ForEach(history, id: \.recordID) { plan in CoveragePlanSummary(plan: plan); Divider() }
                    }
                }
            }
            if let error { NorthstarBanner(tone: .failure, title: "Plan action not completed", message: error) }
            Text("Options for coordinator review").font(Northstar.Fonts.bodyStrong)
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let proposed = proposal(option)
                let isCurrent = current?.mode == proposed.mode && current?.recipient?.id == proposed.recipientID
                VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                    Text(option.title).font(Northstar.Fonts.bodyStrong)
                    Text(isCurrent ? "Current plan" : "Not requested")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    if model.demoPost == .room {
                        Button(proposed.mode == .reschedule ? "Record reschedule intention" : "Request \(proposed.mode == .remote ? "remote" : "in-person") support") {
                            if current == nil { submit(proposed) } else { replacement = proposed }
                        }
                        .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
                        .disabled(isCurrent && current?.response?.accepted != false)
                        .accessibilityIdentifier("coverage-request-\(proposed.mode.rawValue)-\(proposed.recipientID ?? "none")")
                    }
                }
                Divider()
            }
            if model.demoPost != .room { Text("Coverage plans are requested on the room device.").font(Northstar.Fonts.supporting) }
            Text("Availability, plan response, message receipt and call connection are separate. Rescheduling records an intention; it changes no external booking.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
        .alert("Replace the current support plan?", isPresented: Binding(get: { replacement != nil }, set: { if !$0 { replacement = nil } }), presenting: replacement) { proposed in
            Button("Replace plan") { submit(proposed); replacement = nil }
            Button("Keep current plan", role: .cancel) { replacement = nil }
        } message: { _ in Text("The previous revision stays in history. A late response to it cannot accept the replacement.") }
    }

    private func proposal(_ option: CoverageMatcher.Option) -> Proposed {
        switch option {
        case .inPersonRep(let rep, _): Proposed(mode: .inPerson, recipientID: rep.id, expectedRevision: current?.revision)
        case .remoteRep(let rep): Proposed(mode: .remote, recipientID: rep.id, expectedRevision: current?.revision)
        case .reschedule: Proposed(mode: .reschedule, recipientID: nil, expectedRevision: current?.revision)
        }
    }
    private func submit(_ proposed: Proposed) {
        do {
            _ = try model.requestCoverage(caseID: procedure.id, mode: proposed.mode,
                recipientID: proposed.recipientID, expectedRevision: proposed.expectedRevision)
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

struct CoveragePlanSummary: View {
    let plan: CoveragePlan
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s2) {
            Text("\(plan.modeLabel) · Revision \(plan.revision)").font(Northstar.Fonts.bodyStrong)
                .accessibilityIdentifier("coverage-current-revision")
            if let recipient = plan.recipient {
                Text("Requested contact: \(recipient.name) · Technical rep")
            }
            Text("Requested by \(plan.requester.displayName)")
            Text("Requested: \(plan.requestedAt.formatted(.iso8601)) · UTC").font(Northstar.Fonts.supporting)
            NorthstarStatusLabel(plan.statusLabel, tone: plan.response?.accepted == true ? .success : .info)
            Label("Request: \(plan.delivery.label)", systemImage: plan.delivery == .failed ? "exclamationmark.triangle" : "envelope")
                .font(Northstar.Fonts.supporting)
            if let response = plan.response {
                Text("Responding device participant: \(response.actor.displayName) · stated technical rep")
                Text("Response: \(response.delivery.label)").font(Northstar.Fonts.supporting)
            }
            Text("A listed contact is distinct from the connected device participant. Local roles do not verify identity.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
    }
}
