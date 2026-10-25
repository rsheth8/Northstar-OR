# Demo workspace: Minnesota blizzard pacemaker scenario

Everything below is fictional and simulated: no real patients, hospital data or people. Hospital names are invented; towns, coordinates and approximate distances are real public geography so the map and travel story are believable.

The demo uses the app's optional sample, loaded with **Load sample workspace** on the setup screen. It is ordinary workspace data. Every case, contact, site and weather record can be edited, and new cases work the same way.

## What the sample contains

**Workspace:** Arrowhead Cardiac Coverage (fictional). The room iPad participant is Jordan Ellis, coordinator. On the Mac rep station the participant is Ana Lindqvist, technical rep, so her acceptance and replies carry her name.

### Sites

| Site (fictional) | Town | Coordinates | Simulated weather (hours relative to loading the sample) |
| --- | --- | --- | --- |
| North Shore Community Hospital | Grand Marais | 47.75, −90.33 | Blizzard. 14 in of snow, peaking at 1.8 in/h around hours 3–4; sustained wind about 36 mph from hour 1 to 8; 18 °F falling to about 8 °F. Shoreline highway closes at **+90 min**. |
| Lakes Regional Medical Center | Bemidji | 47.47, −94.88 | Light snow tomorrow, 2 in over hours 20–27, roads open (no closure recorded). |
| Prairie Valley Hospital | Worthington | 43.62, −95.60 | Ice storm watch. Temperatures near freezing, 1 in of snow, road closure at **+18 h**. |

Each site has hourly fictional samples (snowfall, temperature, wind) from 1 h before to 36 h after loading, with an issue time, a valid window and an exact closure time. The source is labeled "Northstar fictional weather scenario (simulated, not a forecast)". The Coverage Matcher, weather views and reports read the same record. Editing it in the app saves revision 1.

### Cases

| Case | Site | Starts | What it shows |
| --- | --- | --- | --- |
| **GM-1025** Fictional pacemaker case · blizzard coverage | Grand Marais | +8 h | **High** coverage risk. Ana's 110 min drive arrives after the road closure, so nobody can attend in person. Ana and Marcus can support remotely, and Reschedule is offered. |
| WO-1026 Fictional ICD case — recording unavailable | Worthington | +26 h | **Elevated** risk because the simulated roads close during the case window. Recording is blocked because no ICD template is supported, which shows the app refusing content it doesn't have. |
| BJ-1026 Fictional pacemaker case · routine coverage | Bemidji | +30 h | **Low** risk; Ana can attend in person. A second independent case for start/resume isolation. |

### Contacts (all technical reps)

| Contact | Home base | Skills | Drive to Grand Marais / Bemidji / Worthington | Notes |
| --- | --- | --- | --- | --- |
| Ana Lindqvist | Duluth | Pacemaker, ICD | 110 / 200 / 390 min | Available, remote capable |
| Marcus Bell | Minneapolis | Pacemaker, neurostimulator | 270 / 225 / 180 min | Available, remote capable |
| Priya Raman | St. Cloud | ICD, insulin pump | 300 / 150 / 210 min | Marked unavailable; not qualified for pacemaker |

## Why this is realistic

Sources are in [the research report](../reports/Rural%20device%20rep%20coverage%20gaps.md).

- **Grand Marais is a real access problem.** The real town's hospital is a 16-bed critical access hospital, "the only hospital for 80 miles", with medevac transfers to Duluth several times a week. Duluth is the nearest regional hub, about two hours' drive along the shore, which matches Ana's 110 minutes. Our hospital and people are fictional.
- **The rep role matches policy.** HRS says reps run their company's equipment only at a physician's request and direction, and names distance as a reason remote support is allowed. The app ranks logistics and records team statements; it never makes clinical decisions.
- **Weather matches how hospitals react.** Upper Midwest health systems reschedule elective procedures in winter storms. A blizzard is about 35 mph or more sustained wind with heavy blowing snow, which the North Shore scenario reflects.
- **Remote rep support is real practice.** During COVID, Abbott told hospitals to have staff run checks while a rep coached by phone or video. Manufacturer remote programs exist today but share video and screens, not the case's checklist state. That missing context is what Northstar's brief adds.

**Say "fictional, representative scenario".** No documented case of a blizzard stranding a device rep was found, so don't present GM-1025 as a true story. A real 16-bed critical access hospital would more often need rep help for a patient who already has a device than for a new implant. The case title stays generic for that reason.

## Co-pilot checklist (fictional pacemaker coordination, version 2)

Each item records what the team **reports** at a coordination milestone. It follows the WHO time-out and sign-out pause points plus the technical steps a device rep normally supports: confirming device and lead models, running the programmer, taking lead measurements and the final interrogation. Northstar never enters values, judges results or tells anyone what to do.

| # | Item | Normally rep-supported | Good item to defer in the demo |
| --- | --- | --- | --- |
| 1 | Time-out recorded | No | |
| 2 | Device and lead models confirmed | Yes | |
| 3 | Programmer and analyzer ready | Yes | **Yes**: no rep on site, so the team can't confirm who runs the programmer |
| 4 | Lead positioning reported | No | |
| 5 | Lead measurements documented | Yes | |
| 6 | Leads connected to device | Yes | |
| 7 | Final interrogation documented | Yes | |
| 8 | Sign-out and handoff | No | Device ID card details: about 45% of device patients arrive without the card |

All eight are required, so deferring any of them raises the pinned acknowledgment warning. Cases saved with the older version 1 wording show "Recording unavailable", and their data is kept unchanged. Reset demo devices before rehearsing.

## Reset before every rehearsal and before presenting

The weather clock starts when the sample is loaded:

- **Load it within about an hour of presenting.** The "arrives after the simulated road closure in N min" reason then reads live.
- **After 90 minutes** the reason changes to "simulated roads are already closed". Risk still shows as high.
- **After 6 hours** the weather evidence counts as stale, like any old forecast.

To reset a device, delete and reinstall the app, then **Load sample workspace**. A **Start over on this device** action exists in the app model and will be added to Workspace settings after the shell and forms work merges. Each device keeps only its own records.

## Demo text to use

- **Defer in Co-pilot:** record item 1 (Time-out recorded) and item 2, then defer item 3, **Programmer and analyzer ready**.
- **Team question (iPad):** "We deferred programmer setup. No rep is on site because of the road closure. Can you walk our staff through connecting the programmer for this fictional device?"
- **Rep replies (Mac, Suggested text menu):** "Received. I can see the case brief and the deferred item." then "I can walk your team through the programmer connection screens; the physician directs any programming." Other options: "Please read me the model and serial number from the device packaging…" and "I'm supporting remotely. Please keep a team member at the programmer."
- **Voice phrases (when the voice branch merges):** "record confirmation", "defer item", "acknowledge deferral", "open planner", "open co-pilot", "show unresolved items", "stop listening".

## Five-minute path

The full script with lines, timing, setup and fallbacks is in [DEMO_SCRIPT.md](DEMO_SCRIPT.md). In short: pair the devices beforehand → Planner, GM-1025 (why Ana can't drive in) → **Start recording** → confirm items 1–2 → defer item 3 → send the question → Ana already sees the case and acknowledges and replies → live call → **Correct record** on item 3 → confirm the rest → "All team confirmations recorded".

## Do not claim

Live weather or road data, internet or distant connection ("works from anywhere"), travel or cost savings, device programming, verified identity, AI or image interpretation, or anything not merged by the 10 AM freeze. See [NATIVE_DEMO_STATUS.md](NATIVE_DEMO_STATUS.md).
