import Foundation

/// This fictional coordination exercise has no clinical validation or instructions.
enum FictionalCoordinationTemplate {
    static let id = "fictional-pacemaker-coordination"
    /// Version 2 replaced generic item wording with pacemaker coordination milestones.
    static let version = 2
    static let name = "Fictional pacemaker coordination"
    static let deviceFamily = "pacemaker"
    static let source = "Northstar OR fictional coordination exercise, version 2"
    static let applicability = "Recording team-reported coordination for fictional pacemaker cases only. Does not verify clinical work or outcomes."
    static let reference = CoordinationTemplateReference(id: id, version: version)
    static var template: CoordinationTemplate {
        CoordinationTemplate(reference: reference, name: name, deviceFamily: deviceFamily,
                             applicability: applicability, source: source, availability: .supportedFictional, steps: steps)
    }
    /// Suggested replies for the technical rep. Logistics and documentation only; the
    /// physician directs any programming and makes every clinical decision.
    static let technicalSupportReplies = [
        "Received. I can see the case brief and the deferred item.",
        "Please read me the model and serial number from the device packaging and I'll match the documentation.",
        "I can walk your team through the programmer connection screens; the physician directs any programming.",
        "I'm supporting remotely. Please keep a team member at the programmer.",
        "I can discuss technical documentation; the team retains clinical decisions.",
    ]

    // Item IDs are kept from version 1 so identities stay stable; content changed, so the
    // version changed. Each item records what the team reports at a pacemaker coordination
    // milestone (WHO time-out and sign-out, and the technical steps a device rep normally
    // supports). Nothing here instructs clinical work, takes measurements or judges results.
    static let steps: [ProcedureStep] = [
        ProcedureStep(id: "timeout", title: "Time-out recorded", detail: "Record that the team reports its surgical time-out was completed, including the planned pacemaker procedure and site. Northstar records the report; it does not lead or verify the time-out.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "device-check", title: "Device and lead models confirmed", detail: "Record that the team reports the generator and lead models and serial numbers on the packaging were read back against the case plan. Fictional values only; a report is not a suitability check.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "programmer", title: "Programmer and analyzer ready", detail: "Record that the team reports the manufacturer programmer and pacing system analyzer are connected and set to the right device family, and who is operating them: an on-site rep, a remote rep with on-site staff, or hospital device staff. Defer if this is not confirmed.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "lead-placement", title: "Lead positioning reported", detail: "Record that the implanting physician reported lead positioning is complete. Northstar does not assess position or technique.", isRequired: true, normallyCoveredByRep: false),
        ProcedureStep(id: "thresholds", title: "Lead measurements documented", detail: "Record that the team reports lead measurements (sensing, impedance and threshold) were taken and documented in its own record. No values are entered or interpreted here.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "connect-device", title: "Leads connected to device", detail: "Record that the team reports the leads were connected to the generator and the connection was secured. A deferral here stays visible in the rep's brief.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "final-interrogation", title: "Final interrogation documented", detail: "Record that the team reports a final device interrogation was completed and the programmed settings were documented under the physician's direction. Northstar does not choose or check settings.", isRequired: true, normallyCoveredByRep: true),
        ProcedureStep(id: "closure", title: "Sign-out and handoff", detail: "Record the team's sign-out: device registration and ID card details handed off, and any deferred items reviewed. Recording does not certify procedure completion or outcome.", isRequired: true, normallyCoveredByRep: false),
    ]

    /// Creates an ordinary case from this content, with no sample identity dependency.
    static func makeProcedure(id: String, name: String, hospitalID: String,
                              scheduledAt: Date, durationMinutes: Int,
                              workspaceID: String? = nil, reference: String? = nil) -> Procedure {
        Procedure(id: id, name: name, deviceFamily: deviceFamily, hospitalID: hospitalID,
                  scheduledAt: scheduledAt, durationMinutes: durationMinutes, steps: steps,
                  workspaceID: workspaceID, reference: reference ?? id, templateReference: self.reference)
    }

    /// Both the exact pinned reference and that version's content must match.
    static func supports(_ procedure: Procedure) -> Bool {
        template.supports(procedure)
    }
}
