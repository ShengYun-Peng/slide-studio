# Scene rendering on macOS

The runtime renders motion from **time**, not by joining screenshots of slides.
A scene configuration defines content, assets, timing, and output settings. Its
renderer evaluates the visual state at each frame, which makes selected-frame
inspection and controlled retiming possible.

## Use the catalog route

The catalog contains **15 patterns**, with a separate Tesla AI variant of the
cinematic title. `scenes/catalog.json` maps every scene ID to its renderer. Use
the CLI rather than compiling `main.swift` for every pattern:

```sh
python3 studio.py catalog
python3 studio.py render --scene branch-and-merge --output my-project/build/branch --preview-only
python3 studio.py render --scene branch-and-merge --output my-project/build/branch
python3 studio.py render --scene cinematic-title-reveal --config scenes/cinematic-title-reveal/tesla-scene.json --output my-project/build/tesla-title
```

Current routes are:

| Renderer | Pattern IDs |
|---|---|
| `runtime/swift/main.swift` | `framework-to-portfolio`, `surface-build`, `surface-trajectories`, `text-and-score` |
| `runtime/renderers/device-story.swift` | `device-story` |
| `runtime/renderers/table-modules.swift` | `branch-and-merge` |
| `runtime/renderers/research-training.swift` | `learn-visual-vocabulary`, `masked-token-training` |
| `runtime/renderers/video-budget.swift` | `video-budget` |
| `runtime/renderers/presentation-patterns.swift` | `context-zoom`, `before-after`, `metric-focus`, `research-timeline`, `evidence-to-insight` |
| `runtime/renderers/cinematic-title.swift` | `cinematic-title-reveal` and its Tesla AI variant |

The code in `main.swift` still contains earlier simple implementations for some
patterns. They are useful source examples, but the catalog-selected specialized
renderers are the gallery's current quality reference. The CLI records the actual
renderer path and hash, config hash, asset hashes, and environment in `inputs.json`.

## Platform and assets

Requires macOS and Apple's command-line developer tools. CoreGraphics/CoreText
draw vector geometry and text; CoreImage performs compositing and screen-plane
transforms; SceneKit draws the 3D surfaces; AVFoundation encodes and decodes
movies. Surface scenes require a Metal-capable Mac. No Python packages, ffmpeg,
network service, or API key are needed for the bundled renderers.

Some renderers need packaged assets. The table-training demos use a synthetic
teaching image. The polished device scene uses photographic Apple hardware and
its registered screen geometry. The optional Tesla title uses a vector logo and
Cybercab footage. These files are copied into this independent project; runtime
code does not need the old defense folder or its temporary directories. Asset
availability and redistribution status are separate questions: see
[`LICENSE_STATUS.md`](../../LICENSE_STATUS.md) and each provenance manifest.

Asset paths in an isolated source config are relative to that config. Bundled
scenes may refer to `../../assets/` within the repository. A project override
resolves against the current presentation folder. The CLI creates a resolved
build config and hashes each asset; do not hardcode personal source paths into
the portable JSON.

## Render contract

- `--config ABS_JSON --output ABS_DIRECTORY --preview`: writes `poster.png`,
  `end.png`, `contact-sheet.png`, and `render-manifest.json`.
- `--video`: writes the same files plus a silent `movie.mp4`.
- Shipped scene configs now use **1920 × 1080 at 60 fps**. Smaller previews or
  larger 4K deliveries can be configured; the logical canvas is normally
  1920 × 1080 and output remains 16:9. Do not infer quality from resolution alone.
- The full configuration contains seconds for event times, poster time, and
  preview timestamps. When invoking the standalone Swift binary, changing only
  `duration` does not automatically retime those values.
- The project CLI's `scene.overrides.duration` retimes inherited events,
  preview/poster timestamps, and supported timeline anchors proportionally.
  Explicit overridden event values are seconds in the new schedule and win over
  the inherited values. Invalid bounds or event order are rejected.
- Some defense-derived scenes expose `timeline` anchors, mapping presentation
  time (`at`) onto the original causal sequence (`reference`). This retains the
  method's detailed choreography while allowing different speaking holds.
- Theme and content support is renderer-specific. Consult the scene's `USAGE.md`
  and actual JSON fields; adding an arbitrary label does not make the renderer
  consume it. Notes size belongs to the slide adapter, not the movie.

## Preserving production quality

Reusability should retain the useful source detail. The modular sequence keeps
the dependency between location, cropping, and recognition. Training diagrams
retain the distinction between learning a visual vocabulary and predicting masked
targets. The device keeps a measured hardware/screen relationship. The title
effect uses vector glyph paths and transient edge light instead of a low-resolution
glow. These details matter more than merely adding frames or gradients.

When adapting a scene, preserve its semantic anchors, layout, and rendering
quality, then replace the content. If the new method changes a dependency, change
the diagram itself; a polished animation must not teach the wrong mechanism.

For a new family, implement a standalone Swift renderer with the same output
contract or extend a suitable existing renderer. Register its bundled source in
`scenes/catalog.json`, add its config and usage guide, then test it through the CLI.
Use common progress variables for connected objects and synchronized quantities.
Keep editable labels outside the movie when frequent native text edits matter.

## Surface implementation

`SurfaceRenderer` builds a mesh from an illustrative height function. It clips
triangles against a moving horizontal plane while retaining vertex positions;
it does not stretch a 2D screenshot upward. Camera and lights stay fixed. Replace
the sampler with measured data before using the scene as experimental evidence.
The supplied geometry explains the concept but does not recover the original
paper's numerical samples.

## Verify the encoded movie

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/verify-motion
/tmp/verify-motion my-project/build/branch
```

The decoder checks every frame, dimensions, fps, duration, and increasing
timestamps, then writes `verification.json` and `decoded-contact-sheet.png`.
Inspect source and decoded frames, then watch actual playback at speaking speed.
Those structural checks do not establish scientific correctness, artistic
quality, native Keynote autoplay, or narrator synchronization.

Native font rasterization, GPU output, and encoders may vary across macOS versions.
Reproducibility means retaining the same source, content, assets, timeline, and
geometry—not guaranteeing byte-identical movies on every machine. A movie is
still a movie after assembly: its internal labels are not native Keynote text
objects. Movie autoplay and manual slide advance remain separate settings.
