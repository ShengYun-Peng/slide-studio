# Build a 3D surface

Measure a point, trace a direction, then reveal a fixed 3D mesh with a rising horizontal plane.

## Run

From the repository root:

```sh
swiftc runtime/swift/main.swift -o /tmp/slide-motion
/tmp/slide-motion --config scenes/surface-build/scene.json --output scenes/surface-build/demo --video
```

For a quick layout check, replace `--video` with `--preview`. Both modes create `poster.png`, `end.png`, `contact-sheet.png`, and `render-manifest.json`; video mode also creates `movie.mp4`. The bundled demo is 1920×1080 at 60 fps. Inspect the encoded movie, including intermediate transitions, after changing geometry or timing.

## Adapt

- Change `content` in `scene.json`; the renderer consumes these values directly. All distances use a 1920×1080 design canvas and scale to the output size.
- Change `theme.background`, `foreground`, `muted`, `panel`, `accents`, `font_regular`, and `font_bold` together. The default theme is embedded, so the scene can be copied independently.
- `timing` values are **seconds**, not fractions. They control the named events directly. If you change `duration`, retime the events as well. `poster_time` and `preview_times` are also seconds.
- Preserve distinct semantic colors, readable labels, and one takeaway. Long strings are fitted to their boxes; inspect previews so fitting does not quietly make text too small.
- Use automatic **movie playback** on the slide. Keep slide advancement manual unless the speaker explicitly wants uninterrupted continuation.

## Content fields

- `title`: Configurable label.
- `height_label`: Configurable label.
- `height_scale`: Configurable number.
- `basin_radius`: Configurable number.
- `steps`: Array of values.
- `footnote`: Configurable label.

## Event names

`measure_start`, `measure_end`, `curve_start`, `curve_end`, `build_start`, `build_end`.

## Scientific status

This is a real 3D mesh rendered with SceneKit, but the height function is **illustrative**, not recovered experimental data. The broad low floor, steep sides, high plateau and small ripples are intentionally adjustable. `height_scale` changes the 3D height; `basin_radius` changes the low region. A fixed mesh is clipped by a rising horizontal plane; vertices do not stretch upward. To use measurements, replace `SurfaceRenderer.heightAt` with interpolation of your measured samples and record their provenance. The front wall is partly transparent so the axes and trajectories remain visible.

Requires a Metal-capable macOS machine. Camera and lighting are fixed to avoid jitter. No numerical axes are shown because these demo values do not support quantitative claims.
