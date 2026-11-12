# Cinematic title reveal — local review

Implemented two 8-second, 1920 × 1080, 60 fps demos:

- `scenes/cinematic-title-reveal/demo/movie.mp4`: original **NEXT CHAPTER** title,
  procedural studio light field, and an original aperture mark.
- `scenes/cinematic-title-reveal/tesla-demo/movie.mp4`: actual **TESLA AI** title,
  red vector Tesla symbol, and the stable Cybercab clip used in the defense.

Both are rendered by `runtime/renderers/cinematic-title.swift`; labels, spacing,
timing, logo, light colors, and optional footage are configuration inputs.
`variants.json` records both gallery variants.

## Fidelity decisions

The accepted defense source was a high-resolution vector mask with temporary
edge light, not a blurry persistent shadow. This renderer uses CoreText glyph
paths directly. A narrow traveling highlight catches the contours, the platinum
face gains exposure, and a broad reflection passes once before a clean hold.
The final frame contains no bright outer border or low-resolution black halo.

The Tesla PDF is rasterized at four times its displayed dimensions, so the logo
edge mask is derived from the vector source rather than a small screenshot. The
background uses the already stabilized, cyclic defense clip, not a new handheld
shot. A slow 1.2% camera settlement adds depth without bouncing the text.

The initial preview exposed a visible black title silhouette at time zero; that
was fixed with an independent face-alpha entrance before the luminance reveal.

## Verification performed

- Compiled the standalone renderer with the local Swift compiler.
- Rendered both complete MP4s and all source preview frames.
- Decoded all **480 frames in each movie** with AVFoundation.
- Both verification files report passing dimensions, 60 fps, 8.0 seconds,
  strictly increasing timestamps, and complete reader status.
- Inspected source contact sheets, encoded contact sheets, and final posters.
- Default scene has no media dependency; optional Tesla assets use portable
  config-relative references and have a provenance manifest.

Native Keynote playback is outside this scene-only test. It remains a separate
assembly/rehearsal check. The Tesla footage and symbol are local reference media;
their redistribution status is not inferred from successful rendering.
