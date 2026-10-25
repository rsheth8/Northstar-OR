import SwiftUI

/// Browsing is local selection; only explicit commands can affect the recording.
struct PlannerView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: Procedure.ID?
    @State private var search = ""
    @State private var attentionOnly = false
    @State private var showingNewCase = false
    @State private var editingCase: Procedure?
    @State private var actionError: String?
    @State private var scope = PlannerScope()
    @State private var showingScope = false
    @State private var destination: PlannerDestination = .cases
    @State private var report: CaseReport?
    private enum PlannerDestination: String, CaseIterable, Identifiable {
        case cases = "Cases", coverage = "Coverage", weather = "Weather", reports = "Reports"
        var id: String { rawValue }
    }

    private var recommendations: [CoverageMatcher.Recommendation] {
        model.cases.sorted { ($0.scheduledAt, $0.id) < ($1.scheduledAt, $1.id) }
            .map { model.recommendation(for: $0) }
    }

    private var visible: [CoverageMatcher.Recommendation] {
        recommendations.filter { rec in
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = query.isEmpty || [rec.procedure.reference ?? rec.procedure.id,
                rec.procedure.name, model.hospital(rec.procedure.hospitalID)?.name ?? "",
                model.hospital(rec.procedure.hospitalID)?.town ?? ""]
                .contains { $0.localizedCaseInsensitiveContains(query) }
            let zone = model.hospital(rec.procedure.hospitalID)?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? TimeZone(secondsFromGMT: 0)!
            return matches && (!attentionOnly || rec.risk != .low) && scope.includes(rec.procedure, timeZone: zone, hasSession: model.session(for: rec.procedure.id) != nil, isActive: model.activeCaseID == rec.procedure.id)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                ForEach(visible, id: \.procedure.id) { rec in
                    caseRow(rec)
                        .tag(rec.procedure.id)
                        .accessibilityIdentifier("planner-case-\(rec.procedure.id)")
                        .listRowBackground(selectedID == rec.procedure.id
                            ? Northstar.Palette.Workspace.selection : Northstar.Palette.bgBase)
                }
            }
            .accessibilityIdentifier("planner-worklist")
            .safeAreaInset(edge: .top) {
                Text(scopeSummary).font(Northstar.Fonts.supporting)
                    .foregroundStyle(Northstar.Palette.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Northstar.Space.s3)
                    .background(Northstar.Palette.bgBase)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Northstar.Palette.bgBase)
            .searchable(text: $search, prompt: "Search cases or sites")
            .navigationTitle("Cases")
            .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 420)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.demoPost == .room {
                        Button("New case", systemImage: "plus") { showingNewCase = true }
                            .frame(minHeight: Northstar.Target.minimum).accessibilityIdentifier("planner-new-case")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Recording and date filters") { showingScope = true }
                        Toggle("Coverage needs attention", isOn: $attentionOnly)
                        Button("Show all cases") { attentionOnly = false; search = ""; scope = PlannerScope() }
                    } label: {
                        Label(attentionOnly ? "Needs attention" : "All cases", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter cases")
                }
            }
            .overlay {
                if visible.isEmpty {
                    ContentUnavailableView {
                        Label("No matching cases", systemImage: "calendar")
                    } description: {
                        Text(model.cases.isEmpty ? "No fictional cases are available in this workspace." : "Try another search or show all cases.")
                    } actions: {
                        if model.cases.isEmpty && model.demoPost == .room {
                            Button("Create fictional case") { showingNewCase = true }
                                .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        }
                        if !model.cases.isEmpty {
                            Button("Show all cases") { search = ""; attentionOnly = false; scope = PlannerScope() }
                                .buttonStyle(NorthstarSecondaryButtonStyle())
                        }
                    }
                }
            }
        } detail: {
            VStack(spacing: 0) {
                Picker("Planner destination", selection: $destination) {
                    ForEach(PlannerDestination.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).padding(Northstar.Space.s4)
                if destination == .coverage {
                    ScrollView {
                        CoverageMapView(procedures: visible.map(\.procedure), sites: model.hospitals, selectedID: $selectedID)
                            .padding(Northstar.Space.s6)
                    }
                } else if let rec = recommendations.first(where: { $0.procedure.id == selectedID }) {
                    switch destination {
                    case .cases: detail(rec)
                    case .weather: weather(rec.procedure)
                    case .reports: reportEntry(rec.procedure)
                    case .coverage: EmptyView()
                    }
                } else {
                ContentUnavailableView("Select a case", systemImage: "calendar",
                    description: Text("Browse coverage and logistical options. Selecting a case does not change the active recording."))
                    .background(Northstar.Palette.bgRaised)
                }
            }
        }
        .sheet(isPresented: $showingScope) {
            NavigationStack {
                Form {
                    Picker("Recording", selection: $scope.recording) {
                        ForEach(PlannerScope.Recording.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Filter by site-local day", isOn: Binding(get: { scope.day != nil }, set: { scope.day = $0 ? Calendar.current.dateComponents([.year, .month, .day], from: .now) : nil }))
                    if scope.day != nil {
                        DatePicker("Scheduled day", selection: Binding(get: { scope.day.flatMap { Calendar.current.date(from: $0) } ?? .now }, set: { scope.day = Calendar.current.dateComponents([.year, .month, .day], from: $0) }), displayedComponents: .date)
                    }
                    Text("The chosen calendar date is evaluated in each site's time zone. Browsing does not change the active recording.")
                }
                .navigationTitle("Case filters").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingScope = false } } }
            }
        }
        .sheet(item: $report) { CaseReportView(report: $0) }
        .sheet(isPresented: $showingNewCase) {
            if let workspace = model.workspace {
                CaseFormView(workspace: workspace, existingCases: model.cases) { input in
                    let saved = try model.saveCase(input); selectedID = saved.id
                }
            }
        }
        .sheet(item: $editingCase) { procedure in
            if let workspace = model.workspace {
                CaseFormView(workspace: workspace, existingCases: model.cases, editing: procedure) { input in _ = try model.saveCase(input) }
            }
        }
        .tint(Northstar.Palette.ice)
    }

    private func caseRow(_ rec: CoverageMatcher.Recommendation) -> some View {
        let procedure = rec.procedure
        return HStack(alignment: .top, spacing: Northstar.Space.s3) {
            Rectangle().fill(selectedID == procedure.id ? Northstar.Palette.ice : .clear)
                .frame(width: 3).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text(procedure.reference ?? procedure.id).font(Northstar.Fonts.bodyStrong)
                        Spacer()
                        Text(schedule(procedure, date: false)).font(Northstar.Fonts.supporting).monospacedDigit()
                    }
                    VStack(alignment: .leading) {
                        Text(procedure.reference ?? procedure.id).font(Northstar.Fonts.bodyStrong)
                        Text(schedule(procedure, date: false)).font(Northstar.Fonts.supporting).monospacedDigit()
                    }
                }
                Text(model.hospital(procedure.hospitalID)?.town ?? "Site not recorded")
                    .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                NorthstarStatusLabel("\(rec.risk.rawValue.capitalized) coverage risk", tone: riskTone(rec.risk))
                Label(recordingLabel(procedure), systemImage: model.activeCaseID == procedure.id ? "record.circle" : "doc.text")
                    .font(Northstar.Fonts.supporting)
                Text(schedule(procedure, date: true)).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }
            .padding(.vertical, Northstar.Space.s2)
        }
        .foregroundStyle(Northstar.Palette.ink)
        .frame(minHeight: Northstar.Target.primary)
        .accessibilityElement(children: .combine)
    }

    private func detail(_ rec: CoverageMatcher.Recommendation) -> some View {
        let procedure = rec.procedure
        let isActive = model.activeSession?.procedure.id == procedure.id
        return ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s6) {
                VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                    Text("Selected case").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
                    Text(procedure.reference ?? procedure.id).font(Northstar.Fonts.display)
                        .accessibilityAddTraits(.isHeader)
                    Text(procedure.name).font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                }
                VStack(alignment: .leading, spacing: Northstar.Space.s3) {
                    LabeledContent("Site", value: model.hospital(procedure.hospitalID)?.name ?? "Not recorded")
                    LabeledContent("Scheduled", value: schedule(procedure, date: true))
                    LabeledContent("Template", value: procedure.templateReference.map { "Coordination v\($0.version)" } ?? "Not recorded")
                    LabeledContent("Recording", value: isActive ? "Active on this device" : "Not active on this device")
                }
                .font(Northstar.Fonts.body)
                if model.demoPost == .room {
                    Button(isActive ? "Open Co-pilot" : model.session(for: procedure.id) == nil ? "Start recording" : "Resume recording") {
                        do {
                            _ = try model.startOrResume(caseID: procedure.id)
                            model.selectedDestination = .coPilot
                            actionError = nil
                        } catch { actionError = error.localizedDescription }
                    }
                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    .disabled(!FictionalCoordinationTemplate.template.supports(procedure))
                    .accessibilityIdentifier("planner-start-recording")
                    if !FictionalCoordinationTemplate.template.supports(procedure) {
                        NorthstarBanner(tone: .attention, title: "Recording unavailable", message: "This case does not have a supported coordination template. Its planning record remains available.")
                    }
                    Button("Edit case") { editingCase = procedure }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                    if let actionError { NorthstarBanner(tone: .failure, title: "Recording not opened", message: actionError) }
                }
                Divider()
                section("Coverage assessment") {
                    NorthstarStatusLabel("\(rec.risk.rawValue.capitalized) logistical risk", tone: riskTone(rec.risk))
                    ForEach(rec.reasons, id: \.self) { reason in
                        Text(reason).font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                    }
                    Text("Simulated inputs · Assessment does not select a support plan.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                }
                Divider()
                section("Support options") {
                    Text("Ranked for coordinator review · Not requested")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    ForEach(Array(rec.options.enumerated()), id: \.offset) { _, option in
                        optionRow(option)
                    }
                    if rec.options.isEmpty { Text("No eligible options recorded.") }
                }
                Divider()
                section("Recording support context") {
                    Text("Support-plan requests and acceptance are not available in this build. This action only updates the active recording’s reduced-support label.")
                        .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                    if isActive {
                        NorthstarStatusLabel(model.activeSession?.reducedSupport == true ? "Reduced-support context recorded" : "Standard support context recorded", tone: .neutral)
                        Button(rec.reducedSupport ? "Record reduced-support context" : "Record standard support context") {
                            model.sync.send(.reducedSupportChanged(procedureID: procedure.id, on: rec.reducedSupport))
                        }
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    } else {
                        Text("Browse freely. The active recording has not changed.")
                            .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    }
                }
            }
            .padding(Northstar.Space.s6)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Northstar.Palette.ink)
        .background(Northstar.Palette.bgRaised)
        .navigationTitle("Case details")
        .navigationBarTitleDisplayMode(.inline)
    }


    private var scopeSummary: String {
        let day = scope.day.flatMap { Calendar.current.date(from: $0) }.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "All dates"
        return "\(scope.recording.rawValue) · \(day)\(attentionOnly ? " · Needs coverage attention" : "")"
    }

    private func recordingLabel(_ procedure: Procedure) -> String {
        model.activeCaseID == procedure.id ? "Active recording" : model.session(for: procedure.id) != nil ? "Retained recording" : "Not started"
    }

    private func reportEntry(_ procedure: Procedure) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s4) {
            Text("Case record report").font(Northstar.Fonts.title)
            Text("Review a frozen summary of this case’s recorded items, corrections and support exchanges. Unrecorded information stays visible.")
            Button("Create report for review", systemImage: "doc.text") {
                let session = model.session(for: procedure.id)
                report = CaseReport(procedure: procedure, site: model.hospital(procedure.hospitalID), state: session?.recordingState, events: session?.events ?? [], questions: model.questions, notes: model.sessionNotes, forecast: model.planningEvidence(for: procedure.hospitalID)?.forecast, capturedAt: .now, planningEvidence: model.planningEvidence(for: procedure.hospitalID))
            }.buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
            Spacer()
        }.padding(Northstar.Space.s6)
    }

    private func weather(_ procedure: Procedure) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                Text("Simulated weather").font(Northstar.Fonts.title)
                Text(model.hospital(procedure.hospitalID)?.name ?? "Site not recorded").font(Northstar.Fonts.bodyStrong)
                if let evidence = model.planningEvidence(for: procedure.hospitalID) {
                    let forecast = evidence.forecast
                    LabeledContent("Evidence revision", value: String(evidence.revision))
                    LabeledContent("Source", value: evidence.source)
                    LabeledContent("Scenario", value: evidence.scenario)
                    Text(forecast.summary).font(Northstar.Fonts.body)
                    LabeledContent("Snowfall summary", value: "\(forecast.snowfallInches.formatted()) in")
                    LabeledContent("Forecast as of", value: forecast.asOf.map { $0.formatted() } ?? "Unknown")
                    LabeledContent("Explicit road closure", value: forecast.roadClosureAt.map { $0.formatted() } ?? "Unknown absolute time")
                } else {
                    ContentUnavailableView("No forecast recorded", systemImage: "cloud", description: Text("Missing weather is unknown. Coverage reasons remain available in Cases."))
                }
                Text("Hourly observations and departure time are not recorded. No graph or route is inferred from a summary.")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }.padding(Northstar.Space.s6)
        }
    }

    private func optionRow(_ option: CoverageMatcher.Option) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s1) {
            Text(option.title).font(Northstar.Fonts.bodyStrong)
            switch option {
            case .inPersonRep(let rep, _), .remoteRep(let rep):
                Text("\(rep.statedRole.map(roleLabel) ?? "Role not recorded") · Not requested")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            case .reschedule(let reason):
                Text("Coordinator option · \(reason)")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }
        }
        .padding(.vertical, Northstar.Space.s2)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text(title).font(Northstar.Fonts.bodyStrong).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func schedule(_ procedure: Procedure, date: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = model.hospital(procedure.hospitalID)?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
        formatter.dateStyle = date ? .medium : .none
        formatter.timeStyle = .short
        let zone = formatter.timeZone.abbreviation(for: procedure.scheduledAt) ?? formatter.timeZone.identifier
        return "\(formatter.string(from: procedure.scheduledAt)) \(zone)"
    }

    private func roleLabel(_ role: ParticipantRole) -> String {
        switch role {
        case .coordinator: "Coordinator"
        case .orTeam: "OR team"
        case .technicalRep: "Technical rep"
        case .clinicalSpecialist: "Clinical specialist"
        }
    }

    private func riskTone(_ risk: RiskLevel) -> NorthstarTone {
        risk == .low ? .neutral : .attention
    }
}
