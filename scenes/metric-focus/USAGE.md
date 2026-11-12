# Table → comparison → takeaway

Use when an audience cannot read an entire benchmark table while listening. Start with the table, leave the meaningful baseline visible, dim unrelated rows, emphasize the proposed row, and reveal one large result. The geometry never shifts between states.

## Adapt

- `headers`: four labels.
- `rows`: four rows with four values each; use strings so units and signs stay explicit.
- `baseline_row` and `focus_row`: zero-based indices.
- `metric`, `metric_label`, `comparison_line1/2`, `takeaway`: concise conclusion.
- `focus_start/end`, `insight_start/end`, `takeaway_start/end`: staged attention.

The default +14.4 safety points is computed conceptually from the shown 94.6 and 80.2 values. These are illustrative. When replacing the rows, also update the headline delta and its units. The headline is a label, not an automatic statistical calculation.

Keep unrelated rows legible enough to recognize the comparison context. Do not gray out the baseline needed to assess the claim, or use color to hide a tradeoff.

## Render and inspect

From the repository root:

```sh
swiftc -O runtime/renderers/presentation-patterns.swift -o /tmp/presentation-patterns
/tmp/presentation-patterns --config "$PWD/scenes/metric-focus/scene.json" --output "$PWD/scenes/metric-focus/demo" --preview
/tmp/presentation-patterns --config "$PWD/scenes/metric-focus/scene.json" --output "$PWD/scenes/metric-focus/demo" --video
```

The default demo is **1920 × 1080, 60 fps, 8.5 seconds**, with a steady end state. It uses CoreGraphics/CoreText and AVFoundation; no external packages or downloaded media are needed. Content, theme, event times, poster time and preview times are read from JSON. The design canvas remains 1920 × 1080 when output resolution changes.

Review `contact-sheet.png` before a full render, then `decoded-contact-sheet.png` and actual playback. The shared native decoder can validate the final movie:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-presentation-patterns
/tmp/verify-presentation-patterns "$PWD/scenes/metric-focus/demo"
```

A duration change in a complete standalone configuration does not imply a new event schedule: update event/poster/preview times too. Project-level retiming is handled by the studio pipeline. Native Keynote movie autoplay and manual slide advance remain separate settings.

## Scientific and visual limits

The supplied values and report are **illustrative**, not experimental results. Keep the visible footnote or replace it with the appropriate evidence citation when using measured content. The renderer does not validate a scientific claim. Do not infer a causal result from the visual effect itself.

Text is rendered into the movie. The source JSON and Swift remain editable; the movie is not a set of native Keynote text boxes. For frequent text changes, keep only the moving visual in the movie and place static labels natively.
