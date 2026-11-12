# Context → linked detail

Use when a full document, interface, map, or dense figure gives necessary context, but a small region carries the evidence. The source stays visible while its selected region lifts into a larger view. Both connector endpoints are computed from the same source rectangle; no independent positioning or guessed crop.

The demo uses an original procedural report. It first marks a table region, then moves the exact same crop into a clean detail panel, then reveals a short takeaway. The plot/report texture is rendered once at high resolution, and the animation uses continuous geometry with a monotone easing curve.

## Adapt

- `title`, `eyebrow`, `source_label`, `detail_label`, `takeaway_line1`, and `takeaway_line2`: visible labels.
- `document_title`, `document_subtitle`, `document_metrics` (three values), `document_metric_labels` (three labels), `table_title`, and `table` (four-column rows): procedural document content.
- `source_image`: optional exported image, resolved relative to the supplied config. The image is mapped to a 900 × 1120 source canvas. Use matching aspect ratio or adapt the source layout to avoid distortion.
- `focus_rect`: `[x, y, width, height]` in that 900 × 1120 canvas. Default `[70, 390, 760, 280]`.
- `focus_start/end`, `zoom_start/end`, `caption_start/end`: the three narrative beats.

For a real figure, retain enough row/column/axis context in the selected region. Label the source and highlight the actual error or evidence; a zoom alone is not an explanation.

## Render and inspect

From the repository root:

```sh
swiftc -O runtime/renderers/presentation-patterns.swift -o /tmp/presentation-patterns
/tmp/presentation-patterns --config "$PWD/scenes/context-zoom/scene.json" --output "$PWD/scenes/context-zoom/demo" --preview
/tmp/presentation-patterns --config "$PWD/scenes/context-zoom/scene.json" --output "$PWD/scenes/context-zoom/demo" --video
```

The default demo is **1920 × 1080, 60 fps, 8.5 seconds**, with a steady end state. It uses CoreGraphics/CoreText and AVFoundation; no external packages or downloaded media are needed. Content, theme, event times, poster time and preview times are read from JSON. The design canvas remains 1920 × 1080 when output resolution changes.

Review `contact-sheet.png` before a full render, then `decoded-contact-sheet.png` and actual playback. The shared native decoder can validate the final movie:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-presentation-patterns
/tmp/verify-presentation-patterns "$PWD/scenes/context-zoom/demo"
```

A duration change in a complete standalone configuration does not imply a new event schedule: update event/poster/preview times too. Project-level retiming is handled by the studio pipeline. Native Keynote movie autoplay and manual slide advance remain separate settings.

## Scientific and visual limits

The supplied values and report are **illustrative**, not experimental results. Keep the visible footnote or replace it with the appropriate evidence citation when using measured content. The renderer does not validate a scientific claim. Do not infer a causal result from the visual effect itself.

Text is rendered into the movie. The source JSON and Swift remain editable; the movie is not a set of native Keynote text boxes. For frequent text changes, keep only the moving visual in the movie and place static labels natively.
