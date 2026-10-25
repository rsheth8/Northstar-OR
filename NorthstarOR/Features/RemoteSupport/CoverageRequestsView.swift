import SwiftUI

struct CoverageRequestsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    if let error { NorthstarBanner(tone: .failure, title: "Response action not completed", message: error) }
                    if model.incomingCoveragePlans.isEmpty {
                        ContentUnavailableView("No coverage requests received", systemImage: "envelope",
                            description: Text("Connect the room and rep devices. The coordinator requests a named support option from Planner."))
                    }
                    ForEach(model.incomingCoveragePlans, id: \.recordID) { plan in
                        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
                            Text("\(plan.caseReference) · \(plan.siteName)").font(Northstar.Fonts.title)
                            Text(plan.caseName).font(Northstar.Fonts.bodyStrong)
                            CoveragePlanSummary(plan: plan)
                            if plan.mode != .reschedule, plan.response == nil, model.demoPost == .rep {
                                Button("Accept \(plan.modeLabel.lowercased())") { respond(plan, accepted: true) }
                                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                                    .accessibilityIdentifier("coverage-accept-\(plan.recordID)")
                                Button("Decline request") { respond(plan, accepted: false) }
                                    .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
                            }
                            if let response = plan.response, response.delivery != .receivedByPeer, model.demoPost == .rep {
                                Button("Retry same response") {
                                    do { try model.retryCoverage(planID: plan.id, revision: plan.revision, response: true); error = nil }
                                    catch { self.error = error.localizedDescription }
                                }.buttonStyle(NorthstarSecondaryButtonStyle())
                            }
                        }
                        Divider()
                    }
                }.padding(Northstar.Space.s6)
            }
            .background(Northstar.Palette.bgRaised)
            .navigationTitle("Coverage requests").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
    private func respond(_ plan: CoveragePlan, accepted: Bool) {
        do { try model.respondToCoverage(planID: plan.id, revision: plan.revision, accepted: accepted); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
