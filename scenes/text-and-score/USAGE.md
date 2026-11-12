# Synchronize text and a score

Reveal response words and their score curve from one shared timeline.

## Run

From the repository root:

```sh
swiftc runtime/swift/main.swift -o /tmp/slide-motion
/tmp/slide-motion --config scenes/text-and-score/scene.json --output scenes/text-and-score/demo --video
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
- `response`: Configurable label.
- `scores`: Array of values.
- `score_label`: Configurable label.
- `footnote`: Configurable label.

## Event names

`response_start`, `response_end`.

`response` is split at spaces. Text and the moving chart endpoint derive from the same word position. `scores` is a nonempty numeric array, resampled to the word count. Demo scores are illustrative; substitute measured values before making scientific claims. The orange/green highlights currently follow fixed example word ranges; change those ranges in `score` when you change the rhetorical structure.

## Readable research panel

A light inset panel carries charcoal response text and the score plot, while the surrounding slide remains dark. Safe/risky highlights use the same green/purple mapping in text and trace. Text and the chart use the same prefix count, so the line cannot lag behind the words. Punctuation can be separate tokens in the input but renders without an extra preceding space.
