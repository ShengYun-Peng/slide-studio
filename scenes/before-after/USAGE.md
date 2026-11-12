# Locked before / after reveal

Use when image quality, reconstruction, segmentation, visualization design, or interface output must be compared at exactly the same viewpoint. Two layers share one coordinate system. A clipping boundary reveals the second layer, then settles at a balanced comparison; the handle and shaft follow that same boundary.

The default compares an illustrative table image with a structured representation. The rendering is original procedural artwork, not a reported model result. It does not simulate a camera or slide transition; it deliberately holds the evidence still.

## Adapt

- `before_image` and `after_image`: optional matched raster exports, relative to the supplied config file. Use the same camera, crop and dimensions in both.
- `table`: six rows of four columns for the procedural fallback.
- `before_label`, `after_label`, `title`, `eyebrow`, `takeaway`: visible labels.
- `reveal_start/end`: sweep across the shared image.
- `settle_start/end`: return to the balanced comparison. The default table snaps to the Q2 column boundary, avoiding a narrow partial-cell strip.
- `split_fraction`: optional resting position from 0 to 1 across the comparison frame; external-image pairs default to 0.5.
- `caption_start/end`: show the takeaway after the visual is understandable.

If the images have different perspectives or crop regions, align them before using this pattern. Otherwise the motion implies a fair pixel comparison that the sources do not support.

## Render and inspect

From the repository root:

```sh
swiftc -O runtime/renderers/presentation-patterns.swift -o /tmp/presentation-patterns
/tmp/presentation-patterns --config "$PWD/scenes/before-after/scene.json" --output "$PWD/scenes/before-after/demo" --preview
/tmp/presentation-patterns --config "$PWD/scenes/before-after/scene.json" --output "$PWD/scenes/before-after/demo" --video
```

The default demo is **1920 × 1080, 60 fps, 8.5 seconds**, with a steady end state. It uses CoreGraphics/CoreText and AVFoundation; no external packages or downloaded media are needed. Content, theme, event times, poster time and preview times are read from JSON. The design canvas remains 1920 × 1080 when output resolution changes.

Review `contact-sheet.png` before a full render, then `decoded-contact-sheet.png` and actual playback. The shared native decoder can validate the final movie:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-presentation-patterns
/tmp/verify-presentation-patterns "$PWD/scenes/before-after/demo"
```

A duration change in a complete standalone configuration does not imply a new event schedule: update event/poster/preview times too. Project-level retiming is handled by the studio pipeline. Native Keynote movie autoplay and manual slide advance remain separate settings.

## Scientific and visual limits

The supplied values and report are **illustrative**, not experimental results. Keep the visible footnote or replace it with the appropriate evidence citation when using measured content. The renderer does not validate a scientific claim. Do not infer a causal result from the visual effect itself.

Text is rendered into the movie. The source JSON and Swift remain editable; the movie is not a set of native Keynote text boxes. For frequent text changes, keep only the moving visual in the movie and place static labels natively.
