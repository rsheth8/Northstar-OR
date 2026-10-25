import Foundation

/// Form state and validation for the case form, kept free of SwiftUI so it can be tested.
/// Validation is delegated to `CaseInput.makeProcedure` / `updating`; this type only maps
/// the resulting errors to short, plain copy and to the field they belong to.
struct CaseFormDraft: Equatable {
    enum Field: Hashable { case reference, title, site, schedule, duration, template }

    /// A validation failure: the field it belongs to (nil for the whole form) and plain copy.
    struct Issue: Equatable {
        let field: Field?
        let message: String
    }

    var input: CaseInput

    static let templates = [FictionalCoordinationTemplate.template]

    /// New case draft: a fresh UUID-based id and the supported fictional template pre-selected.
    static func new(in workspace: WorkspaceConfiguration, now: Date = .now,
                    id: String = "case-\(UUID().uuidString.lowercased())") -> CaseFormDraft {
        let template = FictionalCoordinationTemplate.template
        return CaseFormDraft(input: CaseInput(
            id: id, workspaceID: workspace.id, reference: "", title: "",
            siteID: workspace.sites.first?.id ?? "", scheduledAt: now, durationMinutes: 60,
            deviceFamily: template.deviceFamily, templateReference: template.reference))
    }

    /// Edit draft: keeps the existing id, template and device family.
    static func editing(_ procedure: Procedure, in workspace: WorkspaceConfiguration) -> CaseFormDraft {
        CaseFormDraft(input: CaseInput(
            id: procedure.id, workspaceID: procedure.workspaceID ?? workspace.id,
            reference: procedure.reference ?? "", title: procedure.name, siteID: procedure.hospitalID,
            scheduledAt: procedure.scheduledAt, durationMinutes: procedure.durationMinutes,
            deviceFamily: procedure.deviceFamily, templateReference: procedure.templateReference))
    }

    /// Returns nil when the input is acceptable to the model, otherwise the first issue.
    func validate(in workspace: WorkspaceConfiguration, existingCases: [Procedure],
                  editing previous: Procedure?) -> Issue? {
        do {
            if let previous {
                _ = try input.updating(previous, in: workspace, existingCases: existingCases,
                                       templates: Self.templates)
            } else {
                _ = try input.makeProcedure(in: workspace, existingCases: existingCases,
                                            templates: Self.templates)
            }
            return nil
        } catch {
            return Self.issue(for: error)
        }
    }

    static func issue(for error: Error) -> Issue {
        guard let error = error as? WorkspaceContractError else {
            return Issue(field: nil, message: "The case could not be saved. Your entries are still here.")
        }
        switch error {
        case .required(let name):
            switch name {
            case "case.reference": return Issue(field: .reference, message: "Enter a case reference.")
            case "case.title": return Issue(field: .title, message: "Enter a case title.")
            case "case.siteID": return Issue(field: .site, message: "Choose a site.")
            case "case.deviceFamily": return Issue(field: .template, message: "Choose a device family.")
            default: return Issue(field: nil, message: "Workspace setup is incomplete. Check Workspace settings.")
            }
        case .duplicateCaseReference:
            return Issue(field: .reference, message: "Another case already uses this reference.")
        case .duplicateCaseTitle:
            return Issue(field: .title, message: "Another case already uses this title.")
        case .unknownSite:
            return Issue(field: .site, message: "This site is not in the workspace. Choose another site.")
        case .invalidDuration:
            return Issue(field: .duration, message: "Duration must be between 1 minute and 24 hours.")
        case .invalidSchedule:
            return Issue(field: .schedule, message: "Choose a valid date and time.")
        case .unsupportedTemplate:
            return Issue(field: .template, message: "This device family has no supported template.")
        case .duplicateID, .immutableCaseIdentity, .foreignWorkspace:
            return Issue(field: nil, message: "This case does not match the workspace. Close the form and try again.")
        default:
            return Issue(field: nil, message: "Workspace setup needs attention. Check Workspace settings.")
        }
    }

    /// Short label for durations, e.g. "1 h 30 min".
    static func durationLabel(_ minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }
}
