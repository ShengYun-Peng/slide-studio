# Five reusable presentation patterns

Implemented at `runtime/renderers/presentation-patterns.swift` with five scene configurations, usage guides, movies, posters, source contact sheets, and decoder verification files.

## What was made

| Pattern | Common use | Specific quality detail |
|---|---|---|
| Context → linked detail | Dense figure, document, interface, map | Exact source rectangle and crop corners share geometry; source stays visible |
| Locked before / after | Reconstruction, quality, segmentation, interface comparison | One camera and clipping boundary; default rest snaps to a column edge |
| Table → focused result | Benchmarks and ablations | Baseline stays visible; unrelated rows dim; headline stays separate from table |
| Connected research journey | Milestones, method stages, program story | Artifact thumbnails reveal purpose; node activates after path arrival |
| Evidence → insight | Trends, gaps, thresholds, regimes | Axes and legend precede curves; delta bracket attaches to exact points |

## Verified

- All five movies: **1920 × 1080, 60 fps, 8.5 seconds**.
- All **2,550 frames** decoded; dimensions, frame rate, duration, and monotonically increasing timestamps passed.
- End frames, staged source contact sheets, and encoded samples visually inspected.
- Fixed during review: a radial-background center artifact; premature chart points; a narrow partial-cell strip at the before/after divider; and independent timeline-node timing.
- Default demos use original procedural art, with no downloaded images, private photos, external footage, or packaged fonts.
- Values remain visibly marked illustrative. Optional external evidence images require the new project's provenance record.

## Additional useful families to consider later

The five above cover recurring evidence-presentation needs rather than decorative transitions. Other worthwhile families are: term-by-term equation explanation; architectural ablation (remove/replace one module while keeping the layout anchored); agent failure → recovery traces; uncertainty bands or distributions; and an image/video contact-sheet selector. These should be added when there is a real explanation they can improve, rather than multiplying interchangeable reveal effects.

## Catalog entries

Root integration can use these entries; this task did not edit the shared catalog or pipeline.

```json
[
  {
    "id": "context-zoom",
    "title": "Context \u2192 linked detail",
    "description": "Enlarge the exact evidence region while keeping its source and linked corners visible.",
    "config": "scenes/context-zoom/scene.json",
    "renderer": "runtime/renderers/presentation-patterns.swift",
    "demo": "scenes/context-zoom/demo/movie.mp4",
    "poster": "scenes/context-zoom/demo/poster.png",
    "license_status": "original procedural demo; illustrative data"
  },
  {
    "id": "before-after",
    "title": "Locked before / after",
    "description": "Reveal two aligned views with one smooth wipe, then hold a clean comparison.",
    "config": "scenes/before-after/scene.json",
    "renderer": "runtime/renderers/presentation-patterns.swift",
    "demo": "scenes/before-after/demo/movie.mp4",
    "poster": "scenes/before-after/demo/poster.png",
    "license_status": "original procedural demo; illustrative data"
  },
  {
    "id": "metric-focus",
    "title": "Table \u2192 focused result",
    "description": "Orient the audience, retain the baseline, and spotlight the result that matters.",
    "config": "scenes/metric-focus/scene.json",
    "renderer": "runtime/renderers/presentation-patterns.swift",
    "demo": "scenes/metric-focus/demo/movie.mp4",
    "poster": "scenes/metric-focus/demo/poster.png",
    "license_status": "original procedural demo; illustrative data"
  },
  {
    "id": "research-timeline",
    "title": "A connected research journey",
    "description": "Connect four milestones with purpose-specific artifacts and causally timed arrivals.",
    "config": "scenes/research-timeline/scene.json",
    "renderer": "runtime/renderers/presentation-patterns.swift",
    "demo": "scenes/research-timeline/demo/movie.mp4",
    "poster": "scenes/research-timeline/demo/poster.png",
    "license_status": "original procedural demo; illustrative data"
  },
  {
    "id": "evidence-to-insight",
    "title": "Evidence \u2192 insight",
    "description": "Trace the evidence first, then highlight the regime that supports the conclusion.",
    "config": "scenes/evidence-to-insight/scene.json",
    "renderer": "runtime/renderers/presentation-patterns.swift",
    "demo": "scenes/evidence-to-insight/demo/movie.mp4",
    "poster": "scenes/evidence-to-insight/demo/poster.png",
    "license_status": "original procedural demo; illustrative data"
  }
]
```
