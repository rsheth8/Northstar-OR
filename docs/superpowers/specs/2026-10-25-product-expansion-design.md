# Northstar OR: complete experience and expansion design

Date: October 25, 2026. Baseline: `8982a7f`, merged PR #48. **Proposed design for review; not implemented.** User direction: consider every current feature, improve the complete UI/UX, and plan voice commands plus richer Planner maps, weather graphs and reports. The user endorsed planning these additions; delivery dates, providers and deployment claims are not agreed.

## Purpose and boundaries

Help a coordinator choose and maintain an explainable logistical support arrangement, help the room team record explicit statements without distraction, and let a technical rep join with enough context to respond. More data earns its place by helping one of those jobs.

Keep three main tabs: Co-pilot, Planner, Remote Support. Settings remains secondary. Preserve native SwiftUI iPadOS 17+ and native Mac Catalyst support. Use Northstar design tokens, 72 pt primary targets, 44 pt other targets and adaptive layouts. Keep fictional records in Data; ordinary runtime records use the repository. Features use AppModel commands and SyncService, never a view-owned network SDK or parallel store.

Simulated data only. No real patients, hospitals' real data, or real people. No clinical decisions, invented readiness scores, ambient completion, automatic plan commitment or unproven delivery. Technical coverage is distinct from clinical coverage. No production authentication, EHR integration, distant network service, push notifications or live tracking is implied.

## Approaches and working recommendation

1. **Staged expansion in the current app — recommended working approach.** Repair current workflow friction; finish true plan management; add Planner evidence views and deliberate voice as bounded slices. Preserves the existing stack and gives each addition a usable fallback. More incremental review, less simultaneous change.
2. **Large dashboard redesign.** Add maps/charts/voice together. Faster visual breadth, but unstable shared data contracts and crowded screens obscure the central work. Not recommended.
3. **Keep the present app and build a separate analytics product.** Good separation for a future institutional reporting program, but duplicates case context and does not answer the current request for a better Planner. Defer until reporting scale warrants it.

The recommendation was presented in the conversation; this document makes its consequences concrete. The defaults below are proposals, not individually approved user requirements. This roadmap does not authorize concurrent writers in shared files.

## Complete feature coverage

| Feature family | Current baseline | Target and dependency |
| --- | --- | --- |
| Setup/settings/sites | Functional saved forms and explicit samples | Persistent labels, first-error focus, protected edits, site editors, useful blank-workspace next action |
| Directory/roles | Editable stated roles, skills, availability, remote capability and travel estimates | Visible eligibility/unknowns, explicit removals, distinct participant/device roles, selected contact versus actual peer |
| Cases/schedule | Create/edit, search, coverage filter, explicit start/resume | Site-local day grouping, recording state, date/status/site filters, duration/time-zone clarity; browsing remains independent |
| Matcher | Pure ranking with constraints and simulated travel/forecast | Preserve explanation, add explicit data completeness/freshness and future conflict handling; no implied road certainty |
| Support plans | Ranked options; context-only action | One versioned named-rep request specifying in-person or remote support, or reschedule intention; explicit acceptance/decline, unrequested backups, safe replacement |
| Co-pilot | Guarded recording, deferral, pinned acknowledgment, correction | Dominant current item, adaptive full-label navigation, fewer duplicate headings, stable support access |
| Question/context | Frozen request snapshot, acknowledgment/reply and later context | One question flow; question-first rep view; frozen/current context clearly separated; history preserved |
| General messages | Saved case thread, drafts, receipts/retry | Secondary message mode, incoming attention, inline error/retry, keyboard-safe composer |
| Nearby connection | Discovery/invitation/pairing, retained projection/reconnect | Useful disconnected/stale states, clear peer identity, restore without claiming a live connection |
| Audio/video calls | Invitations, native media/controls, adaptive workspace panel | Preserve #48; permission, end-call versus disconnect, repeat-call and interruption verification; mic arbitration before voice |
| Review/persistence/lifecycle | Saved sessions/events/drafts, atomic store/recovery; ended label derives from selection rather than a full lifecycle | Unresolved-first case review, explicit recording lifecycle independent of selection, actor/source/time, original corrections, visible unsaved outcomes, compatible migrations |
| Speech output | Short deferral announcements and optional spoken rep alerts | Preserve important visible equivalents, suppress/reconcile during calls/listening and prevent the app from recognizing its own speech |
| Voice | Broad transcript parser/service, not wired into UI | Explicit vocabulary, visible listening, stable-target preview/commit, duplicate protection, no ambient recording |
| Map | Optional site coordinates; no map UI or route geometry | Selected-case/site map and equivalent list, fictional configured home-base points, missing-coordinate state; no live rep location |
| Weather | Summary/snowfall/closure and as-of; no hourly series | Versioned simulated hourly samples, freshness/units/source, case/travel window graph, unknown/stale state |
| Reports | No report/export workflow | Deterministic case brief first; operational reporting after required events; reviewed local export separately |
| AI/image interpretation | Not implemented | Grounded handoff drafts and mock-label observations later; explicit review, source and uncertainty |
| More workflows | One supported pinned template; unsupported ICD blocked | Additional fictional content only after explicit content review and applicability/version tests |

## Proposed experience

### Planner

Local destinations inside Planner: **Cases**, **Coverage**, **Weather**, **Reports**. Start with Cases. These are views of one selected case/date/site scope, not separate data stores. At narrow widths use a native destination menu/detail flow. Keep active recording context distinct from the selected planning case. Filters and selection survive ordinary destination changes; a pending acknowledgment never prevents browsing.

Cases prioritizes day/time/site, recording lifecycle, current plan and coverage constraint. Coverage combines ranked eligible options and current arrangement with a map. Map markers and rows select the same IDs. Basic geographic context is useful without route lines. A home-base point is a listed fictional base, never a live person or proof of attendance. No marker for missing coordinates and no fabricated precise point for a town name. If a real basemap service is used, it is geographic background only; all operational locations and weather/travel records remain fictional. Provide an offline list and source attribution.

Define one authoritative selected evidence revision per site/scenario/time range, consumed by both matcher and chart. Migration from legacy `StormForecast` and `DeviceRep.driveMinutes` preserves values and unknown timestamps; an absent baseline never becomes “now.” Keep missing closure timing unknown rather than reanchoring a legacy relative duration on every render.

Weather answers whether the simulated evidence overlaps the planned travel/case window. Show forecast issue time, valid times, site time zone, units and source/scenario label. Plot only recorded quantities; precipitation, temperature and wind have separate labeled scales when present. Closure is an independently recorded logistical event, never inferred from a snowfall threshold. Missing samples are gaps, not zero; out-of-date values remain visibly stale and do not silently become new evidence. Timeline integrates listed travel duration, explicit planned departure (when recorded), setup buffer, scheduled case and closure, with no automatic scheduling choice.

Reports starts with an on-screen **Case coordination brief**: selected case/template, current plan and separate acceptance, latest logistical evidence, unresolved work, source times and support exchanges. It is a deterministic snapshot, not AI. Operational reports later describe request response times, coverage arrangements and unresolved follow-up across an explicitly selected period. Define which request/receipt/acknowledgment timestamps count, exclude local simulations from remote response claims, and show denominators/missing values. Export requires review, date/time-zone context and a distinct explicit action; no automatic external sending.

### Voice

Recommended first release: user-enabled, short command sessions with a visible microphone control; touch remains available. Navigation/read-only commands may execute directly. State-changing commands first display **Heard → action → named item/case**, then require an explicit commit. Initial command phrases: “Open Planner,” “Open Co-pilot,” “Show unresolved items,” “Record confirmation,” “Defer this item,” “Acknowledge deferral,” and “Stop listening.” Selection and mutation are distinct. Broad “done,” “next,” “skip” or substring matches do not mutate the record.

Mutation captures session ID, item ID, expected version and acknowledgment ID where applicable. A repeated final recognition event can commit at most once. Changing case/item/version, backgrounding, permission loss or leaving the command session invalidates the pending command. Negated/ambiguous/partial utterances do nothing and explain the result. Read-only summary never infers completion.

Synthesized deferral/rep alerts must not be recognized as user commands. Suspend recognition around app speech and invalidate partial results, or suppress optional speech while listening; prove this policy during the audio spike. Important alerts always remain visible.

Dictation is a separate composer action; recognizing words in a question never executes commands. Sending a message, changing device role, switching active recording, replacing a plan, ending a call and removing records remain touch-only initially. During a call, command listening is disabled with a clear explanation until microphone/audio-session coexistence has been separately proven. No promise of offline recognition unless capability is checked on that device. Microphone/speech permission denial, interruption and unavailable recognition have visible recovery and touch fallback. Later deliberate hands-free commit can be evaluated with an OR-member fictional walkthrough; it is not required for the first release.

### Retained record lifecycle

Add explicit recording/ended/reviewable state independently of whether an item is selected. Ending is an intentional app-record action, may retain unresolved items and never certifies a procedure outcome. Do not infer end from all-confirmed or no selection. A pending required acknowledgment must be handled explicitly rather than erased by ending. Preserve prior events and drafts, show the unresolved count before ending, and define a deliberate reopen action if supported. Archive/export are separate explicit capabilities; deleting retained records is not proposed.

### Additional suggestions

- **Changes since you last viewed:** a small per-case summary of new messages/plan changes/unresolved work; no disruptive auto-scroll or auto-acknowledgment.
- **Support responsibility:** explicit named recipient, listed role, current request state and actual connected peer; a later owner/next-action field may help follow-up, but never claim a clinical handoff.
- **Freshness next to evidence:** displayed unknown/stale fields are more useful than decorative charts or a confidence percentage.
- **Coverage conflicts:** later compare accepted arrangements and explicit travel/setup intervals; a free/busy calendar import is not assumed. Existing availability Boolean cannot establish future capacity.
- **Scoped what-if comparison:** later compare user-edited logistical scenarios side by side with current evidence, without changing the committed plan.
- **Keyboard and accessibility parity:** discovery, review, forms and voice help all need conventional native controls; add no voice-only capability.

## Order, release boundaries and validation

1. Finish current UX/recovery and retained review, consuming merged #48 and audit #49 when merged.
2. Finish actual support-plan contracts, storage and explicit recipient actions before making a richer coverage dashboard imply arrangements exist.
3. Add Planner data contracts, editable fictional scenarios and geographic coverage; weather graphs consume those same records.
4. Deliver bounded voice separately; only start recording mutations after the audio-session and command-target spikes pass.
5. Deliver deterministic reports, then export and operational metrics backed by real recorded event semantics.
6. Evaluate optional AI/mock-label observations, additional reviewed templates, conflict/what-if features and distant support as separate projects.

Weather/map UI can ship independently of voice once its contracts land; do not run multiple writers in Models/AppModel/SyncService. No dates or effort promises are assigned. The current hackathon date does not imply that this whole roadmap fits before submission. Every release remains usable with missing maps/weather, denied voice permissions, no contacts or a disconnected peer.

Acceptance uses independently named fictional sites/contacts/two cases; default/largest text/narrow windows; VoiceOver and keyboard; relaunch, failed save, failed delivery, interrupted media and repeated voice output. Physically test voice in representative noise and during interruptions; record results rather than claiming clinical validation. Remote technical support never controls the room's recording authority.
