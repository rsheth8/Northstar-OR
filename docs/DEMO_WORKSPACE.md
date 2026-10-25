# Demo workspace: Minnesota blizzard pacemaker scenario

Everything below is fictional and simulated. No real patients, hospitals' data or people.

The demo uses the app's optional sample, loaded through the normal setup screen. It is ordinary workspace data: every case, contact and site can be edited, and new cases work the same way.

## What the sample contains

**Workspace:** Arrowhead Cardiac Coverage (fictional). Room iPad participant: Jordan Ellis, coordinator. On the Mac rep station the participant is the remote technical rep, Ana Lindqvist.

| Site | Town | Simulated weather (relative to when the sample is loaded) |
| --- | --- | --- |
| North Shore Community Hospital | Grand Marais | Blizzard warning, 14 in of snow, shoreline highway closes **90 min** after loading |
| Lakes Regional Medical Center | Bemidji | Light snow, 2 in, roads open |
| Prairie Valley Hospital | Worthington | Ice storm watch, closure possible in 18 h |

| Case | Site | Starts | What it shows |
| --- | --- | --- | --- |
| **GM-1025** Fictional pacemaker case · blizzard coverage | Grand Marais | 8 h after loading | High coverage risk. Ana's 110 min drive arrives after the road closure, so no rep can attend in person. Ana and Marcus can support remotely; Reschedule is offered. |
| WO-1026 Fictional ICD case | Worthington | 26 h | Recording is blocked: there is no supported ICD template. |
| BJ-1026 Fictional pacemaker case · routine coverage | Bemidji | 30 h | A second, independent case for start/resume isolation. |

| Contact | Home base | Notes |
| --- | --- | --- |
| Ana Lindqvist | Duluth | Pacemaker, ICD. 110 min to Grand Marais. Remote capable. |
| Marcus Bell | Minneapolis | Pacemaker. 270 min to Grand Marais. Remote capable. |
| Priya Raman | St. Cloud | ICD only, marked unavailable. |

## Reset before every rehearsal and before presenting

The weather clock starts when the sample is loaded. Load it **shortly before presenting** (within about an hour) so the "arrives after the simulated road closure in N min" reason reads live. After that time the reason reads "simulated roads are already closed", which still shows high risk.

On each device: **Workspace settings → Start over on this device → Remove everything on this device**, then **Load sample workspace**. This also clears rehearsal recordings and messages. Each device clears only its own records.

## Suggested five-minute path

1. **iPad (room):** Planner → **GM-1025**. Read the coverage assessment: blizzard, Ana arrives after closure, remote options, Reschedule.
2. Optional: **New case** to show ordinary case creation at any site.
3. GM-1025 → **Start recording**. In Co-pilot record the first item, then **Defer** a required item. The amber warning persists and the item stays pinned.
4. **Connect devices** on both iPad and Mac (same Wi-Fi, Local Network allowed). Accept the pairing.
5. **Mac (rep, Ana):** Remote Support shows the case, checklist and the deferred item without being told anything.
6. **iPad:** ask a contextual question. **Mac:** acknowledge and reply. The reply appears on the iPad.
7. Optional: **Session and call → Request call**; accept on the other side. Use headphones.
8. **iPad:** acknowledge the deferral (it stays deferred), review activity, then switch to BJ-1026 to show its record is separate.

## Not in the app (do not claim)

Named-rep plan requests and acceptance in Planner, rescheduling, editing the weather in the app, voice commands, internet or distant transport, AI and image interpretation. See [NATIVE_DEMO_STATUS.md](NATIVE_DEMO_STATUS.md).
