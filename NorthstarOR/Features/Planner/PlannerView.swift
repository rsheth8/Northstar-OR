import SwiftUI

/// Planner dashboard: upcoming procedures ranked by storm risk, with Coverage Matcher options.
/// Starter layout only. The planner lane adds the Minnesota map (MapKit) and polish.
struct PlannerView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: Procedure.ID?

    var body: some View {
        let recs = model.procedures
            .map { model.recommendation(for: $0) }
            .sorted { $0.risk > $1.risk }

        NavigationSplitView {
            List(recs, id: \.procedure.id, selection: $selectedID) { rec in
                HStack {
                    Circle().fill(color(rec.risk)).frame(width: 12, height: 12)
                    VStack(alignment: .leading) {
                        Text(rec.procedure.name).font(Northstar.Fonts.bodyStrong)
                        Text(model.hospital(rec.procedure.hospitalID)?.town ?? "")
                            .font(Northstar.Fonts.caption).foregroundStyle(Northstar.Palette.inkMuted)
                    }
                    Spacer()
                    Text(rec.risk.rawValue.capitalized).font(Northstar.Fonts.label).foregroundStyle(color(rec.risk))
                }
            }
            .navigationTitle("Planner")
        } detail: {
            if let rec = recs.first(where: { $0.procedure.id == selectedID }) {
                detail(rec)
            } else {
                ContentUnavailableView("Pick a procedure", systemImage: "cloud.snow")
            }
        }
    }

    private func detail(_ rec: CoverageMatcher.Recommendation) -> some View {
        List {
            Section("Why") {
                ForEach(rec.reasons, id: \.self) { Text($0) }
            }
            Section("Coverage options (ranked for review)") {
                ForEach(Array(rec.options.enumerated()), id: \.offset) { _, option in
                    Text(option.title)
                }
            }
            Section {
                Button(rec.reducedSupport ? "Send to co-pilot: reduced-support mode ON"
                                          : "Send to co-pilot: reduced-support mode OFF") {
                    model.sync.send(.reducedSupportChanged(procedureID: rec.procedure.id, on: rec.reducedSupport))
                }
            }
        }
        .navigationTitle(rec.procedure.name)
    }

    private func color(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: Northstar.Palette.aurora
        case .elevated: Northstar.Palette.amber
        case .high: Northstar.Palette.alert
        }
    }
}
