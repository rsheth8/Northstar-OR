import SwiftUI

/// Edit workspace name, sites and the local participant; reach contacts from here.
struct WorkspaceSettingsView: View {
    let workspace: WorkspaceConfiguration
    let onSave: (WorkspaceConfiguration) throws -> Void

    @State private var draft: WorkspaceSettingsDraft
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var baseline: WorkspaceSettingsDraft
    @State private var current: WorkspaceConfiguration
    @State private var confirmingDiscard = false
    @Environment(\.dismiss) private var dismiss

    init(workspace: WorkspaceConfiguration, onSave: @escaping (WorkspaceConfiguration) throws -> Void) {
        self.workspace = workspace
        self.onSave = onSave
        _draft = State(initialValue: WorkspaceSettingsDraft(workspace))
        _baseline = State(initialValue: WorkspaceSettingsDraft(workspace))
        _current = State(initialValue: workspace)
    }

    var body: some View {
        NavigationStack {
            Form {
                WorkspaceErrorBanner(message: errorMessage)
                Section("Workspace") {
                    Text("Workspace name").font(Northstar.Fonts.supporting)
                    TextField("Workspace name", text: $draft.name)
                        .accessibilityIdentifier("settings-workspace-name")
                }
                Section {
                    ForEach($draft.sites) { $site in
                        VStack(alignment: .leading) { SiteFields(site: $site) }
                            .padding(.vertical, Northstar.Space.s1)
                    }
                    .onDelete { offsets in
                        guard draft.sites.count > offsets.count else {
                            errorMessage = "A workspace needs at least one site."
                            return
                        }
                        draft.sites.remove(atOffsets: offsets)
                    }
                    Button { draft.sites.append(SiteDraft()) } label: { Label("Add site", systemImage: "plus") }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                        .accessibilityIdentifier("settings-add-site")
                } header: {
                    Text("Sites")
                } footer: {
                    Text("Swipe a site to remove it. Drive times to a removed site are dropped from contacts.")
                }
                Section("You") {
                    Text("Your name").font(Northstar.Fonts.supporting)
                    TextField("Your name", text: $draft.participantName)
                    Picker("Role", selection: $draft.role) {
                        ForEach(WorkspaceForms.participantRoles, id: \.self) { Text(WorkspaceForms.label(for: $0)).tag($0) }
                    }
                }
                Section {
                    NavigationLink {
                        ContactsDirectoryView(workspace: current, onSave: { updated in
                            try onSave(updated)
                            current = updated
                        })
                    } label: {
                        Label("Contacts (\(workspace.contacts.count))", systemImage: "person.2")
                    }
                    .frame(minHeight: Northstar.Target.minimum)
                    .accessibilityIdentifier("settings-contacts")
                }
                Section {
                    WorkspaceErrorBanner(message: errorMessage)
                    Button("Save settings", action: save)
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .accessibilityIdentifier("settings-save")
                    if saved {
                        NorthstarStatusLabel("Saved on this device", tone: .success, systemImage: "checkmark.circle")
                            .accessibilityIdentifier("settings-saved")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Northstar.Palette.bgBase)
            .navigationTitle("Workspace settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { if draft != baseline { confirmingDiscard = true } else { dismiss() } }
                        .frame(minHeight: Northstar.Target.minimum)
                        .accessibilityIdentifier("settings-done")
                }
            }
            .onChange(of: draft) { _, _ in saved = false }
        }
        .interactiveDismissDisabled(draft != baseline)
        .confirmationDialog("Discard unsaved settings?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
        .tint(Northstar.Palette.ice)
    }

    private func save() {
        do {
            let updated = try draft.applying(to: current)
            try onSave(updated)
            current = updated
            baseline = draft
            errorMessage = nil
            saved = true
        } catch {
            errorMessage = WorkspaceForms.message(for: error)
            saved = false
        }
    }
}

#Preview("Settings") {
    WorkspaceSettingsView(workspace: WorkspacePreviewData.workspace, onSave: { _ in })
}

enum WorkspacePreviewData {
    static let workspace: WorkspaceConfiguration = {
        let wid = "workspace-preview"
        let site = Hospital(id: "site-a", name: "Fictional General", town: "Exampleville",
                            workspaceID: wid, timeZoneIdentifier: "America/Chicago")
        let rep = DeviceRep(id: "contact-a", name: "Alex Example", homeBase: "Exampleville",
                            skills: [FictionalCoordinationTemplate.deviceFamily], driveMinutes: ["site-a": 35],
                            isAvailable: true, canSupportRemotely: true, workspaceID: wid,
                            statedRole: .technicalRep, travelAsOf: Date())
        return WorkspaceConfiguration(id: wid, name: "Fictional coordination team", sites: [site], contacts: [rep],
                                      localParticipant: LocalParticipant(id: "p1", workspaceID: wid,
                                                                         displayName: "Sam Sample", statedRole: .coordinator))
    }()
}
