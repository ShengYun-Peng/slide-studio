# Revise the current deck without losing the speaker's work

An existing deck is a live design artifact. The speaker may have changed text, notes, crops, object positions, timing, or slide order since the last generated build. The newest saved deck is the starting point for a revision.

## Resolve identity before editing

Translate “slide 110” into its current title, content, and semantic ID. Confirm the neighboring slides. Merged slides and inserted transitions can shift every later number. For embedded media, locate the actual movie associated with the slide; a filename containing an old slide number is not evidence of current placement.

Keep three states when possible:

1. The baseline used for the last generated output.
2. The latest user-edited saved deck.
3. The proposed revision.

Apply the requested change to the latest state and preserve unrelated differences. Do not replace a user's tuned layout with an older template just because it is easier to regenerate.

## Edit through the safest available route

Native editing can be appropriate when the current Keynote session is accessible and edits can be inspected and saved. File-based regeneration is appropriate when the source project is authoritative or when working on a saved copy. Neither route is inherently always available.

Before writing over an existing deliverable, establish that the file is current and that an open window will not later overwrite the change. If live app access is unavailable, work on a copy and use a save/close handoff only when it is actually needed. Do not make the user repeatedly close the document if a verified native route can preserve their work.

Retain a recoverable snapshot of the deliverable for substantial edits. Keep snapshots and source material in the working project's internal locations, not as a growing pile of similarly named final files. Do not delete unfamiliar `.sb-*` or application staging files merely because they look redundant; identify their role and active owner first.

For a movie-only revision, use the [native media workflow](keynote-media.md) in a review copy. Compare native notes, text/styles, geometry, and transitions before and after; changing the movie must not reset unrelated manual edits. Reconfirm the latest original before delivering the revised copy.

## Generalize the fix within the authorized scope

A reported arrowhead gap suggests checking the same connector recipe elsewhere. A low-contrast axis suggests checking other figures imported from the same source. A notes style defect suggests a representative native test, then consistent application. This is better than waiting for the user to find every instance.

Generalization is not a license to redesign unrelated pages. Preserve edits the user explicitly prefers. If the user requests a prototype on one roadmap page before propagating it, finish that prototype and await their feedback before changing the other roadmaps.

## Review in layers

| Layer | Check | What it does not establish |
|---|---|---|
| Source integrity | Paths, hashes, claims, asset records, configuration | Visual correctness |
| Content validation | Known layout, required fields, notes, scene bindings | Scientific accuracy or native wrapping |
| Static preview | Hierarchy, alignment, contrast, cropping | Playback, native build order, notes-pane appearance |
| Encoded movie | Timing, frame continuity, arrow and label states | How Keynote layers or advances that movie |
| Native deck | Actual object layout, autoplay, manual advance, notes visibility | Talk duration at the speaker's real pace |
| Rehearsal | Spoken flow, pauses, interpretation, duration | Every factual claim's source accuracy |

Record the levels actually completed. When a capability is missing, make the unresolved check explicit instead of calling the deliverable fully verified.

## Practical visual pass

Inspect representative sequences as well as individual slides:

- Adjacent title/body anchors and matching part-title line breaks.
- Mission words and part colors across the entire reveal.
- Paper cover head positions, name centering, venue and badge gaps.
- Table row heights, key-row emphasis, axes and labels on dark backgrounds.
- Arrow endpoints and tangent alignment at intermediate animation frames.
- Masked cells, crop markers, temporary labels, and final assembled outputs.
- Takeaway style and line spacing across papers.
- Transition questions that genuinely follow the preceding evidence.
- Page numbers, full-screen movies, final frames, and absence of accidental auto-advance.
- Notes readability and production comments removed from spoken content.

For a widescreen talk, inspect a full slide at realistic viewing scale, not only zoomed-in crops. The audience should know where to look without searching four disconnected text clusters.

## Portable reuse test

An independent project is portable only if a fresh agent can use it without the old defense folder. Test a different topic, not a renamed version of the same paper. Change content, theme or part labels, and at least one timing value. Rebuild a scene and assemble a small native deck when supported.

Check that no absolute personal source paths, hidden previous-version imports, missing fonts, or mutable remote-only assets are required. Keep any optional environment-specific feature clearly separated from the core project. A gallery thumbnail is not proof that its source code can be rerun.

## Finish with a reviewable result

The final note should identify the actual output, summarize meaningful changes, state which checks passed, and name any concrete unresolved limitations. Do not require the user to read process logs to discover what is usable. Keep the final deliverable easy to find, with source and generated material retained for the next revision.
