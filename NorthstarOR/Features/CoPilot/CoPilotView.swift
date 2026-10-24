import SwiftUI

/// iPad co-pilot, landscape: step list | current step | live log.
/// Starter layout only. The co-pilot lane owns the polish (see docs/TASKS.md).
struct CoPilotView: View {
    @Environment(AppModel.self) private var model
    @State private var announcer = VoiceAnnouncer()

    var body: some View {
        let session = model.activeSession
        VStack(spacing: 0) {
            topBar(session)
            HStack(alignment: .top, spacing: Northstar.Space.s6) {
                stepList(session).frame(width: 300)
                currentStep(session).frame(maxWidth: .infinity)
                logPanel(session).frame(width: 320)
            }
            .padding(Northstar.Space.s6)
        }
        .background(Northstar.Palette.bgBase)
        .overlay {
            if session.pendingAlert != nil {
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(Northstar.Palette.amber, lineWidth: 10)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    private func topBar(_ session: CoPilotSession) -> some View {
        HStack(spacing: Northstar.Space.s4) {
            Image("BrandMark").resizable().scaledToFit().frame(height: 28)
            Text(session.procedure.name).font(Northstar.Fonts.title)
            Spacer()
            if session.reducedSupport {
                Label("Reduced-support mode", systemImage: "snowflake")
                    .font(Northstar.Fonts.label)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Northstar.Palette.amberSoft, in: Capsule())
                    .foregroundStyle(Northstar.Palette.amber)
            }
            TimelineView(.periodic(from: session.startedAt, by: 1)) { ctx in
                Text(Duration.seconds(ctx.date.timeIntervalSince(session.startedAt)).formatted(.time(pattern: .minuteSecond)))
                    .font(Northstar.Fonts.timer)
            }
        }
        .foregroundStyle(Northstar.Palette.ink)
        .padding(.horizontal, Northstar.Space.s6).padding(.vertical, Northstar.Space.s4)
        .background(Northstar.Palette.bgRaised)
    }

    private func stepList(_ session: CoPilotSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s3) {
                ForEach(Array(session.procedure.steps.enumerated()), id: \.element.id) { index, step in
                    let status = session.status(of: step)
                    HStack(spacing: Northstar.Space.s3) {
                        Image(systemName: icon(for: status))
                            .foregroundStyle(color(for: status))
                        Text("\(index + 1). \(step.title)")
                            .font(status == .current ? Northstar.Fonts.bodyStrong : Northstar.Fonts.body)
                            .foregroundStyle(status == .completed ? Northstar.Palette.inkMuted : Northstar.Palette.ink)
                    }
                    .padding(Northstar.Space.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(status == .current ? Northstar.Palette.auroraSoft : .clear,
                                in: RoundedRectangle(cornerRadius: Northstar.Radius.sm))
                }
            }
        }
    }

    private func currentStep(_ session: CoPilotSession) -> some View {
        VStack(spacing: Northstar.Space.s6) {
            if let alert = session.pendingAlert {
                VStack(spacing: Northstar.Space.s3) {
                    Label("\(alert.title) was skipped", systemImage: "exclamationmark.triangle.fill")
                        .font(Northstar.Fonts.title).foregroundStyle(Northstar.Palette.amber)
                    Button("Confirm and continue") { session.acknowledgeAlert() }
                        .buttonStyle(NorthstarPrimaryButtonStyle())
                }
            } else if let step = session.currentStep {
                Text(step.title).font(Northstar.Fonts.display).foregroundStyle(Northstar.Palette.ink)
                    .multilineTextAlignment(.center)
                Text(step.detail).font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                if step.normallyCoveredByRep && session.reducedSupport {
                    Label("Normally covered by the device rep", systemImage: "person.badge.clock")
                        .font(Northstar.Fonts.caption).foregroundStyle(Northstar.Palette.ice)
                }
                HStack(spacing: Northstar.Space.s4) {
                    Button("Skip") {
                        let skipped = step
                        session.skipCurrentStep()
                        if skipped.isRequired { announcer.say("\(skipped.title) was skipped. Confirm to continue.") }
                    }
                    .font(Northstar.Fonts.step)
                    .frame(minHeight: 72).padding(.horizontal, Northstar.Space.s6)
                    Button("Complete") { session.completeCurrentStep() }
                        .buttonStyle(NorthstarPrimaryButtonStyle())
                }
            } else {
                Label("Procedure complete", systemImage: "checkmark.seal.fill")
                    .font(Northstar.Fonts.display).foregroundStyle(Northstar.Palette.aurora)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func logPanel(_ session: CoPilotSession) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s2) {
            Text("LIVE LOG").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                    ForEach(session.log.reversed()) { entry in
                        Text("\(entry.timestamp.formatted(date: .omitted, time: .standard))  \(entry.message)")
                            .font(Northstar.Fonts.log)
                            .foregroundStyle(entry.kind == .alert ? Northstar.Palette.amber : Northstar.Palette.ink)
                    }
                }
            }
        }
        .padding(Northstar.Space.s4)
        .background(Northstar.Palette.bgSunken, in: RoundedRectangle(cornerRadius: Northstar.Radius.md))
    }

    private func icon(for status: StepStatus) -> String {
        switch status {
        case .completed: "checkmark.circle.fill"
        case .skipped: "exclamationmark.triangle.fill"
        case .current: "circle.inset.filled"
        case .upcoming: "circle"
        }
    }

    private func color(for status: StepStatus) -> Color {
        switch status {
        case .completed: Northstar.Palette.aurora
        case .skipped: Northstar.Palette.amber
        case .current: Northstar.Palette.starlight
        case .upcoming: Northstar.Palette.slate
        }
    }
}

#Preview(traits: .landscapeLeft) {
    CoPilotView().environment(AppModel())
}
