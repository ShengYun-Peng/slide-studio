# Framework → portfolio

Keep a connected framework intact as it spins; turn its parts into a publication overview.

## Run

From the repository root:

```sh
swiftc runtime/swift/main.swift -o /tmp/slide-motion
/tmp/slide-motion --config scenes/framework-to-portfolio/scene.json --output scenes/framework-to-portfolio/demo --video
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
- `center`: Configurable label.
- `parts`: Array of values.
- `papers`: Array of arrays of labels.
- `recognition`: Configurable label.

## Event names

`spin_start`, `spin_end`, `spread_start`, `spread_end`, `labels_start`, `labels_end`, `papers_start`, `awards_start`, `awards_end`.

`content.awards` supplies one symbol type per paper (`oral`, `award`, `open`, or an empty string). They enter after the paper lists; keep the symbols secondary to the claims. The default symbols communicate a pattern, not an asserted award record.

## Connected geometry

The central bubble, curved glass legs, and three outer rings share one rigid transform during the spin. They do not rotate independently. The vector fill, edge highlights and translucent material are redrawn at output resolution. The parts then settle into the portfolio headings before the publication rows and recognition marks arrive. Preserve this order when changing the story.
