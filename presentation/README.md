# Defence Presentation — Smart Health (SWE3090XA)

A self-contained HTML slide deck for presenting the project to the lecturer, with
built-in **speaker script and scoring cues** on every slide.

## Open it

**On a laptop:** double-click `index.html` (opens in any browser). Present in
**fullscreen** for best effect.

**On your iPhone:** use `Smart-Health-Presentation.html` — a single self-contained
file (~2 MB) with every image embedded, so it works from any viewer with no
`assets/` folder. Easiest path: email or AirDrop that one file to yourself, then
open it (launches in Safari). Fully responsive — tested at iPhone size.

> `index.html` is the editable source and references `./assets/`. After editing it,
> regenerate the phone file with `python build-standalone.py`.

## Controls

**Desktop (keyboard/mouse)**

| Key | Action |
|-----|--------|
| `→` / `Space` / click right | Next slide |
| `←` / click left | Previous slide |
| `S` | Toggle the speaker-notes panel (shown by default) |
| `F` | Fullscreen |
| `Home` / `End` | Jump to first / last slide |

**Phone (touch)**

| Gesture | Action |
|---------|--------|
| Swipe left / right | Next / previous slide |
| `‹` `›` buttons (bottom bar) | Next / previous slide |
| **📝 Notes** button (bottom bar) | Show/hide the speaker script (hidden by default on phones) |

On phones each slide scrolls vertically if its content is taller than the screen.

## What's in the deck (21 slides)

1. Title · 2. Problem · 3. What I built · 4. Objectives
5–8. **Architecture** — API-based layered design, data flow, security
9–13. **Live demo** — symptom check → Malaria 55% (explainable) → rule engine → providers
14–16. **Evidence** — testing (T1–T6, 15 tests), ER model, challenges
17–20. Outcomes · Recommendations · Conclusion · **your Q&A defence sheet**

Each slide's bottom panel has two things for you:
- 🎤 **Presenter script** — what to say.
- ⭐ **Maximum-marks cue** — the exact phrase or move that earns the rubric mark.

## Running the live demo alongside the deck

See `../LAUNCH.md`. Start the backend, boot the `swe_pixel` emulator, `flutter run`.
Suggested path: **Fever + Headache + Chills → Analyse → Malaria 55% →
Find Nearby Doctors → Directions**. Keep the backend window visible so the panel
sees the request hit the rule engine live.

> The `assets/` folder holds the app screenshots and the report figures the deck
> embeds — keep it next to `index.html`.
