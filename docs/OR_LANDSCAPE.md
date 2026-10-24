# Northstar OR: how an OR runs and what tools exist

Research date: **2026-10-24**. This is background for product and pitch decisions. It records public sources; it is not clinical guidance and not evidence that Northstar works. Points marked *(background)* are general domain knowledge that no source below confirms. Verify those with an OR nurse or device rep before using them on a slide.

Most efficiency figures in this space are vendor-reported. Do not present them to judges as independent results.

## 1. How a case runs in real time

### The people in the room *(background)*

| Role | Job during the case |
| --- | --- |
| Surgeon / proceduralist | Makes every clinical decision |
| Anesthesia (anesthesiologist or CRNA) | Airway, sedation, vital signs |
| Circulating nurse | Non-sterile room coordinator: documents, fetches supplies, makes calls, usually runs the checklist |
| Scrub tech | Sterile; instruments and counts |
| Device rep (device cases) | Technical support for the manufacturer's product only |

### The timeline

Perioperative systems record a case as a sequence of milestones, for example: room set up → patient in room → induction → positioning and prep → time-out → incision → closing → dressing → patient out → room cleaned ([milestone list, patent filing](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10721333)).

Definitions are not standardized. Anesthesia, nursing and surgeons can read the same timestamps differently ([UCSF turnover study](https://open-proposals.ucsf.edu/sites/default/files/chv/cw-projects-2024/1677821080/or_start_times_and_turnover_times.pdf)). One study reported average turnover between cases of 31 minutes, ranging from 8 to 60 ([BMC Medical Education, 2018](https://pmc.ncbi.nlm.nih.gov/articles/PMC6280448)).

### The checklist's three pause points

| Phase | When | Often led by |
| --- | --- | --- |
| Sign In | Before anesthesia starts | Anesthesia |
| Time Out | After induction, before incision | Surgeon |
| Sign Out | At or after closure, before the patient leaves | Circulating nurse |

WHO asks one person to coordinate the whole checklist and confirm each phase is complete before the case moves on. That person is often the circulating nurse ([WHO checklist](https://www.caho.in/files/WHO-Surgical-safety-checklist.pdf), [NZ HQSC](https://www.hqsc.govt.nz/our-work/improved-service-delivery/safe-surgery-nz/projects/surgical-teamwork-and-communication/interventions/surgical-safety-checklist/), [WA Country Health policy](https://www.wacountry.health.wa.gov.au/~/media/WACHS/Documents/About-us/Policies/Surgical-Safety-Checklist-Policy.pdf?thn=0)). Phase leaders vary by health system.

### The device rep in a pacemaker case

- Industry-employed allied professionals give technical help during pacemaker/ICD implant, programming, troubleshooting and follow-up. The physician is responsible for assessing programming and for recommending what to do about a malfunction ([HRS policy](https://hrsonline.org/documents/2022-hrs-ieap-policy-updatepdf/download)).
- *(Background)* In practice this usually means running the manufacturer's programmer, taking lead measurements and confirming device and lead models.
- Reps should be present only to provide assistance; hospital staff own device training ([ECRI](https://www.ecri.org/search-results/member-preview/hrc/pages/edutrain5/)). Liability can arise if a rep exercises medical judgment ([AMA Journal of Ethics](https://joe-prod.ama-assn.org/sites/joedb/files/2018-06/hlaw1-1002.pdf)).
- This supports the Northstar rule that the app prompts and documents and never makes clinical decisions, and that rep availability is not clinical coverage.

### The rural coverage problem

- Device sales forces have not grown with demand. Reps cover territories hours apart and cannot attend every case in person ([PSQH](https://psqh.com/analysis/advice-from-afar-how-remote-access-enables-medical-device-representatives-to-work-with-clinicians)).
- AdvaMed-linked guidance urges reps to support remotely where possible ([AdvaMed / WLF backgrounder](https://www.advamed.org/wp-content/uploads/2017/04/medical_device_makers_representatives_in_the_o.r._patient_care_benefits_and_legal_ramifications.pdf)).
- No independent data was found on how many rural US hospitals use remote rep support.

## 2. Existing tools

| Category | Examples | What they do | What they leave open |
| --- | --- | --- | --- |
| OR scheduling and status boards | Epic OpTime, LiveData OR-Schedule Board, Cerner tracking board, SIS Charts Tracker | Suite-wide displays of room status and case milestones ([Mindbowser comparison](https://www.mindbowser.com/epic-optime-vs-other-or-management-systems-a-comparative-guide/), [LiveData at MGH](https://www.psqh.com/news/massachusetts-general-hospital-expands-use-of-livedata-periop-manager-with-or-schedule-board), [Western Health tracking board](https://digitalhealth.wh.org.au/wp-content/uploads/2023/06/Perioperative-Tracking-Board.pdf)) | They track the patient and room, not the support plan or the rep |
| Rep scheduling and credentialing | Torq, Casechek, O.R. TRAX, GHX Vendormate, symplr | Pair reps with cases, notify schedule changes, handle credentials and badge check-in ([Torq](https://apps.apple.com/us/app/-/id1439819022), [Casechek](https://www.casechek.com/procurement/), [O.R. TRAX case study](https://ortrax.com/wp-content/uploads/2025/05/PR-3_-ASC-Case-Study.pdf), [NYU Langone Vendormate guide](https://nyulangone.org/files/vendormate-credentialing–guide.pdf)) | No source showed ranked backup options when the usual rep is unavailable, or separate request / acceptance / connection states |
| Remote rep support and telepresence | Proximie, Avail (shut down; technology acquired by Mendaera in 2024), Teladoc | Live OR video to remote experts ([Mendaera acquisition](https://www.businesswire.com/news/home/20240319468469/en/Mendaera-Acquires-Avail-Medsystems-Telepresence-Technology), [Avail shutdown](https://www.massdevice.com/avail-medsystems-abruptly-shuts-down/), [Teladoc and Proximie](https://www.emarketer.com/content/teladoc-expands-ar-enabled-virtual-surgery-support-via-proximie-partnership)) | Hardware and bandwidth requirements; Avail's shutdown shows the risk of console-heavy models |
| Ambient OR AI and computer vision | Proximie Intelligence Suite, Apella, caresyntax, VitVio | Camera-based milestone logging and delay flags. Proximie announced a 104-theatre NHS evaluation (Sept 2026) and a 44-room UC San Diego deployment ([Proximie, AWS and NHS](https://press.aboutamazon.com/2026/9/global-healthtech-proximie-in-collaboration-with-aws-deloitte-and-the-nhs-launches-largest-nhs-ai-theatre-evaluation-to-unlock-hidden-operating-theatre-capacity), [Proximie and NVIDIA](https://mobile.hospimedica.com/business/articles/294809864/proximie-advances-ai-driven-intelligent-operating-rooms-with-nvidia-collaboration.amp.html), [Apella](https://www.imveurope.com/article/apella-raises-80m-scale-operating-room-computer-vision), [VitVio](https://tech.eu/2026/10/14/vitvio-brings-ai-powered-surgical-operating-system-to-poland-in-uck-gdansk-partnership/)) | Aimed at large centers and throughput, not small rural teams |
| Clinical messaging | TigerConnect, Vocera, Voalte | Role-based secure messaging and EHR notifications, including OR turnover workflows ([TigerConnect OR workflows](https://tigerconnect.com/?p=4472), [UConn messaging policy](https://health.uconn.edu/graduate-medical-education/wp-content/uploads/sites/20/2025/01/Secure-Electronic-Messaging.pdf)) | Some products provide patient context (for example, [TigerConnect](https://tigerconnect.com/products/clinical-collaboration-platform/)). These sources do not establish the combined coverage-plan, recorded-checklist and explicit question-acknowledgment handoff proposed here; that is a research gap, not proof competitors lack it. |
| Digital checklists | In-room electronic time-out; smart-glasses checklist study | One study reported completion rising from 76% to as high as 100% with a Google Glass app; an electronic time-out was documented within 2 minutes 97% of the time ([JMIR mHealth 2019](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6658283/), [Rothman et al. 2016 record](https://busqueda.bvsalud.org/portal/resource/es/mdl-27272671)) | Small, single-site evidence; no link from checklist state to a support request |

## 3. Implications for Northstar

These are hypotheses for product and pitch work, not validated findings.

1. **The gap is the hand-off when the usual rep can't attend.** Existing tools cover rooms, rep schedules or video separately. None found connects the coverage plan, the team's recorded checklist state and a context-carrying request that the rep explicitly acknowledges. This fits the *Connect & Intersect* prompt.
2. **Use the WHO phases as shared vocabulary.** Sign In, Time Out and Sign Out, coordinated by the circulator, are terms Medtronic judges will recognize. Northstar's template content still needs workflow-specific review (see PRODUCT.md).
3. **The circulating nurse is the main in-room user.** They are non-sterile, already coordinate the checklist and already handle calls. This supports large touch targets, optional voice and short alerts.
4. **Position Northstar as lightweight.** An iPad-only, low-bandwidth coordination tool contrasts with console telepresence and suite-wide camera systems. Do not claim it has been tested in a rural OR.
5. **Keep the role boundary explicit.** HRS and ECRI language supports showing rep support as technical, and keeping availability, acceptance and clinical coverage distinct.

## 4. Open questions

- No source showed a rural OR team or a cardiac device rep describing this hand-off in their own words. A short conversation with a field clinical engineer or OR nurse at the event would test the core assumption.
- Confirm the *(background)* role and pacemaker-workflow points above before presenting them.
- Read the full Rothman et al. paper before citing any wrong-site outcome result.
