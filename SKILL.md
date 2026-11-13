---
name: slide-studio
description: Create or revise research presentations in native Keynote using reusable layouts, conversational speaker notes, and code-rendered explanatory animations. Use with a topic, papers, figures, an existing deck, or a mix of materials.
---

# Slide Studio

Use [START_HERE.md](START_HERE.md) as the common entry point. It works with files and a shell; no particular agent, chat history, or MCP connection is required. The current talk lives in `my-project/`.

The bundled style is a starting profile, not a requirement to make every talk resemble a PhD defense. Preserve the user's audience, argument, medium, timing, and manual edits. Native Keynote assembly requires macOS and Keynote; portable source, inspection, and planning remain useful elsewhere.

## Route the work

- New topic or mixed materials: [workflow](guides/workflow.md), then [input materials](guides/input-materials.md).
- Layout or figure revision: [visual design](guides/visual-design.md).
- Interactive tool or visualization-system talk: [interactive talks](guides/interactive-talks.md), then the `interface-tour` scene.
- Speaker script: [spoken notes](guides/spoken-notes.md).
- Diagram-to-video or movie timing: [motion](guides/motion.md).
- Existing manually edited deck: [review and adaptation](guides/review-adaptation.md) before changing it.
- Replace embedded Keynote movies while preserving the deck: [native media workflow](guides/keynote-media.md).
- Recurring failure or design judgment: search [lessons learned](guides/lessons-learned.md) by symptom rather than loading the entire reference every time.

## Essential constraints

1. Use semantic slide and scene IDs. Slide numbers are current navigation hints, not durable identity.
2. Build claims from sources. Keep empirical results, explanatory reconstructions, and future ideas distinguishable.
3. Keep the argument readable at presentation distance. Prefer one claim and one clear visual reading order per slide; do not solve density by shrinking everything.
4. Use the same event clock for linked visual changes. A movie can autoplay on entry while the slide still advances manually.
5. Presenter notes contain what the speaker will say. Store production instructions and review comments separately. Native Keynote notes color must be checked in the actual notes pane; archive RGB values do not establish dark-mode visibility.
6. Inspect the current saved deck before applying changes. Work from a snapshot and preserve later manual changes; do not overwrite an open document with a stale generated file.
7. Report what was actually verified. Source validation, raster preview, encoded playback, and native Keynote inspection are different levels of evidence.

Run the available CLI through `python3 studio.py --help`. Use its existing commands and scene catalog before inventing another rendering pipeline. Adapt the configuration and source code where the user's content requires it, then rerun the relevant checks.
