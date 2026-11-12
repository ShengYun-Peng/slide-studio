# Cinematic title reveal

Use this for a new chapter, a final promise, a product name, or a “what's next”
moment. The title begins unseen; moving light catches its edges, the face gains
exposure, and a soft reflection passes across it. It then holds as a clean title.

This rebuilds the technique from the final defense Tesla AI scene rather than
substituting a large blurred outline. The default **NEXT CHAPTER** demo is made
entirely from original procedural graphics. The **TESLA AI** variant uses the
actual red vector mark and Cybercab footage from the defense's local source pack.

## Render

```sh
python3 studio.py render --scene cinematic-title-reveal --output my-project/build/title
python3 studio.py render --scene cinematic-title-reveal --config scenes/cinematic-title-reveal/tesla-scene.json --output my-project/build/tesla-title
```

Or use the standalone native renderer:

```sh
swiftc -O runtime/renderers/cinematic-title.swift -o build/cinematic-title
build/cinematic-title --config scenes/cinematic-title-reveal/scene.json --output build/title --video
```

`--preview` produces a poster, an end frame, and a contact sheet. `--video` also
encodes a silent MP4. The shipped demos are 1920 × 1080 at 60 fps. Geometry is
defined on a 1920 × 1080 logical canvas; larger even 16:9 output sizes retain
vector edges and can be used for final delivery.

## Change the content

| Field in `content` | Purpose |
|---|---|
| `title` | Main title, kept on one line |
| `subtitle`, `eyebrow` | Optional supporting labels; empty strings hide them |
| `font`, `font_size`, `tracking` | System font name, initial type size, and letter spacing |
| `max_title_width` | Measured width limit; long titles scale uniformly rather than distort |
| `title_center_y` | Title's visible center on the logical canvas |
| `logo_kind` | `monogram`, `pdf`, or `none` |
| `logo_pdf` | Optional vector logo, resolved relative to the source config |
| `background_video` | Optional local footage, resolved relative to the source config |
| `background_opacity` | Footage exposure, from 0 to 1 |
| `logo_color`, `light_color` | Original mark and moving-light colors; an imported PDF retains its own artwork colors |
| `logo_y`, `subtitle_y`, `subtitle_size` | Composition adjustments |

Replace the footage with a stable shot. A shaky background cannot be repaired by
adding glow. The renderer starts the clip at `background_start`, plays forward,
and holds the final source frame if the title scene lasts longer than the source.
The neutral demo does not need either optional asset.

## Retiming

The named events are absolute seconds in a standalone config:

- `sweep_start/end`: the moving edge-light pass.
- `rim_start/full` and `rim_fade_start/end`: entrance and disappearance of edge light.
- `face_alpha_start/end`: the face enters without revealing a black silhouette at frame 0.
- `face_start/end`: the face brightens to its final platinum material.
- `sheen_start/end`: a restrained broad reflection crosses the filled glyphs.
- `background_start/end`: optional footage fades in under the title.
- `subtitle_start/end`: small text enters only after the main title is legible.

Keep at least a short final hold. Use the studio project's duration override to
retime inherited events together; if editing this complete JSON directly, adjust
all event times and review timestamps to fit the duration.

## Why the edges stay clean

The renderer gets real glyph paths from CoreText and keeps those vector paths for
the face and all edge-light passes. The face has a subtle vertical platinum
gradient, not a hard bevel. Edge highlights use narrow stroked paths and moving
gradients, then fade out completely. The imported Tesla mark is rasterized from
the vector PDF at four times its displayed size; its transient edge mask is
computed at that resolution. No low-resolution mask is enlarged for the final
title, and no persistent black shadow surrounds the letters.

## Asset status

The neutral demo is independent of the defense source files. The local Tesla
variant references `assets/cinematic/tesla-reference/`; its provenance is recorded
in `assets/cinematic/provenance.json`. Those third-party assets and the derived
Tesla movie are for local review until redistribution has been checked. The
generic renderer, neutral demo, and source configuration remain useful without
them. This is separate from the design question of whether a brand mark looks
appropriate in a presentation.
