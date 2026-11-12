# Branch, specialize, then assemble

This is the detailed modular-table sequence adapted from the defense: a table image feeds a structure model and a location model; cell locations select real image crops for the content model; structure and recognized words then assemble one digitized table. The dependency between locating and reading cells is visible throughout.

## Run and inspect

From the repository root on macOS, compile this scene's actual renderer:

```sh
swiftc runtime/renderers/table-modules.swift -o /tmp/slide-studio-branch-and-merge
/tmp/slide-studio-branch-and-merge --config "$PWD/scenes/branch-and-merge/scene.json" --output "$PWD/scenes/branch-and-merge/demo" --video
```

Use `--preview` instead of `--video` for stills. Both modes produce `poster.png`, `end.png`, `contact-sheet.png`, and `render-manifest.json`; video mode also produces `movie.mp4`. The current demo is **1920×1080, 60 fps, 24 seconds**. Review the decoded movie as well as the poster, especially arrow endpoints, small labels, and the final hold. In Keynote, autoplay the movie while keeping slide advancement manual unless continuous advancement is intentional.

## What JSON changes

- `content.title`: the main takeaway, drawn above the diagram.
- `content.labels`: an exact source-string → replacement-string map. For example, `{"Table image":"Document image", "Structure model":"Layout model", "Digitized table":"Structured output"}`. Matching is case-sensitive. Multi-line captions are drawn as individual lines, so replace `Rows · columns` and `Merged cells` separately.
- `duration`, `fps`, output dimensions, `poster_time`, and `preview_times` control delivery and review.
- `timeline` retimes the complete sequence without changing its geometry.

The table is rendered procedurally at high resolution; there is **no external image asset or `table_image` field** for this scene. The fixed table has ten text cells, including a two-row header and a two-column header. Replacing cell text through `labels` changes both the source table and recognized output, but its existing crop rectangles do not grow. For longer labels, change `cells`, `textBounds`, and output positions in the renderer too.

## Timing

`timeline` is an ordered list of `{ "at": output_seconds, "reference": source_seconds }` anchors. The renderer linearly interpolates reference time between anchors, then evaluates the original stage animations at that time. Keep at least two anchors; `at` values must strictly increase, while `reference` values should stay nondecreasing. Repeat a reference value at a later output time to insert a hold. The renderer does not validate malformed anchors. Update the last `at`, `poster_time`, and `preview_times` when changing duration. The empty `timing` object is reserved and is not read for event timing by this renderer.

The default maps output/reference times as `0→0`, `6→10`, `16→26`, `24→38`. Reference time is the clock used by the renderer, not an additional movie duration.

| Reference seconds | Visible action |
| --- | --- |
| 0–2.3 | Read the source table; move it left. |
| 2.3–7.8 | Draw curved branches, reveal modules, and connect the output. |
| 10.45–14 | Reveal structure and cell locations; annotate merged cells in place. |
| 15.15–24.15 | Crop and recognize cells; retire the temporary OCR work row. |
| 24.2–25.1 | Spread recognized words through the content module. |
| 27–35.2 | Carry structure and words into the final table. |
| 35.2–38 | Hold the assembled result. |

## When to edit source

This is a reusable **fixed dependency graph**, not an arbitrary graph-layout engine. Edit `runtime/renderers/table-modules.swift` to change module count, dependency routing, table geometry, crop order, assembly order, or layout. Module rectangles, `curvedBranch`, `cells`, `cropStarts`, `assemblyStarts`, and the compact/expanded content positions are the main control points. Keep each arrow tangent continuous into its head and preserve the location→crop→recognition dependency when retheming the example.

## Layout and theme limits

Geometry uses a 1920×1080 design canvas and scales with the output dimensions. The renderer currently reads `theme.background` and `theme.foreground`; the other embedded theme fields are project metadata, not controls for this renderer. Semantic colors, line widths, font sizes, and font choices live in the Swift source. Text is drawn at fixed sizes: it does **not** automatically wrap or shrink. Keep replacements short and inspect every affected stage.

## Provenance

Renderer lineage is recorded in `assets/research/provenance.json`. The optional historical snapshot is `assets/reference/recipes/branch-and-merge.swift.txt`; it is a local reference, not a runtime dependency. Everything required by this demo is in the project. Values are a synthetic teaching example, not clinical data or an empirical model result.
