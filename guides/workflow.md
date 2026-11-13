# From materials to a talk

Use this guide for a new presentation or a substantial narrative revision. For a narrow layout fix, go directly to the relevant guide and inspect the neighboring slides.

## 1. Capture the brief without creating a questionnaire

Infer what the provided material already establishes. Record the talk's audience, occasion, duration, desired outcome, supplied sources, output format, visual preferences, and existing edits to preserve. Ask only for information that changes a meaningful decision. A research defense, a 12-minute conference talk, and an industry briefing need different depths even when they share figures.

Write a one-sentence audience promise: “By the end, you will understand how to ___, and why ___ matters.” Use the promise to choose material; do not turn it into a slide that repeats the title verbatim.

## 2. Inventory evidence and assets

Register source files with `ingest`. Extract the paper's problem, contribution bullets, method, strongest evidence, limitations, and useful figures. Record source locations next to factual claims, including the evaluation setting behind each number. Source ingestion is an inventory step, not a guarantee that the document was fully understood.

Classify media as empirical figure, original explanatory illustration, reconstructed illustration, third-party footage, or decorative asset. Keep source and derived material separate. For screenshot or crop-based examples, retain the full original so a reviewer can understand the claimed failure.

If the research contribution is an interactive system, inspect the system itself. Identify a task and a short interaction sequence that demonstrates what the tool makes possible. A deck built mostly from paper figures can summarize the project while leaving the audience unable to understand or use its interface. Follow [interactive talks](interactive-talks.md) for that route.

## 3. Draft the argument before the slide count

A useful research-talk arc is:

1. A familiar task or experience gives the audience a common starting point.
2. Concrete evidence reveals a consequential gap.
3. A concise question leads to the research mission.
4. A small number of parts explains how the mission is addressed.
5. Each work follows problem → key idea → mechanism → evidence → takeaway.
6. Bridges turn the previous result or limitation into the next research question.
7. Future directions grow from completed contributions, then impact and acknowledgements close the talk.

This is a reusable pattern, not a fixed slide order. Short talks may combine several steps. A defense may need an early publication overview and a later impact synthesis; a product talk may not.

Avoid a method name as the only bridge. “This shows that finetuning can remove the protection. How can we retain it?” prepares a new method better than “Our next work is DSS.” Likewise, introduce architecture as a response to reliable visual input, then connect the adversarial and document examples explicitly.

## 4. Use semantic content files

The CLI's project contract is intentionally small:

```json
{
  "schema_version": 1,
  "title": "Reliable Document Extraction",
  "theme": "anthony-dark",
  "duration_minutes": 12,
  "storyboard": "storyboard.json"
}
```

`storyboard.json` contains a `slides` array. A representative slide is:

```json
{
  "id": "extract-structure-before-text",
  "layout": "comparison",
  "title": "Structure determines which value belongs where",
  "columns": [
    {"title": "Table image", "body": ["Headers and merged cells define relationships"]},
    {"title": "Recovered structure", "body": ["Preserve those relationships before reading values"]}
  ],
  "notes": "notes/extract-structure-before-text.md"
}
```

The ID survives insertion, deletion, and reordering. Notes paths and scene associations should use that ID. A slide's current number is useful for communicating with the presenter; resolve it to an ID before editing.

The [authoring contract](authoring-contract.md) describes the actual supported layout fields and current limits. Use it when adapting the sample to a new topic.

Supported layout roles are listed in [the layout catalog](../templates/layouts/catalog.json). A scene binding uses `scene: {"template": "scene-id", "overrides": {}}`; choose the ID from `python3 studio.py catalog`, then adapt the scene configuration. Keep layout, content, theme, and time-dependent behavior separate.

## 5. Prove one representative slice

Build a short slice that tests the hardest choices: an opening, a dense method diagram, a table or result, a paper cover, and a motion scene if relevant. Check whether the audience can identify the message without reading notes. A user may review this slice while independent work continues.

For a tool talk, the slice should include a real overview-to-detail interaction, not only static cover and motivation slides. Review it at presentation distance: core reading text follows the chosen profile's size floor, the title describes the visible point, and the audience has one obvious reading target. Compare the sequence with accepted references for hierarchy and continuity, not merely matching colors.

Once the direction is clear, extend it consistently. Do not ask for approval for every routine edit or repeat the same preference question. If the user limits a revision to a prototype slide, honor that boundary before propagating it.

## 6. Compose, rehearse, revise

Write the notes together with the visual sequence. Explain what is visible before drawing a conclusion, and leave enough time for the audience to locate the evidence. Give complex continuous motion a single event clock and useful narration holds.

Estimate talk length from the current spoken notes and observed rehearsal speed. Movie duration overlaps narration; add only the portions that actually require silent waiting. Appendix slides do not belong in the main-talk total. A slide-count target can help plan pacing, but it cannot determine duration by itself.

## 7. Assemble and verify the actual deliverable

Run validation, static preview, scene preview, full rendering, assembly, and verification as appropriate. The agent makes the scientific and editorial decisions; the CLI makes file processing and rendering repeatable. It is not an autonomous paper summarizer.

Check the native deck in Keynote when available. In particular, verify movie autoplay, manual slide advance, notes readability, real text wrapping, face masks, and the ending state of animations. Preserve a current snapshot before replacing a deliverable; do not overwrite a newer manually edited deck.

Deliver the final `.key`, a useful project source, and a concise review note naming any real limitations. Keep intermediate exports inside generated-output locations. No PDF/PPTX export is required merely to mark an iteration complete.
