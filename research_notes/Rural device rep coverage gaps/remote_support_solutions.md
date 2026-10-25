# Remote / virtual device-rep and OR telepresence support for cardiac rhythm device procedures

Research date: 2026-10-25. About 18 tool calls. Search snippets were followed up with fetches where possible. Items labelled "marketing" are vendor claims, not independent evidence.

## Manufacturer programs: what exists for remote implant support and remote programming, and what is FDA-cleared?

### Takeaway
All four major CRM manufacturers have some form of remote implant support. They range from screen-share only (Boston Scientific Heart Connect) to full remote control of an on-site programmer (BIOTRONIK LiveSupport, Medtronic CareLink 2090 remote session per regional pages). Each one is proprietary and only works with that manufacturer's own programmer and devices. I found no 2024–2026 FDA approval announcement for remote CIED programming during implant, and no first-in-human study identified as such. The strongest evidence is a Chinese randomized controlled trial and a BIOTRONIK usage analysis.

### Cited Findings
**Medtronic**
- Medtronic's CareLink SmartSync Device Manager (an iPad app plus a base station and patient connector) was FDA-approved to program and manage data from Medtronic implanted cardiac devices. It succeeds the CareLink 2090 programmer, which had known cybersecurity weaknesses. The MedTech Dive article ID suggests about 2019, and Becker's gives the announcement as "May 2". Verify the year. — [MedTech Dive](https://www.medtechdive.com/news/medtronic-gets-fda-approval-for-wireless-pacemaker-programmer/554023/); [Becker's](https://www.beckershospitalreview.com/healthcare-information-technology/fda-approves-medtronic-s-ipad-based-remote-pacemaker-programming-system.html)
- Medtronic regional (Philippines) marketing says SmartSync "allows support of implant from the control room" and "enables Bluetooth technology, allowing for programming and testing from a distance during implant", with "screen share support available at implant". It says CareLink 2090 "allows true remote control of implant from anywhere… A local Medtronic device specialist supports a real-time, full programming session from a remote location." This comes from a search snippet and the page later returned 404. Availability varies by country and this is not a confirmed US claim. — [Medtronic PH page (snippet)](https://medtronic.com/ph-en/e/crhf-innovations/managing-patients-remotely.html)
- Medtronic EMEA marketing says a technician "can be at your side connecting remotely, giving you the usual technical and troubleshooting support". It also describes an education program that trains clinic teams to lead implants themselves. — [Medtronic DE patient clinic services](https://www.medtronic.com/de-de/l/e/emea/cardiac-rhythm/managing-your-patients/patient-clinic-services.html)
- Medtronic used GHX's Explorer Surgical platform for remote observation, on-demand expertise and "digital procedural playbooks" during a product launch (ILLUMISITE, which is not CRM). This is a GHX case study from about 2023. The PDF text could not be extracted, so only the snippet is used. — [GHX case study PDF](https://www.ghx.com/media/is0dk10r/medtronic_4xroi_explorer_case_study.pdf)
- MyCareLink Smart Monitor (Nov 17, 2015) was the first app-based remote *monitoring* system for pacemakers. It is for monitoring only, not programming. — [Medtronic news](https://news.medtronic.com/2015-11-17-Medtronic-Announces-FDA-Approval-and-Launch-of-Worlds-First-App-Based-Remote-Monitoring-System-for-Pacemakers?asPDF=1)

**BIOTRONIK**
- BIOTRONIK LiveSupport lets a remote BIOTRONIK device expert interrogate and program CIEDs through a Renamic Neo programmer at the local site. It has two modes: LiveControl, where the remote expert takes control, and LiveView, which is view only. — [Prasad et al., Front Digit Health, Feb 4 2026 (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562)
- Usage from April 2022 to April 2025: 38,943 sessions on 2,831 programmers by 555 users. The peak was 2,295 sessions/month, with about 2,028/month over the last 6 months. Sessions averaged 89/day on weekdays and 14/day on weekends. 93% were LiveControl. — [same](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562)

**Boston Scientific**
- The LATITUDE Programming System (Model 3300) has **Heart Connect**, which shares the programmer screen in real time with remote clinicians or BSC reps "for challenging clinical scenarios" over Wi-Fi, Ethernet or cellular. Public pages describe screen sharing only and do not confirm remote control. — [BSC LATITUDE Programming System](https://www.bostonscientific.com/en-US/products/remote-patient-monitoring/LATITUDE-programming-system.html); [connectivity](https://www.bostonscientific.com/en-US/products/remote-patient-monitoring/LATITUDE-programming-system/connectivity.html)
- The **LATITUDE Consult** System is a read-only remote device check, providing "technical review and documentation… without needing to wait for a Boston Scientific representative or programmer". Marketing cites a study in which a device expert was not needed in person 90% of the time. — [BSC LATITUDE Consult](https://www.bostonscientific.com/en-US/products/remote-patient-monitoring/LATITUDE-Consult-System.html)
- BSC owns its US CRM programmers (3120/3200/3300), Consult communicators and Heart Connect systems. — [BSC programming system brief](https://www.bostonscientific.com/en-US/products/remote-patient-monitoring/LATITUDE-Programming-System-Brief-Summary.html)
- The LUX-Dx insertable cardiac monitor supports remote programming. In real-world data, 24% of devices were reprogrammed and 82% of those reprogramming events were remote. This is an ICM, not a pacemaker or ICD at implant. — [PMC9721296](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9721296/); [NCT04732728](https://clinicaltrials.gov/study/NCT04732728)

**Abbott**
- In China, a randomized trial used Abbott/St. Jude Merlin PCS Model 3650 programmers linked to a research 5G cloud platform for remote parameter testing during implant (see Evidence). — [Xiong et al., Front Cardiovasc Med 2024](https://www.frontiersin.org/journals/cardiovascular-medicine/articles/10.3389/fcvm.2024.1364940/full)
- Abbott's FDA-approved remote *programming* product, NeuroSphere Virtual Clinic (launched Mar 2021), is for **neuromodulation** (DBS, SCS), not cardiac devices. — [MedCity News](https://medcitynews.com/2021/03/fda-approval-brings-remote-programming-for-abbotts-deep-brain-stimulation-device/); [Fierce Biotech](https://www.fiercebiotech.com/medtech/abbott-launches-virtual-clinic-for-its-neuromodulation-devices)
- Abbott's Bluetooth-connected pacemakers and ICDs work with the myMerlinPulse app for remote monitoring. — [Fierce Biotech](https://www.fiercebiotech.com/medtech/fda-approves-abbott-s-bluetooth-connected-pacemaker-defibrillator-implants)
- Abbott is running an NSR study of the AVEIR leadless pacemaker Remote Care System, which covers follow-up, not implant. — [NCT06542133 listing](https://decentrialz.com/clinical-trials/NCT06542133/aveir-remote-care-system-non-significant-risk-study)

**Studies and trials in progress**
- NCT05366660, "Remote Programming of CIED": a single-arm multicenter feasibility study, 110 patients, interrogation and programming. The record page did not render, so the details come from a search snippet. — [ClinicalTrials.gov](https://clinicaltrials.gov/study/NCT05366660)
- NCT06404021, "Electronic Device Implantation Through Remote Guidance": a 3-phase program (simulation, phantom, then RCT) for remotely guided ICD/CRT-D implant, with 30 patients randomized 2:1. Snippet only. — [ClinicalTrials.gov](https://clinicaltrials.gov/study/NCT06404021)

### Inferences
- Remote programming during implant is real and in use today, but it is siloed by manufacturer, tied to that manufacturer's programmer hardware, and run by the manufacturer's own staff. A hospital using several manufacturers has several separate remote channels.
- Even where remote control exists, the on-site person still has to set up the programmer and wand or connector. Remote programming moves the rep's keystrokes, not their hands.
- A hackathon coordination app should not claim to program or interrogate devices. It can sit *alongside* these manufacturer channels as a neutral coordination layer.

### Gaps
- I could not confirm the exact FDA regulatory basis (PMA supplement numbers) for remote-session programming during implant in the US, or whether Medtronic's remote 2090 session or BIOTRONIK LiveSupport is US-cleared. The LiveSupport paper's authors include US-based BIOTRONIK staff, but the paper's geography was not confirmed. I found no 2024–2026 FDA approval news for remote CIED programming.
- I found no source explicitly labelled a "first-in-human" remote CIED programming study. The earliest reports are COVID-era case series: Long et al., 3 patients, cited in the PMC paper above.
- Medtronic US program names for remote implant support (e.g., any "virtual case support" brand) were not found on public pages.

## OR telepresence companies: what they provide, adoption, outcomes

### Takeaway
General OR telepresence platforms focus on video and audio, with annotation. Explorer Surgical adds procedural playbooks. The best-funded rep-focused player, Avail Medsystems ($125M raised), shut down abruptly in November 2023. That is a meaningful signal about the business model. Public outcome data on rep travel avoided or case coverage is essentially absent and mostly comes from vendors.

### Cited Findings
- **Avail Medsystems:** The OR console had two pan/tilt/zoom cameras (one on an arm), a 32" monitor, a touchscreen showing available remote users, remote camera control from iPad or PC, and annotation on live or paused video. Consoles were free to hospitals, with a subscription charged to medtech companies. It raised $100M Series B (Oct 2020, about $125M total) and planned up to 1,000 consoles. Smith & Nephew was an early customer. The article says nothing about scheduling or credentialing, and gives no travel or time metrics. — [MedTech Dive, Oct 8 2020](https://www.medtechdive.com/news/avail-medsystems-raises-100m-medtech-reps-remotely-oversee-surgeries/586636/)
- Avail marketed support for remote accounts, emergent cases, physician training, and specialties including EP and cardiovascular. This is marketing. — [MedTech Dive sponsored](https://www.medtechdive.com/spons/with-remote-collaboration-technology-busy-device-representatives-can-be-t/609098)
- Avail **shut down abruptly on about Nov 2, 2023** after failing to close a new funding round. — [MassDevice](https://www.massdevice.com/avail-medsystems-abruptly-shuts-down/); [MD+DI](https://www.mddionline.com/digital-health/from-slaying-to-slayed-avail-abruptly-shuts-down)
- **Explorer Surgical (GHX):** Procedural playbooks, telementoring and performance tracking. HIPAA-compliant two-way video for remote case support and proctoring was added in 2020. GHX acquired it in October 2021. Pega Medical (pediatric orthopedics) adopted it in March 2022 so reps could coordinate when not on site. — [Becker's ASC](https://www.beckersasc.com/orthopedics-tjr/explorer-surgical-launches-new-remote-case-support-features/); [MassDevice](https://www.massdevice.com/pega-medical-picks-explorer-surgicals-digital-case-support-platform/); [GHX release 2022](https://www.ghx.com/news-releases/2022/explorer-surgical-a-ghx-company-chosen-by-pediatric-orthopedic-medical-device-innovator-to-support-surgical-workflow-and-remote-case-management/); [Dealroom](https://app.dealroom.co/companies/explorer_surgical)
- **Proximie:** Olympus distributes it. Up to 4 simultaneous low-latency feeds, plus annotation and chat. A market report says it had supported more than 100,000 procedures across more than 800 hospitals as of June 2025; that number traces back to the vendor. It is moving into ambient OR data capture and analytics. — [Olympus UK](https://www.olympus.co.uk/medical/en/Products-and-solutions/Products/Product/Proximie.html); [Proximie blog](https://www.proximie.com/blog/from-records-to-real-time-how-proximie-orchestrates-the-operating-room)
- **Rods&Cones:** Surgeon-worn smart glasses plus "cORe", a pole-mounted PTZ camera with touchscreen. An interventional cardiology use at Borea Hospital, Sanremo, Italy (Mar 2024) streamed angiograph and ultrasound feeds over a call, with remote annotation drawn onto the glasses. It was used for education, with proctoring planned. No checklist or case data is mentioned. The source is the vendor's site. — [Rods&Cones Borea](https://rods-cones.com/smart-glasses-in-the-operating-room-innovative-cardiology-at-borea-hospital/); [FAQ](https://rods-cones.com/frequently-asked-questions/)
- **Caresyntax:** A surgical-intelligence and data platform, not telepresence. A 2025 industry guide says it serves about 30,000 surgical professionals in more than 3,500 ORs. — [IntuitionLabs guide](https://intuitionlabs.ai/articles/surgical-ai-companies)
- Remote device-technician support via smart glasses was reported for CIED implants in Turkey (2022 letter). An encrypted link connected staff wearing glasses to a technician at the device company. — [Balkan Med J 2022](https://balkanmedicaljournal.org/pdf.php?id=2431) (the full text could not be fetched; details are from the search snippet)

### Inferences
- The telepresence category has converged on video, audio and annotation. Explorer Surgical is the one notable player that adds structured procedural playbooks, and it targets orthopedic and launch workflows, not CRM.
- Avail's failure suggests that a hardware-heavy model, where device makers pay subscriptions for consoles, struggled after COVID. A lightweight, software-only coordination tool on hardware hospitals already own (iPads) is a defensible contrast.

### Gaps
- I found no public pricing for Proximie, Rods&Cones or Explorer Surgical, and no confirmed CRM or EP deployments for any of them.
- I did not research InTouch/Teladoc, Ocutrx or rep-credentialing integrations (Vendormate, Symplr, etc.) and found nothing on them, so they are not covered.
- I found no independent outcomes data (rep travel avoided, cases covered, CO2) for any telepresence platform.

## Evidence: virtual rep support for pacemaker/ICD implants and checks

### Takeaway
The best independent evidence is one single-center RCT (n=480, China, 2024). It found remote parameter testing during CIED implant was non-inferior, with the same procedure time and far fewer door openings. The largest real-world dataset (BIOTRONIK, about 39k sessions) is manufacturer-authored and based on satisfaction surveys. I found no study quantifying rep travel avoided, cost or CO2.

### Cited Findings
- **Xiong et al. 2024 RCT** (Chengdu, Apr 2022–May 2023, ChiCTR2200057587): 480 patients receiving Abbott CIEDs, mostly pacemakers, randomized 1:1 to remote vs. routine parameter testing.
  - Completion was 100% in both groups, meeting non-inferiority.
  - Sensing, threshold and impedance did not differ.
  - Procedure time (102 vs 100 min), testing time (39 vs 35.5 min) and fluoroscopy did not differ.
  - Door openings: median 0 vs 6 (p<0.0001).
  - No complications in the remote group.
  - Setup: a Merlin 3650 programmer connected by USB to a 5G module, plus a cloud service and real-time A/V with on-site staff. Security: RSA/AES, two-step login, recorded sessions. Settings revert if the link drops.
  - Limitations: single center, few ICD/CRT, no follow-up, Abbott-only, and it is a research platform.
  - — [Front Cardiovasc Med, Mar 22 2024](https://www.frontiersin.org/journals/cardiovascular-medicine/articles/10.3389/fcvm.2024.1364940/full)
- **Prasad et al. 2026 (BIOTRONIK LiveSupport):** Retrospective analysis.
  - Surveys: 159 patients, 92 clinicians, 7 BIOTRONIK reps.
  - Staff *estimated* more than 60 minutes saved per patient in 78% of sessions. No adverse outcomes were reported.
  - Remote-site providers gave "mixed" answers on preferring LiveSupport over an in-person rep.
  - Limitations: four authors are BIOTRONIK employees. Time was estimated, not measured. Connectivity interruptions were not tracked. IT restrictions and poor cellular coverage hindered setup. Efficacy measures were not assessed.
  - — [PMC12914562](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562); [Frontiers](https://www.frontiersin.org/journals/digital-health/articles/10.3389/fdgth.2025.1684695/full)
- COVID origin: remote programming was introduced to reduce exposure. Long et al. reported 3 patients programmed from outside the room. Ploux et al. reported 115 patients programmed remotely at varying distances with no complications. Both are as cited in Prasad et al. — [PMC12914562](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562)
- Medtronic marketing frames remote implant support as reducing PPE use and direct patient contact. — [Medtronic PH (snippet)](https://medtronic.com/ph-en/e/crhf-innovations/managing-patients-remotely.html)

### Inferences
- The evidence supports *feasibility and safety of remote parameter testing* when trained on-site staff are present. It does not support replacing on-site staff or reps entirely.
- Fewer door openings is the cleanest objective benefit (an infection-control proxy), but infection itself was not measured.

### Gaps
- I found no peer-reviewed data on rep travel miles, cost per case, CO2 avoided or case-coverage rates for rural CRM implants.
- I found no US multicenter RCT of remote implant support.

## Limitations: bandwidth, IT/security, privacy, physical tasks, liability, regulation

### Takeaway
The documented limitations are connectivity and IT restrictions, manufacturer lock-in, and the need for trained on-site staff. Cybersecurity is a known concern for programmers. Liability and HIPAA analyses specific to remote CIED reps were not found in this pass.

### Cited Findings
- IT restrictions and poor cellular connectivity can hinder LiveSupport setup. The tool only works with Renamic Neo and BIOTRONIK devices. — [PMC12914562](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562)
- The 5G platform needed carrier infrastructure (China Telecom) and multilayer security, and is limited to Abbott. — [Xiong 2024](https://www.frontiersin.org/journals/cardiovascular-medicine/articles/10.3389/fcvm.2024.1364940/full)
- The CareLink 2090 programmer "has been dogged by cybersecurity weaknesses". — [MedTech Dive](https://www.medtechdive.com/news/medtronic-gets-fda-approval-for-wireless-pacemaker-programmer/554023/)
- Medtronic EMEA runs training so clinic teams can lead implants themselves, which implies on-site competence is the real constraint. — [Medtronic DE](https://www.medtronic.com/de-de/l/e/emea/cardiac-rhythm/managing-your-patients/patient-clinic-services.html)
- Explorer Surgical emphasized "HIPAA-compliant" video, which suggests privacy is a buying criterion. — [Becker's ASC](https://www.beckersasc.com/orthopedics-tjr/explorer-surgical-launches-new-remote-case-support-features/)

### Inferences
- In all cases a person on site has to place the wand or connector and set up the programmer. That person needs a clear, shared view of what step they are on and what the remote expert needs.

### Gaps
- I found no sources on rep liability, state or federal rules on remote rep presence, OR video consent policies, or measured OR bandwidth in rural hospitals.

## Context gap: what does a remote rep see when joining?

### Takeaway
Every system documented here gives the remote party *video, audio, annotation and/or the programmer screen*. None of the CRM sources describe sharing structured case status, checklist progress or deferred items with the remote rep. Explorer Surgical's playbooks are the only structured-workflow precedent, and they are not CRM-specific. No source explicitly names a "context gap". This is an inference, not a documented finding.

### Cited Findings
- Avail: cameras, monitor, annotation, and a list of available remote users. No scheduling or credentialing is mentioned. — [MedTech Dive 2020](https://www.medtechdive.com/news/avail-medsystems-raises-100m-medtech-reps-remotely-oversee-surgeries/586636/)
- BSC Heart Connect: programmer screen share. — [BSC](https://www.bostonscientific.com/en-US/products/remote-patient-monitoring/LATITUDE-programming-system.html)
- BIOTRONIK LiveView/LiveControl: programmer view or control. — [PMC12914562](https://pmc.ncbi.nlm.nih.gov/articles/PMC12914562)
- Xiong 2024: programmer link plus real-time A/V with on-site staff. — [Frontiers](https://www.frontiersin.org/journals/cardiovascular-medicine/articles/10.3389/fcvm.2024.1364940/full)
- Rods&Cones and Proximie: video feeds, annotation, chat. No checklist or case data is mentioned. — [Rods&Cones](https://rods-cones.com/smart-glasses-in-the-operating-room-innovative-cardiology-at-borea-hospital/); [Olympus Proximie](https://www.olympus.co.uk/medical/en/Products-and-solutions/Products/Product/Proximie.html)
- Explorer Surgical: "digital procedural playbooks" alongside video. — [GHX/Medtronic case study](https://www.ghx.com/media/is0dk10r/medtronic_4xroi_explorer_case_study.pdf); [OrthoWorld](https://www.orthoworld.com/?p=40594)

### Inferences
- Honest positioning: Northstar should not compete on video or device programming. Manufacturers and telepresence vendors already do those. Its opening is a manufacturer-neutral, structured case context (case status, current step, deferred items and acknowledgments, who has been contacted and who accepted) that a remote rep or coordinator can read the moment they join. Today that context comes from voice conversation.
- Avail's shutdown and the lack of public outcome data mean claims like "reduces rep travel X%" cannot be backed with external evidence and should be avoided.

### Gaps
- I found no documented user research or survey quantifying how remote reps get oriented when joining a case. A literature search on "situational awareness" or "handoff" in telementoring could fill this gap.
