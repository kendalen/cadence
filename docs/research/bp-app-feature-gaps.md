# BP tracker apps — most-wanted, most-ignored features

Research notes for Cadence's roadmap. Gathered 2026-08-24 via `/last30days`
(Reddit health subs + HN + YouTube) plus web search and the JMIR/PMC
home-BP-monitoring literature.

**Caveat on strength of evidence:** the 30-day social window was thin and
skewed toward medical anxiety posts ("is 160/110 normal?"), not app critique.
Treat the ranking below as *durable pattern + light fresh confirmation*, not a
hard vote count. The strongest signals come from web reviews and the clinical
literature, not the fresh Reddit pull.

---

## The feature gaps (ranked by how requested + how ignored)

1. **Free data export + backup that isn't paywalled.**
   The clearest documented complaint: users type in hours of history, then find
   analysis/export locked behind a purchase, with no way to get their data out.
   Export lock-in is the corner cheap apps deliberately cut.
   → Cadence already covers this: versioned JSON backup + CSV/PDF export.

2. **Privacy / offline-first, no account.**
   Strong enough pull that people build their own (see the r/QuantifiedSelf post
   below). Off-the-shelf apps force accounts, subscriptions, cloud upload of
   sensitive health data.
   → Cadence's core pitch: local-only, no accounts, no telemetry, no ads.

3. **Averaging + protocol support instead of single-reading drama.**
   Clinical gap is documented: a study found **only 6 of 62 BP apps met
   home-monitoring best practice** — e.g. accept morning + evening readings over
   7 days and show the *mean*, not react to one spike. Most apps log a number
   and stop.
   → Cadence's core model: session (7-2-2), period averages, coverage
   ("9/14 this week"). This is the differentiator, not a nice-to-have.

4. **Medication tracking + reminders, and a clean PDF for the doctor.**
   The baseline "share with my GP" ask. Recurring in reviews.
   → Cadence status: notes can hold medication today. **Reminders** flagged as
   the more interesting *earlier* slice (standalone nudge, barely touches the
   data model). Full medication tracking = later slice (bigger domain add,
   must stay diary-side of the medical-device line).

5. **Trustworthy interpretation, not diagnosis.**
   Thread after thread is panic over one high reading. Apps that colour a single
   reading red make it worse. The unmet need is *context*: averages, coverage,
   ranges attributed to a source (ESH/AHA), and "talk to your doctor" framing —
   never a fake verdict.
   → Cadence's regulatory boundary already forbids the bad version. The
   positive version (context, coverage labels, sourced ranges) is the product.

**One-line takeaway for Cadence:** the features the market ignores are already
your defaults. The one genuinely open opportunity on this list is
**reminders → then medication tracking**.

---

## The r/QuantifiedSelf "privacy-first self-made app" post

- **Link:** https://www.reddit.com/r/QuantifiedSelf/comments/1vr4l35/looking_for_a_few_people_who_actively_track_their/
- **Posted:** 2026-08-17, r/QuantifiedSelf. Small footprint: 3 upvotes, 4 comments.
- **What it is:** a recruit-testers post — privacy-first, self-made, Android,
  BP / heart health. No app name, no Play Store link, no GitHub anywhere.

**Could not read the 4 comments.** Reddit hard-blocks automated fetching now
(login wall / 403 — same block that 429'd the research run). Tried direct JSON,
old-reddit, browser user-agent, and a text-reader proxy; all bounced. To get
the tester feedback: open the link in a browser and paste the comments in.

**Was it finished/published?** Almost certainly not. A recruit-testers post
with no name and no store link = a solo dev at the *prototype* stage. Searching
for the app by its description found nothing, confirming it's not published
under a findable name. So it's **not a competitor to study — it's a fellow
prototype**. Its value: an independent person felt the "privacy-first BP
tracker" gap strongly enough to build their own. Validates the niche; gives
nothing to reverse-engineer.

---

## Published privacy-first apps worth actually studying

More useful than the nameless prototype — these are real and fetchable:

- **Pressure Easy** — pitches "no accounts, no subscriptions, no data
  collection." Direct philosophical match to Cadence.
  App Store: https://apps.apple.com/app/id6759265324
- **Blood Pressure / "My Heart"** — privacy-first + doctor-ready PDF reports,
  ~14M downloads. Worth studying for how it presents ranges without crossing
  into diagnosis. https://www.bphealth.app/en/blog/best-blood-pressure-app-2026

Open question to chase later: how each handles the diagnosis boundary, and what
their reviews complain about.

---

## Raw research artifact

Full engine dump (23 Reddit threads, 8 YouTube videos, 12 HN stories) saved at:
`~/Documents/Last30Days/blood-pressure-tracker-app-most-wanted-features-raw-v3.md`
