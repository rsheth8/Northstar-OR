# Five-minute demo script

Matches the app at the 10 AM freeze and the sample in [DEMO_WORKSPACE.md](DEMO_WORKSPACE.md). Everything is fictional. Button names are in **bold**; re-check them on the frozen build because Co-pilot and Remote Support screens are still being polished.

**Cast**
- **Rahil** plays **Jordan Ellis**, the coordinator in the Grand Marais room, on the **iPad**.
- **Amartya** plays **Ana Lindqvist**, the device rep in Duluth, on the **Mac**.

The app shows the names Jordan and Ana, so say them. Don't introduce yourselves by your real names in character. The data uses no real people.

## Before you go on (do not show)

1. Within about an hour of presenting, on **both** devices: delete and reinstall the app (or **Start over** if it has merged), then **Load sample workspace**. This starts the blizzard clock, so Planner shows the closure counting down.
2. Pair the devices: **Connect devices → Find Northstar devices → Invite** the other device → accept. Allow Local Network and **Set up microphone** on both. Send one test message and check it arrives, then make sure the iPad shows no leftover test question. If one appears, reset and pair again.
3. Headphones on the Mac. iPad volume up. The rear iPad camera points at something neutral, with no people or screens.
4. iPad on **Planner**; Mac on **Remote Support**.
5. Start the backup screen recording of a full rehearsal run on this same build, and keep it ready.

## Script

### Opening clip (about 0:20)

**Amartya:** "Grand Marais. A small hospital on the North Shore. Later today, a patient is scheduled for a pacemaker procedure, and the device rep who supports it is two hours away, behind a road that's about to close. *(beat)* So what happens when the case starts?"

> Fact check: Duluth to Grand Marais is about two hours. The sample has Ana 110 min away and the road closing 90 min after loading. Say "later today", not "two o'clock": the case is scheduled 8 hours after the sample loads, and Planner shows that time.

### Black slide: the cold call (about 0:25)

**Amartya (as Ana, on the phone):** "Hi, it's Ana, the device rep. Sorry I couldn't make it. Uh, which case is this? Where are you in the checklist? What's still open? What do you need from me?"

**Rahil (as Jordan, flustered):** "Okay, so, um, give me a second…"

### Slide 1 (about 0:20)

**Rahil:** "That's a cold call. Every minute of it is spent catching up instead of helping. This is Northstar. The storm cuts the road. It shouldn't cut the support."

### Demo (about 3:00)

**1. The workspace (0:15) on the iPad.**
**Rahil:** "This is a fictional workspace we set up in the app: our sites, our reps, our cases. No patient data, ever."

**2. Planner shows why the rep is remote (0:30).** Tap **GM-1025**.
**Rahil:** "Here's tonight's case in Grand Marais. Northstar checks who can actually get here: Ana's drive is 110 minutes, the simulated road closes before she arrives, so no one can attend in person. It shows *why*, and it offers Ana remotely, Marcus as a backup, or rescheduling. It never picks for us. The coordinator chooses Ana."
- If coverage requests merged by 10 AM, request Ana (remote) here, and Amartya accepts on the Mac: "Accepted." Otherwise just say "we choose Ana".

**3. Start the case (0:20).** Tap **Start recording**, then go to **Co-pilot**.
**Rahil:** "In the room, I record what the team reports at each step. Northstar doesn't run the procedure or tell the doctor anything; it keeps the record."
Tap **Record confirmation** twice: **Time-out recorded**, then **Device and lead models confirmed**.

**4. The issue (0:20).** On **Programmer and analyzer ready**, tap **Defer item**.
**Rahil:** "Programmer setup is normally the rep's job, and she's not here. I can't confirm it, so I defer it." The amber warning appears: **Deferred · Acknowledgment required**.
**Rahil:** "Northstar won't let us quietly skip past a required step."

**5. Ask for help (0:25).** Open **Request support** (or **Ask about this item**) and type:
"We deferred programmer setup. No rep is on site because of the road closure. Can you walk our staff through connecting the programmer for this fictional device?"
Tap **Send question**.

**6. The rep sees everything (0:30) on the Mac.** The alert shows: "A question is waiting on this case."
**Amartya (as Ana):** "Hi, it's Ana. I haven't asked you anything yet, and I can already see the case, your question, what you've confirmed, and that programmer setup is still open."
Tap **Acknowledge question**, then reply from **Suggested text**: "I can walk your team through the programmer connection screens; the physician directs any programming." Tap **Send reply**. The reply appears on the iPad: **Reply from Ana Lindqvist**.

**7. Live call (0:40).** On either device tap **Request call**; the other taps **Accept call**.
**Amartya (as Ana):** "I can see your room camera. Hold the programmer where I can see the screen… Select the pacemaker device family, then open the analyzer connection screen. Your physician takes it from there."
**Rahil:** "Got it, it's connected." Tap **End call**.

> Keep the call under 45 seconds. Ana hears the room and sees the room camera; her camera isn't used. Don't demo mute or camera flip, which haven't been checked on the real devices yet.

**8. Finish the record (0:30) on the iPad.** On the pinned item tap **Correct record** → team-confirmed → reason "Programmer connected with remote rep guidance" → **Save correction**. The warning clears.
Open **Review items**, select **Lead positioning reported**, and **Record confirmation** through the last item. Co-pilot shows **All team confirmations recorded**.
**Rahil:** "Same call as before. No catching up." Optionally open **Activity**: "And the record keeps the deferral, the question, Ana's reply and the correction, with who and when."

### Closing line (about 0:10)

**Amartya:** "People, ideas and tools meet here. Where they intersect, a cold call becomes a join brief."

### Tech stack slide (about 0:15)

Say only what is in the build:
- **Native SwiftUI app** for iPad (iPadOS 17+) and Mac (Mac Catalyst), one codebase, with Apple Observation for app state.
- **Apple Multipeer Connectivity** for an encrypted, explicitly paired iPad–Mac session over the same Wi-Fi.
- **WebRTC** (open source, via stasel/WebRTC 155) for two-way audio and room-camera video.
- **Local, versioned storage on each device.** Records survive relaunch; nothing goes to a server.
- **An explainable, rule-based coverage matcher** with no AI and no black-box score.
- **MapKit, Speech and AVFoundation** only if the map and voice features are merged and shown.
- XcodeGen and GitHub Actions CI on every change.

**Rahil:** "The storm cuts the road. It shouldn't cut the support. Thank you."

## Lines to change from the earlier draft, and why

| Earlier draft | Say instead | Why |
| --- | --- | --- |
| "This afternoon… two o'clock" | "Later today… when the case starts" | Planner shows the real scheduled time, 8 h after loading |
| "Hi, it's Amartya, the rep" | "Hi, it's Ana, the device rep" | The app shows Ana Lindqvist; the data uses no real people |
| "uses Co-pilot to relay information to the doctor" | "records what the team reports at each step" | Northstar never directs clinical work |
| "request the most available tech rep" | "shows who can get here and why; the coordinator chooses Ana" | It ranks with reasons and never auto-picks |
| "device details are still open" | "programmer setup is still open" | The deferred item is Programmer and analyzer ready, the rep's actual job |
| "Rahil implements fix and keeps going" | Correct record → confirm the rest | Shows the audit trail: deferral and correction both kept |
| "enjoy a proper and successful procedure" | "All team confirmations recorded" | The app records reports; it doesn't verify outcomes |

## If something goes wrong

- **Call doesn't connect:** "We'll stay on messages." The question, acknowledgment and reply already make the point. Skip to step 8.
- **Wi-Fi drops:** messages are saved and retried. Say "it's saved and will send when we reconnect," then reconnect or switch to the backup video.
- **Planner says roads are "already closed":** the sample loaded more than 90 minutes ago. Still high risk, so keep going.
- **Anything else:** play the backup recording and narrate over it.

## Don't say

"Works from anywhere", "saves travel or money", "programs the device", "AI", "verified rep", "live weather", or any feature not merged by 10 AM. If asked about distance: "Today it runs on one network; a real rural deployment needs an internet relay. That's our next build."
