# Northstar OR: actual capabilities and fit with real rural device-rep coverage constraints

Research date: 2026-10-25. Part A is from local repository files (read-only). Part B is external web research. Nothing here is clinical advice. Where only secondary sources were found, that is stated.

## A. What Northstar does and does not do today (repository)

### Takeaway
Northstar is a native SwiftUI iPad (room) + Mac Catalyst (rep) prototype that (1) ranks simulated logistical coverage options with an explainable rule-based matcher, (2) records team-reported checklist confirmations/deferrals/corrections with a pinned acknowledgment gate, and (3) runs a nearby-only encrypted Multipeer session carrying a late-join brief, contextual questions with immutable snapshots, acknowledgments, replies, messages, and two-way audio plus room-camera video. It has no internet transport, no plan acceptance in Planner, no auth, no working voice, no AI/vision, no EHR link and no real weather data.

### Cited Findings

**Prior team research (docs/OR_LANDSCAPE.md, dated 2026-10-24) — summarize, do not duplicate:**
- Covers OR roles, case milestones, WHO checklist pause points (Sign In / Time Out / Sign Out, often coordinated by the circulator); HRS and ECRI positions that reps give technical help only and physicians own clinical judgment; rural coverage problem (reps cover distant territories; AdvaMed guidance urging remote support); a competitor table (OR boards such as Epic OpTime/LiveData; rep scheduling/credentialing such as Torq, Casechek, Vendormate; telepresence such as Proximie, Avail — shut down, tech acquired by Mendaera 2024; ambient OR AI such as Apella, caresyntax; clinical messaging such as TigerConnect, Vocera; digital checklist studies). Its conclusion: the hypothesized gap is the handoff when the usual rep can't attend; no independent data found on rural remote-rep usage. — [docs/OR_LANDSCAPE.md](file:///home/user/Northstar-OR/docs/OR_LANDSCAPE.md)

**Coverage Matcher (`NorthstarOR/Features/Planner/CoverageMatcher.swift`) — implemented rules, checked in order per rep:**
1. Technical-rep role required (`statedRole == .technicalRep`; "technical coverage is not inferred").
2. Stated skill must include the procedure's device family.
3. Rep must be marked available.
4. Drive time to the site must be recorded (unknown = blocker).
5. Scheduled start must not have passed.
6. Drive time + setup buffer (default 45 min) must fit before start (arriving with exactly the buffer left counts as on time).
7. Drive must arrive before simulated road closure (arriving exactly at closure = too late).
- Remote option = qualified + available + `canSupportRemotely` (a capability, not acceptance).
- Ranking: in-person options by drive time (then name/ID), then remote options, then **Reschedule** appended when nobody can attend in person. Risk: high (no in-person), elevated (simulated roads close during case window), low otherwise. Each rep gets a plain-language reason. "It ranks; it never commits a plan." — CoverageMatcher.swift (local)
- Weather input is a fixture `StormForecast` with summary and closure time; demo sample: Grand Marais blizzard, highway closes 90 min after load, Ana's 110-min drive arrives late, so Ana/Marcus remote + Reschedule. — docs/DEMO_WORKSPACE.md (local)

**Co-pilot recording:** explicit team-reported confirmation, deferral, pinned required acknowledgment (blocks confirm/further deferral/item switching; support request, read-only review and correction of the pinned item remain available; acknowledgment leaves the item deferred), corrections with retained events; persists across relaunch. Team remains the recording authority; no inference from ambient conversation. — docs/NATIVE_DEMO_STATUS.md, docs/PRODUCT.md (local)

**Remote Support:** Native iPad (room) ↔ Mac Catalyst (rep) over an encrypted Multipeer session on the same Wi-Fi, requiring Local Network permission and explicit pairing. Late-joining rep receives full read-only room projection (case, checklist, recorded activity) before any question. Contextual questions carry an immutable `SupportContextSnapshot` (case ref, site, device family, template version, selected item, reduced-support flag, checklist lines, recent events, recording revision); live context updates separately and the app counts changed lines vs snapshot. Delivery states are distinct: `onThisDevice`, `waitingForPeer`, `receivedByPeer`, `failed`. Explicit question acknowledgment and reply; messages persisted before send, stable IDs, retry/reconnect replay, receipts. Call invitation needs acceptance, 30-s expiry; WebRTC two-way audio and room-only camera video (rep camera not requested). Owner confirmed on 2026-10-25 that both audio directions and iPad video work; mute, camera toggle/flip, post-call messaging and repeated-call recovery not yet physically verified. — NorthstarOR/Models/SupportExchange.swift, docs/NATIVE_DEMO_STATUS.md (local)
- Checks reported in status doc: 157 unit tests passed, 12 native integration checks, 1 normal-launch UI test, signed Mac and iPad builds. Accessibility (VoiceOver, enlarged text, keyboard, contrast, Reduce Motion) not rechecked for this pass. — docs/NATIVE_DEMO_STATUS.md (local)

**Not implemented (repository's own claim audit):** internet/distant transport; named-rep plan request, acceptance and rescheduling in Planner (PRODUCT.md and DEMO_READINESS.md describe these as intended, but the status doc says NOT implemented); authentication/verified identity ("local role/pairing is not verified identity"); background calls, push notifications and export; hands-free voice commands (parser exists but not wired); computer vision and conversational AI; editing weather in-app; real weather/road data; EHR integration (no patient fields at all). ICD template intentionally blocked. — docs/NATIVE_DEMO_STATUS.md, docs/DEMO_WORKSPACE.md (local)

**Hard rules:** simulated data only (fictional people/facilities/forecasts, in `NorthstarOR/Data/`); app prompts and documents and never makes clinical decisions (no diagnosis, dosing, technique verification or go/no-go); color describes recorded app state, never clinical readiness; device-rep availability ≠ clinical coverage; acknowledging a warning doesn't complete the item; unseen event = unknown. — CLAUDE.md, docs/PRODUCT.md (local)

### Inferences
- Note a doc inconsistency for the report writer: DEMO_READINESS.md and PRODUCT.md script "Ana is requested then explicitly accepts," but NATIVE_DEMO_STATUS.md and DEMO_WORKSPACE.md say plan request/acceptance is NOT implemented. The final report should follow the status doc.
- The matcher's value is explainability, not optimization: it uses static drive minutes and a single closure time, with no traffic, rep calendar, or uncertainty modeling.

### Gaps
- I skimmed DEMO_READINESS.md (first ~80 lines) rather than reading all 206 lines; I did not read PRODUCT_FOUNDATION.md or the Co-pilot source code directly, so Co-pilot behavior is taken from docs.

## B1. Rural hospital connectivity and IT realities

### Takeaway
Rural hospital buildings often have decent broadband (helped by a federally subsidized program whose demand now exceeds its annual cap), but coverage is uneven and in-building enterprise/guest Wi-Fi commonly isolates clients. That could block Northstar's current same-Wi-Fi peer discovery. In any case, a remote rep is by definition not on the hospital LAN, so the current nearby-only transport does not reach the core rural use case.

### Cited Findings
- FCC Rural Health Care (RHC) program FY2026: estimated demand $911.25M vs cap $744,161,841; $226.42M of carried-forward unused funds lets all eligible FY2026 requests be funded without prioritization. FY2025: demand $823.08M vs cap $723,892,841. — [FCC DA 26-562](https://docs.fcc.gov/public/attachments/DA-26-562A1.pdf); [Benton summary](https://www.benton.org/headlines/unused-funds-fully-satisfy-demand-rural-health-care-program-funding-funding-year-2026)
- A CMU study of six rural Michigan counties found the hospitals had high-speed internet while surrounding residents often did not. — [WCMU, 2024](https://www.wcmu.org/local-regional-news/2024-02-15/michigan-rural-hospitals-have-high-speed-internet-but-their-patients-dont-cmu-study-finds)
- In a West Texas analysis, only 57% of rural hospitals had at least one fixed provider offering ≥100 Mbps down (secondary summary). — [Connect With Care](https://connectwithcare.org/broadband-access/)
- Debate on bandwidth needs: Project ECHO authors said HD videoconferencing can work at about 1.5 Mbps; critics said low-bandwidth links are unreliable (secondary summary). — [BBC Mag](https://bbcmag.com/does-poor-broadband-deter-telemedicine-adoption-2/)
- Minnesota: Office of Broadband Development figures in a Dec 16, 2025 House document show about 155,000 locations without 100/20 service (the 2026 state goal), down from 229,000 (Nov 2023) and 291,000 (Nov 2022). — [MN House document](https://www.house.mn.gov/comm/docs/FzFcjzwkkkC7oH4vjTzeSQ.pdf); Ookla-based roundup: rural 100/20 access 56.4% vs urban 74.3% (secondary; method unclear). — [Blandin on Broadband](https://blandinonbroadband.org/category/blandin-foundation/)
- Enterprise Wi-Fi: guest SSIDs in NAT mode isolate clients from each other; Bonjour/mDNS discovery is multicast and confined to a VLAN unless forwarded; discovery can succeed while client-to-client connection still fails. — [Cisco Meraki Bonjour Forwarding](https://documentation.meraki.com/Wireless/Design_and_Configure/Configuration_Guides/Client_Addressing_and_Bridging/Bonjour_Forwarding); [Extreme Networks community thread](https://community.extremenetworks.com/t5/extremecloud-iq-site-engine/bonjour-traffic-airplay/m-p/48561); [Ruckus community](https://community.ruckuswireless.com/discussion/9666/client-isolation-and-bonjour-whitelists)

### Inferences
- Northstar's Multipeer/Local Network design depends on Bonjour-style discovery. On an isolated hospital SSID it would probably need IT configuration or would fail; this is untested. (Apple Multipeer can also use peer-to-peer Wi-Fi/Bluetooth, but I did not verify this against a source in this pass.)
- A rural deployment would need an internet relay (with TURN for WebRTC) and an audio-only/text fallback, since the rep is hours away. The text/snapshot-first design suits low bandwidth well; video is the bandwidth-heavy part.

### Gaps
- No source found measuring OR-specific Wi-Fi quality or hospital IT policies on peer-to-peer apps in rural hospitals.
- No primary FCC Section 706 rural figures retrieved; I skipped the vendor-blog numbers.
- I didn't find an official 2026 statewide Minnesota percentage.

## B2. Privacy / regulatory constraints (HIPAA, recording, FDA)

### Takeaway
A rep can lawfully be in the OR and see PHI incidental to device support, but a software vendor that transmits or stores PHI would usually need a BAA. Since the 2023 end of COVID-era enforcement discretion, video platforms handling PHI need BAAs too. Recording audio/video in the OR raises consent and policy issues. Northstar's current no-PHI, no-recording-of-media design avoids most of this. On the FDA side, coordination/administrative software that doesn't analyze medical data falls outside the device definition, but the CDS guidance was revised in January 2026 and should be checked directly.

### Cited Findings
- HIPAA: a device company that only sells products and does not receive PHI from the covered entity is not a business associate. It becomes one when it handles PHI for services such as technical support (secondary/vendor summaries). — [Wiggin and Dana](https://www.wiggin.com/publication/special-hipaa-business-associate-issues-for-health-care-contractors/); [Accountable HQ (vendor)](https://www.accountablehq.com/post/hipaa-essentials-for-medical-device-sales-reps-entering-the-or-what-matters-most)
- OCR guidance as reported: reps may be present in the OR to support use, implantation, calibration or adjustment of a device (secondary report; primary OCR wording not retrieved). — [MDedge](https://mdedge.com/content/hipaa-regs-permit-consultation-device-manufacturers)
- OCR's COVID telehealth enforcement discretion ended with the PHE (May 11, 2023), with a 90-day transition ending about Aug 9–10, 2023 (sources differ by a day). After that, providers needed BAAs with video vendors handling PHI. — [Haynes Boone](https://www.haynesboone.com/news/alerts/telehealth-and-other-healthcare-providers-reminded-of-health-information-privacy); [HIPAA Journal](https://www.hipaajournal.com/covid-19-phe-ends-may-11-2023/); [Telehealth.org](https://telehealth.org/hipaa-enforcement/)
- OR recording: moving from intracorporeal to full-room audio/video capture raises ethical, legal and social issues that must be addressed (Langerman et al., Annals of Surgery 2023). — [Harvard Law bibliography entry](https://hls.harvard.edu/bibliography/navigating-a-path-towards-routine-recording-in-the-operating-room/). An example institutional policy separates recording that needs written authorization (teaching, QI) from recording for treatment/identification. — [HealthPartners policy](https://www.healthpartners.com/institute/wp-content/uploads/2018/10/photography-video-recording.pdf)
- FDA: the 21st Century Cures Act §520(o)(1) excludes from the device definition functions for administrative support of a facility (scheduling, inventory, workflow, etc.). Functions that analyze or interpret medical data remain devices. FDA can re-assert oversight if a function is reasonably likely to cause serious adverse health consequences. — [FDA guidance PDF (Changes to Existing Medical Software Policies)](https://fda.gov/media/132527/download); [FDA Law Blog](https://www.thefdalawblog.com/2019/10/changes-to-existing-medical-software-policies-resulting-from-section-3060-of-the-21st-century-cures-act/)
- CDS: the 2022 final guidance addressed the four non-device CDS criteria of §520(o)(1)(E): no image/signal analysis; displays/analyzes medical information; supports HCP recommendations; HCP can independently review the basis. — [Crowell & Moring 2022](https://www.crowell.com/en/insights/client-alerts/fda-issues-final-guidance-on-clinical-decision-support-software). FDA's page now lists a **final guidance dated January 2026, content current as of 01/29/2026** (docket FDA-2017-D-6569), so the 2022 version has been superseded. — [FDA CDS guidance page](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/clinical-decision-support-software)

### Inferences
- Northstar has no patient fields and makes no clinical recommendations, so it sits more naturally in administrative/communication software than in CDS. Its matcher ranks logistics (drive time, availability), not clinical options. Adding camera label-reading or AI summaries of case state could move it closer to the CDS or device boundary; that is a regulatory question, not a settled answer.
- The room-camera video stream is the highest privacy-risk feature. A real deployment would need hospital consent/recording policy alignment and a BAA-backed transport; Northstar doesn't record media, which helps.

### Gaps
- AORN's position on OR recording was not found; primary HHS OCR text on reps in the OR was not retrieved.
- I didn't read the full January 2026 CDS revision, so changes vs 2022 are not characterized.
- State consent (e.g., Minnesota) and two-party audio recording laws were not researched.

## B3. Evidence that checklists and structured communication help

### Takeaway
Structured checklists and handoffs have meaningful but contested evidence. The WHO checklist's landmark result (Haynes 2009) was not reproduced in Ontario's mandate (Urbach 2014), likely because of implementation fidelity. I-PASS shows that structured handoffs reduce errors. These support Northstar's "explicit acknowledgment and context" design principle, but none of them validates Northstar itself.

### Cited Findings
- Haynes et al., NEJM 2009: 8 hospitals, before/after (3,733 vs 3,955 patients), 19-item WHO checklist. Death fell 1.5%→0.8% (p=0.003); inpatient complications fell 11.0%→7.0% (p<0.001). Non-randomized. — [Harvard Gazette](https://news.harvard.edu/gazette/story/2009/01/surgical-safety-checklist-drops-deaths-and-complications-by-more-than-one-third/); [PMC 2810011](https://pmc.ncbi.nlm.nih.gov/articles/PMC2810011)
- Urbach et al., NEJM 2014 (Ontario, 101 hospitals, ~109k vs ~106k surgeries, 3 months either side): no significant change. Adjusted complications 3.86%→3.82%, mortality 0.71%→0.65%. Leape's editorial argued the checklist was likely not actually used and 3 months was too short. — [MDedge](https://mdedge.com/familymedicine/article/80926/health-policy/surgical-checklists-failed-improve-outcomes); [Globe and Mail](https://beta.theglobeandmail.com/news/national/surgical-checklists-have-little-effect-on-patient-outcomes-study-finds/article17473716/)
- Starmer et al., NEJM 2014 (I-PASS, 9 pediatric programs, 10,740 admissions): medical errors fell 24.5→18.8 per 100 admissions (23%); preventable adverse events fell 4.7→3.3 (30%); handoff time didn't increase; significant at only 6 of 9 sites. — [AHRQ PSNet](https://psnet.ahrq.gov/resources/resource/28485); [HMS News](https://hms.harvard.edu/news/improved-hospital-handoffs-cut-adverse-events-almost-half)
- Joint Commission Center for Transforming Healthcare hand-off project: hand-offs were defective >37% of the time at participating hospitals, and targeted solutions gave a 52% average reduction in defective hand-offs where fully implemented. The widely cited "~80% of serious errors involve hand-off miscommunication" is attributed to a project lead in secondary press, and I found no primary Joint Commission publication for it. Figures of 50–80%/70% vary by source. — [Relias Media](https://reliasmedia.com/articles/129001-tackling-hand-off-communications); [Healthcare IT News](https://www.healthcareitnews.com/news/joint-commission-confronts-deadly-miscommunications)
- AHRQ TeamSTEPPS handoff guidance emphasizes receiver acknowledgment and the chance to ask questions (already cited in the repo). — [AHRQ](https://www.ahrq.gov/teamstepps-program/curriculum/communication/tools/handoff.html)

### Inferences
- The Ontario result argues against claiming that "digitizing the checklist" improves outcomes. Northstar's honest claim is narrower: it preserves unresolved state and context during a remote handoff.
- I-PASS and the Joint Commission findings ("sender/receiver expectations differ") map directly to Northstar's snapshot + explicit acknowledgment + distinct delivery states.

### Gaps
- No evidence found specifically on device-rep remote handoffs or SBAR in rep–OR communication; I didn't find a primary SBAR outcome study in this pass.

## B4. Weather and road data sources for a real version

### Takeaway
NWS's free API (api.weather.gov) provides alerts and forecasts but has no uptime guarantee, an unpublished rate limit and a history of outages. Minnesota 511 shows closures, but I couldn't confirm a public developer feed. A real version should treat these as advisory inputs with timestamps and fallbacks, which matches Northstar's "unknown is not proof" rule.

### Cited Findings
- api.weather.gov requires a User-Agent (API key planned). The rate limit "is not public information" (retry after about 5 s). The page gives no uptime guarantee; Known Issues (updated 3/24/2026) lists none significant; observations can be delayed up to 20 min by MADIS QC; `/alerts/active?area=MN` returns active alerts; grid mappings can change, so recheck `/points`; outages are announced via NCEP SDM admin messages and weather.gov/notification. — [NWS API documentation](https://www.weather.gov/documentation/services-web-api)
- Outage history: severe reliability problems after a Feb 2020 upgrade (third-party status page). An April 2024 outage of about 6 hours hit NWS dissemination, with a reported uptime goal of 97% for dissemination systems (not specifically the API). — [Singlewire status](https://status.singlewire.com/incidents/hwvj3fnlnvw1); [Nextgov 2024](https://www.nextgov.com/modernization/2024/04/nws-says-partial-circuit-failure-caused-network-outage/395524/); [GitHub weather-gov/api discussion](https://github.com/weather-gov/api/discussions/688)
- MnDOT 511: the app gives near-real-time winter road conditions, incidents and closures. MnDOT integrated automatic road-condition reporting from its Maintenance Decision Support System and modified its API in 2020. — [Minnesota 511 App Store](https://apps.apple.com/app/id664709236); [NASCIO nomination](https://www.nascio.org/wp-content/uploads/2021/08/NASCIO-CBCP-MN-Integrated-Weather-Alert-Data-for-Minnesota-Travelers.pdf)
- Comparable 511 feeds use the CARS platform with request/credentialed XML access (Iowa lists "Minnesota Feeds"). Wisconsin 511 offers a keyed REST API including winter road conditions, throttled to 10 calls/60 s. — [Iowa DOT 511 XML request](https://iowadot.gov/511/XMLRequestForm); [511WI API docs](https://511wi.gov/developers/doc)

### Inferences
- Real integration would replace the fixture `StormForecast` with NWS alerts plus 511 closure events, show "as of" times, and fall back to manual coordinator entry. Road closure is an event, not a forecast, so the matcher's single "closure time" would need to become uncertain or ranged.
- Drive-time estimates would need a routing source; none was researched.

### Gaps
- I couldn't confirm MnDOT's developer feed terms, access process or reliability; I'd need to contact MnDOT/511 directly.
- No routing/drive-time API was evaluated.
