# Interface-tour and readability update

The November 2026 update adds a reusable interface walkthrough and applies the
conference-talk readability lessons to the Anthony dark profile.

## Checked artifacts

- The [bundled movie](../scenes/interface-tour/demo/movie.mp4) is 3840×2160,
  60 fps, and 12 seconds. All 720 frames decode, timestamps increase, and the
  reader completes. See the [decoder report](../scenes/interface-tour/demo/verification.json)
  and [movie hash](../scenes/interface-tour/demo/render-manifest.json).
- The original synthetic UI sources use DPR 6 for full states and DPR 12 for
  the reading crop. At the overview and final camera anchors, required DPR is
  2.88 and 6.4 respectively. Both views have sufficient source pixels; encoded
  frames were also inspected for readable detail and crop seams.
- One camera controls movement; state changes occur on a hold. The three-second
  move ends in a four-second reading hold. These are configurable example timings.
- The native eight-layout Keynote starter was rebuilt and exported as slide PNGs
  for visual review. Core text uses the enlarged profile; wrapped heading space,
  roadmap rows, and author circles were adjusted together.
- Tests cover the text floor, wrapped layout spacing, nested capture paths and
  hashes, timing overrides, and copy-only Keynote media replacement behavior.
  Local guide links and skill metadata were checked independently.
- A separate native media test replaced a 12-second movie with a 24-second movie
  in a disposable deck. Full trim, a persisted 22-second poster, autoplay settings,
  manual slide advance, preserved native content, unchanged source bytes, and the
  embedded movie hash all passed readback. See the [repeatable native test](../guides/keynote-media.md).

The movie is a composition of lossless states, not a continuous screen recording.
The UI and values are illustrative. Source-density checks describe pixels and
coverage, not the scientific accuracy of substituted content. Native playback
and real presentation pacing still need review in each new project.
