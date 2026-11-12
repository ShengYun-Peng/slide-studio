# Trace evidence → isolate insight

Use for a result where the important point is a regime, gap, threshold, or trend. Axes appear first. Both curves trace on the same clock. Then a soft focus band, a correctly attached delta bracket, and a short conclusion direct attention to the relevant region.

The default compares two illustrative learning curves and emphasizes the low-data regime. Plot lines are piecewise linear through the supplied samples, rather than visually smoothed through invented values.

## Adapt

- `baseline`, `proposed`: equal-length numeric arrays, at least two samples.
- `y_min`, `y_max`: axis bounds (default 40 and 100); `y_ticks`: displayed numeric ticks.
- `x_ticks`: four labels at equally spaced positions. The default represents a log-spaced x axis. Adapt the x mapping in source for nonuniform sample positions.
- `baseline_label`, `proposed_label`, `x_label`, `y_label`: actual quantities and units.
- `delta_index`: shared sample index to annotate; default 2. If `delta_label` is omitted, it is derived from the two values at that sample. A supplied label must agree with the values and units.
- `insight_heading`, `insight_line1/2`, `insight_detail`, `insight_detail2`: the concise reading guide.
- `axes_start/end`, `curves_start/end`, `focus_start/end`: evidence-before-conclusion timing.

The focus band currently marks the first 39% of the plot. Change its geometry when another region supports the insight. If the axis does not begin at zero, keep the numeric lower bound visible.

## Render and inspect

From the repository root:

```sh
swiftc -O runtime/renderers/presentation-patterns.swift -o /tmp/presentation-patterns
/tmp/presentation-patterns --config "$PWD/scenes/evidence-to-insight/scene.json" --output "$PWD/scenes/evidence-to-insight/demo" --preview
/tmp/presentation-patterns --config "$PWD/scenes/evidence-to-insight/scene.json" --output "$PWD/scenes/evidence-to-insight/demo" --video
```

The default demo is **1920 × 1080, 60 fps, 8.5 seconds**, with a steady end state. It uses CoreGraphics/CoreText and AVFoundation; no external packages or downloaded media are needed. Content, theme, event times, poster time and preview times are read from JSON. The design canvas remains 1920 × 1080 when output resolution changes.

Review `contact-sheet.png` before a full render, then `decoded-contact-sheet.png` and actual playback. The shared native decoder can validate the final movie:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-presentation-patterns
/tmp/verify-presentation-patterns "$PWD/scenes/evidence-to-insight/demo"
```

A duration change in a complete standalone configuration does not imply a new event schedule: update event/poster/preview times too. Project-level retiming is handled by the studio pipeline. Native Keynote movie autoplay and manual slide advance remain separate settings.

## Scientific and visual limits

The supplied values and report are **illustrative**, not experimental results. Keep the visible footnote or replace it with the appropriate evidence citation when using measured content. The renderer does not validate a scientific claim. Do not infer a causal result from the visual effect itself.

Text is rendered into the movie. The source JSON and Swift remain editable; the movie is not a set of native Keynote text boxes. For frequent text changes, keep only the moving visual in the movie and place static labels natively.
