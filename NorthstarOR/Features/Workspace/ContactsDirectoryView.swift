import SwiftUI

/// List of fictional contacts with add, edit and remove.
struct ContactsDirectoryView: View {
    let workspace: WorkspaceConfiguration
    let onSave: (WorkspaceConfiguration) throws -> Void

    @State private var current: WorkspaceConfiguration
    @State private var errorMessage: String?

    init(workspace: WorkspaceConfiguration, onSave: @escaping (WorkspaceConfiguration) throws -> Void) {
        self.workspace = workspace
        self.onSave = onSave
        _current = State(initialValue: workspace)
    }

    var body: some View {
        List {
            WorkspaceErrorBanner(message: errorMessage)
            Section {
                ForEach(current.contacts) { rep in
                    NavigationLink {
                        ContactFormView(workspace: current, draft: ContactDraft(rep), onSave: commit)
                    } label: { row(rep) }
                    .frame(minHeight: Northstar.Target.minimum)
                    .accessibilityIdentifier("contact-\(rep.id)")
                }
                .onDelete(perform: remove)
            } footer: {
                if current.contacts.isEmpty {
                    Text("No contacts yet. Add a fictional contact to request support from.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Northstar.Palette.bgBase)
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ContactFormView(workspace: current, draft: ContactDraft(), onSave: commit)
                } label: { Label("Add contact", systemImage: "plus") }
                .accessibilityIdentifier("contacts-add")
            }
        }
        .onChange(of: workspace) { _, new in current = new }
    }

    private func row(_ rep: DeviceRep) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s1) {
            Text(rep.name).font(Northstar.Fonts.bodyStrong)
            Text("\(WorkspaceForms.label(for: rep.statedRole ?? .technicalRep)) · \(rep.homeBase)")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            HStack {
                NorthstarStatusLabel(rep.isAvailable ? "Listed available" : "Listed unavailable",
                                     tone: rep.isAvailable ? .success : .neutral,
                                     systemImage: rep.isAvailable ? "checkmark.circle" : "minus.circle")
                if rep.canSupportRemotely {
                    NorthstarStatusLabel("Can support remotely", tone: .info, systemImage: "video")
                }
            }
        }
    }

    /// Saves through the closure; local state changes only after it returns.
    private func commit(_ updated: WorkspaceConfiguration) throws {
        try onSave(updated)
        current = updated
        errorMessage = nil
    }

    private func remove(at offsets: IndexSet) {
        var updated = current
        updated.contacts.remove(atOffsets: offsets)
        do { try commit(updated) } catch { errorMessage = WorkspaceForms.message(for: error) }
    }
}

struct ContactFormView: View {
    let workspace: WorkspaceConfiguration
    let onSave: (WorkspaceConfiguration) throws -> Void

    @State private var draft: ContactDraft
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var baseline: ContactDraft
    @State private var confirmingDiscard = false
    @Environment(\.dismiss) private var dismiss

    init(workspace: WorkspaceConfiguration, draft: ContactDraft,
         onSave: @escaping (WorkspaceConfiguration) throws -> Void) {
        self.workspace = workspace
        self.onSave = onSave
        _draft = State(initialValue: draft)
        _baseline = State(initialValue: draft)
    }

    var body: some View {
        Form {
            WorkspaceErrorBanner(message: errorMessage)
            Section("Contact") {
                Text("Name").font(Northstar.Fonts.supporting)
                TextField("Name", text: $draft.name).accessibilityIdentifier("contact-name")
                Text("Home base").font(Northstar.Fonts.supporting)
                TextField("Home base", text: $draft.homeBase)
                Picker("Role", selection: $draft.role) {
                    ForEach(WorkspaceForms.contactRoles, id: \.self) { Text(WorkspaceForms.label(for: $0)).tag($0) }
                }
            }
            Section {
                Toggle("Supports \(ContactDraft.family) cases", isOn: $draft.supportsTemplateFamily)
                Toggle("Listed as available", isOn: $draft.isAvailable)
                Toggle("Can support remotely", isOn: $draft.canSupportRemotely)
            } header: {
                Text("Skills and availability")
            } footer: {
                Text("Stated by the team for planning. Not verified, and not a live status.")
            }
            Section {
                ForEach(workspace.sites) { site in
                    HStack {
                        Text(site.name)
                        Spacer()
                        TextField("min", text: driveBinding(site.id))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .accessibilityLabel("Drive minutes to \(site.name)")
                    }
                    .frame(minHeight: Northstar.Target.minimum)
                }
            } header: {
                Text("Simulated drive minutes")
            } footer: {
                Text("Fictional figures used for coverage planning. Leave blank if unknown.")
            }
            Section {
                WorkspaceErrorBanner(message: errorMessage)
                Button("Save contact", action: save)
                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    .accessibilityIdentifier("contact-save")
                if saved {
                    NorthstarStatusLabel("Saved on this device", tone: .success, systemImage: "checkmark.circle")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Northstar.Palette.bgBase)
        .navigationTitle(draft.name.isEmpty ? "New contact" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft) { _, _ in saved = false }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { if draft != baseline { confirmingDiscard = true } else { dismiss() } }
                    .northstarHitTarget()
            }
        }
        .interactiveDismissDisabled(draft != baseline)
        .confirmationDialog("Discard contact changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
    }

    private func driveBinding(_ siteID: String) -> Binding<String> {
        Binding(get: { draft.driveText[siteID] ?? "" }, set: { draft.driveText[siteID] = $0 })
    }

    private func save() {
        do {
            let updated = try draft.applying(to: workspace)
            try onSave(updated)
            errorMessage = nil
            saved = true
            dismiss()
        } catch {
            errorMessage = WorkspaceForms.message(for: error)
            saved = false
        }
    }
}

#Preview("Contacts") {
    NavigationStack {
        ContactsDirectoryView(workspace: WorkspacePreviewData.workspace, onSave: { _ in })
    }
}
