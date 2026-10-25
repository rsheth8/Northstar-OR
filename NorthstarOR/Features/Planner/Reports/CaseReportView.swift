import SwiftUI

struct CaseReportView: View {
    let report: CaseReport
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                Label("Frozen record for review", systemImage: "doc.text").font(Northstar.Fonts.title)
                Text("Captured \(report.date(report.capturedAt)). Create a new report to include later changes.")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                ShareLink(item: report.text) {
                    Label("Share reviewed report", systemImage: "square.and.arrow.up")
                }.buttonStyle(NorthstarSecondaryButtonStyle())
                Text(report.text).font(Northstar.Fonts.body).textSelection(.enabled)
            }.padding(Northstar.Space.s6)
        }.navigationTitle("Case report").background(Northstar.Palette.bgRaised)
    }
}
