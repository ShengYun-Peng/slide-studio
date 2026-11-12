# Motion gallery v2 — local review

The gallery contains **15 reusable patterns and one Tesla AI variant**. The
upgrade preserves more of the original defense's composition and causal
sequences, with source, configuration, assets, and provenance inside this project.

## What changed

- **Device story:** photographic Apple hardware replaces the schematic laptop.
  The live UI is registered to its moving screen; cursor distance controls icon
  enlargement; caption, icon, and window exits use separate readable beats.
- **Framework to portfolio:** one rigid transform rotates the hub, curved glass
  legs, and three rings together. The same parts become publication headings.
- **Modular table:** structure and location branch first; locations supply cell
  crops to the content model; recognized words assemble into the final structure.
- **Two training steps:** reconstruction shows tokenizer, vocabulary, visual
  tokens, decoder, and feedback. Masked training separates frozen targets from
  the trainable branch and compares only masked positions.
- **Video budget:** sampled frames, token packets, and model activity explain
  where inference compute is spent before the cost summary appears.
- **Text and score:** a light research panel improves readability; text and curve
  share one prefix clock and the same semantic colors.
- **True 3D scenes:** the SceneKit mesh and checkpoint trajectories remain intact,
  now rendered at the gallery's 1080p60 delivery settings.
- **Six additions:** linked detail zoom, aligned before/after, metric focus,
  research timeline with artifact thumbnails, evidence-to-insight, and cinematic
  edge-light title reveal. The last includes neutral and Tesla AI versions.

The title reveal uses vector glyph paths, narrow moving highlights, and a clean
final face. The Tesla variant retains the red mark and Cybercab background; it
does not enlarge a low-resolution shadow around the letters.

## Review and reproducibility

Each shipped movie is 1920×1080 at 60 fps. Full-file decode checks validate frame
count, frame size, frame rate, duration, monotonic timestamps, and reader
completion. See [the consolidated machine report](quality-v2.json) for the final
movie hashes and exact results. Sampled visual review covers actual encoded
frames, including the transition collisions discovered and fixed during review:
[visual findings and their disposition](visual-review-v2.md).

The CLI selects the renderer from `scenes/catalog.json`. Render output records
resolved asset hashes, renderer hashes, configuration, and environment in
`inputs.json`. The main asset-bearing routes were also exercised through the CLI,
including the Tesla config override. Regression checks cover source/project asset
origins, renderer routing, duration retiming, and reference-timeline anchors.

The gallery was checked in headless Chrome at desktop and narrow widths; filtering,
search, opening the large player, and closing it work. It runs directly from a
local file and has no server, external font, analytics, or JavaScript dependency.

## Practical limits

- The photographic laptop source is 30 fps. Its registered source poses are
  blended; the interface and composition render at 60 fps. This is not newly
  captured 60 fps hardware footage.
- Demos explain mechanisms. Their numerical examples and reconstructed landscape
  are illustrative, not a substitute for a paper's measured results.
- Each scene's usage guide distinguishes configurable content from fixed geometry
  that requires a source edit. Replacing a label alone does not adapt a method.
- Apple footage and the Tesla reference remain local-review assets with separate
  provenance. The neutral title needs no external footage. See
  [license status](../LICENSE_STATUS.md) before public packaging.
- This pass improves the reusable gallery. It does not modify the original defense
  Keynote or certify native Keynote autoplay, notes, and live talk timing again.
