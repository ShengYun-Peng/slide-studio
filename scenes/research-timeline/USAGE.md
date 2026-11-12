# Research journey / milestones

Use when a project, method, or research program develops through a sequence of dependencies. This is a four-stage layout: labels stay large, detail uses at most two lines, and all nodes share a single connecting path.

Each stage also includes an original small artifact: an observed report region, a connected causal graph, an inspectable application, and an evaluation curve. These reveal with the corresponding stage, adding purpose without introducing another block of text.

Node arrival is derived from the path's easing curve. A node does not activate before the progressing line reaches it. The restrained ring pulse happens once; there is no bounce or constant moving particle.

## Adapt

- `milestones`: four short stage names.
- `details`: four arrays of one or two short lines.
- `years`: four date or stage labels.
- `title`, `eyebrow`, `takeaway`: the surrounding story.
- `journey_start/end`: the path progression.
- `takeaway_start/end`: reveal the conclusion after the final stage.

A timeline is appropriate for sequence or provenance. It does not prove that an earlier publication caused a later finding. For additional milestones, extend the layout; do not reduce every label to a tiny font.

## Render and inspect

From the repository root:

```sh
swiftc -O runtime/renderers/presentation-patterns.swift -o /tmp/presentation-patterns
/tmp/presentation-patterns --config "$PWD/scenes/research-timeline/scene.json" --output "$PWD/scenes/research-timeline/demo" --preview
/tmp/presentation-patterns --config "$PWD/scenes/research-timeline/scene.json" --output "$PWD/scenes/research-timeline/demo" --video
```

The default demo is **1920 × 1080, 60 fps, 8.5 seconds**, with a steady end state. It uses CoreGraphics/CoreText and AVFoundation; no external packages or downloaded media are needed. Content, theme, event times, poster time and preview times are read from JSON. The design canvas remains 1920 × 1080 when output resolution changes.

Review `contact-sheet.png` before a full render, then `decoded-contact-sheet.png` and actual playback. The shared native decoder can validate the final movie:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-presentation-patterns
/tmp/verify-presentation-patterns "$PWD/scenes/research-timeline/demo"
```

A duration change in a complete standalone configuration does not imply a new event schedule: update event/poster/preview times too. Project-level retiming is handled by the studio pipeline. Native Keynote movie autoplay and manual slide advance remain separate settings.

## Scientific and visual limits

The supplied values and report are **illustrative**, not experimental results. Keep the visible footnote or replace it with the appropriate evidence citation when using measured content. The renderer does not validate a scientific claim. Do not infer a causal result from the visual effect itself.

Text is rendered into the movie. The source JSON and Swift remain editable; the movie is not a set of native Keynote text boxes. For frequent text changes, keep only the moving visual in the movie and place static labels natively.
