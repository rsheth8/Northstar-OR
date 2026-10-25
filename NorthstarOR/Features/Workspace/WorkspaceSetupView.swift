import SwiftUI

/// Shared pieces for the workspace forms.
struct SiteFields: View {
    @Binding var site: SiteDraft

    var body: some View {
        Text("Site name").font(Northstar.Fonts.supporting)
        TextField("Site name", text: $site.name)
        Text("Town").font(Northstar.Fonts.supporting)
        TextField("Town", text: $site.town)
        Picker("Time zone", selection: $site.timeZoneIdentifier) {
            ForEach(WorkspaceForms.timeZoneChoices(including: site.timeZoneIdentifier), id: \.self) { id in
                Text(id.replacingOccurrences(of: "_", with: " ")).tag(id)
            }
        }
    }
}

struct WorkspaceErrorBanner: View {
    let message: String?
    var body: some View {
        if let message {
            NorthstarBanner(tone: .failure, title: "Not saved", message: "\(message) Your entries are kept.")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("workspace-form-error")
        }
    }
}

/// First launch: create a blank fictional workspace, or explicitly load sample content.
struct WorkspaceSetupView: View {
    let onCreate: (WorkspaceConfiguration) throws -> Void
    let onLoadSample: () throws -> Void

    @State private var draft = WorkspaceSetupDraft()
    @State private var errorMessage: String?
    @State private var confirmingSample = false

    var body: some View {
        NavigationStack {
            Form {
                WorkspaceErrorBanner(message: errorMessage)
                Section {
                    Text("Everything here is fictional and stays on this device. Nothing identifies a real patient or hospital.")
                        .font(Northstar.Fonts.supporting)
                        .foregroundStyle(Northstar.Palette.inkMuted)
                }
                Section("Workspace") {
                    Text("Workspace name").font(Northstar.Fonts.supporting)
                    TextField("Workspace name", text: $draft.workspaceName)
                        .accessibilityIdentifier("setup-workspace-name")
                }
                Section("First site") {
                    SiteFields(site: $draft.site)
                }
                Section("You") {
                    Text("Your name").font(Northstar.Fonts.supporting)
                    TextField("Your name", text: $draft.participantName)
                        .accessibilityIdentifier("setup-participant-name")
                    Picker("Role", selection: $draft.role) {
                        ForEach(WorkspaceForms.participantRoles, id: \.self) { Text(WorkspaceForms.label(for: $0)).tag($0) }
                    }
                    Text("A stated role for this workspace. It does not verify identity.")
                        .font(Northstar.Fonts.supporting)
                        .foregroundStyle(Northstar.Palette.inkMuted)
                }
                Section {
                    WorkspaceErrorBanner(message: errorMessage)
                    Button("Create workspace", action: create)
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .accessibilityIdentifier("setup-create")
                    Button("Load sample workspace") {
                        if draft != WorkspaceSetupDraft() { confirmingSample = true } else { loadSample() }
                    }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                        .accessibilityIdentifier("setup-load-sample")
                } footer: {
                    Text("Sample content is optional fictional data. You can set up your own workspace instead.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Northstar.Palette.bgBase)
            .navigationTitle("Set up workspace")
        }
        .alert("Replace setup entries with samples?", isPresented: $confirmingSample) {
            Button("Load sample workspace", role: .destructive, action: loadSample)
            Button("Keep editing", role: .cancel) {}
        }
        .tint(Northstar.Palette.ice)
    }

    private func create() {
        do {
            let config = try draft.build()
            try onCreate(config)
            errorMessage = nil
        } catch {
            errorMessage = WorkspaceForms.message(for: error)
        }
    }

    private func loadSample() {
        do {
            try onLoadSample()
            errorMessage = nil
        } catch {
            errorMessage = WorkspaceForms.message(for: error)
        }
    }
}

#Preview("Setup") {
    WorkspaceSetupView(onCreate: { _ in }, onLoadSample: {})
}
