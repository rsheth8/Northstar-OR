import SwiftUI

/// Create or edit a planned case. No patient information is collected.
/// `onSave` throws on failure; the form then stays open with the input kept.
struct CaseFormView: View {
    let workspace: WorkspaceConfiguration
    let existingCases: [Procedure]
    let editing: Procedure?
    let onSave: (CaseInput) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: CaseFormDraft
    @State private var showIssues = false
    @State private var saveFailure: String?

    init(workspace: WorkspaceConfiguration, existingCases: [Procedure], editing: Procedure? = nil,
         onSave: @escaping (CaseInput) throws -> Void) {
        self.workspace = workspace
        self.existingCases = existingCases
        self.editing = editing
        self.onSave = onSave
        _draft = State(initialValue: editing.map { CaseFormDraft.editing($0, in: workspace) }
                       ?? CaseFormDraft.new(in: workspace))
    }

    private var issue: CaseFormDraft.Issue? {
        draft.validate(in: workspace, existingCases: existingCases, editing: editing)
    }

    private var template: CoordinationTemplate { FictionalCoordinationTemplate.template }

    private var site: Hospital? { workspace.sites.first { $0.id == draft.input.siteID } }

    private var timeZone: TimeZone {
        site?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    var body: some View {
        NavigationStack {
            Form {
                if let saveFailure {
                    Section {
                        NorthstarBanner(tone: .alert, title: "Case not saved", message: saveFailure)
                            .accessibilityIdentifier("case-form-save-error")
                    }
                }
                Section("Case") {
                    field("Reference", prompt: "e.g. NS-104", text: $draft.input.reference, for: .reference)
                    field("Title", prompt: "Fictional case title", text: $draft.input.title, for: .title)
                }
                Section("Site and time") {
                    Picker("Site", selection: $draft.input.siteID) {
                        ForEach(workspace.sites) { Text($0.name).tag($0.id) }
                    }
                    .accessibilityIdentifier("case-form-site")
                    message(for: .site)
                    DatePicker("Date and time", selection: $draft.input.scheduledAt,
                               displayedComponents: [.date, .hourAndMinute])
                        .environment(\.timeZone, timeZone)
                        .accessibilityIdentifier("case-form-schedule")
                    LabeledContent("Time zone", value: timeZone.localizedName(for: .standard, locale: .current)
                                   .map { "\($0) (\(timeZone.identifier))" } ?? timeZone.identifier)
                        .font(Northstar.Fonts.caption)
                    message(for: .schedule)
                    Stepper(value: $draft.input.durationMinutes, in: CaseInput.supportedDurationMinutes, step: 15) {
                        LabeledContent("Duration", value: CaseFormDraft.durationLabel(draft.input.durationMinutes))
                    }
                    .accessibilityIdentifier("case-form-duration")
                    message(for: .duration)
                }
                Section {
                    LabeledContent("Device family", value: template.deviceFamily.capitalized)
                    LabeledContent("Template", value: "\(template.name), version \(template.reference.version)")
                    message(for: .template)
                } header: {
                    Text("Coordination template")
                } footer: {
                    Text("Fictional exercise content. The app records team reports and gives no clinical direction.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Northstar.Palette.bgBase)
            .navigationTitle(editing == nil ? "New case" : "Edit case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .northstarHitTarget()
                        .accessibilityIdentifier("case-form-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .northstarHitTarget()
                        .accessibilityIdentifier("case-form-save")
                }
            }
        }
        .tint(Northstar.Palette.ice)
    }

    private func field(_ label: String, prompt: String, text: Binding<String>,
                       for field: CaseFormDraft.Field) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s1) {
            TextField(label, text: text, prompt: Text(prompt))
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(field == .reference)
                .accessibilityIdentifier("case-form-\(label.lowercased())")
            message(for: field)
        }
    }

    @ViewBuilder private func message(for field: CaseFormDraft.Field) -> some View {
        if showIssues, let issue, issue.field == field {
            Label(issue.message, systemImage: "exclamationmark.triangle.fill")
                .font(Northstar.Fonts.caption)
                .foregroundStyle(Northstar.Palette.alert)
                .accessibilityIdentifier("case-form-error-\(label(field))")
        }
    }

    private func label(_ field: CaseFormDraft.Field) -> String { "\(field)" }

    private func save() {
        saveFailure = nil
        if let issue {
            showIssues = true
            if issue.field == nil { saveFailure = issue.message }
            return
        }
        do {
            try onSave(draft.input)
            dismiss()
        } catch {
            saveFailure = CaseFormDraft.issue(for: error).message
        }
    }
}

#Preview("New case") {
    let site = Hospital(id: "site-a", name: "Fictional Lakeside Hospital", town: "Example town",
                        workspaceID: "ws", timeZoneIdentifier: "America/Chicago")
    let workspace = WorkspaceConfiguration(
        id: "ws", name: "Fictional workspace", sites: [site], contacts: [],
        localParticipant: LocalParticipant(id: "p", workspaceID: "ws", displayName: "Fictional coordinator", statedRole: .coordinator))
    CaseFormView(workspace: workspace, existingCases: []) { _ in }
}
