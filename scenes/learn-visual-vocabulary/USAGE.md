# Learn a visual vocabulary

Step 1 shows an unlabeled table image passing through a tokenizer encoder, a learned visual vocabulary, discrete visual tokens, and an image decoder. Comparing the reconstruction with the input produces an error that updates the encoder, vocabulary, and decoder together. Use this before `masked-token-training` to explain where that scene's targets come from.

## Run and inspect

From the repository root on macOS, compile this scene's actual renderer:

```sh
swiftc runtime/renderers/research-training.swift -o /tmp/slide-studio-learn-visual-vocabulary
/tmp/slide-studio-learn-visual-vocabulary --config "$PWD/scenes/learn-visual-vocabulary/scene.json" --output "$PWD/scenes/learn-visual-vocabulary/demo" --video
```

Use `--preview` instead of `--video` for stills. Both modes produce `poster.png`, `end.png`, `contact-sheet.png`, and `render-manifest.json`; video mode also produces `movie.mp4`. The current demo is **1920×1080, 60 fps, 16 seconds**. Review the decoded movie as well as the poster, especially arrow endpoints, small labels, and the final hold. In Keynote, autoplay the movie while keeping slide advancement manual unless continuous advancement is intentional.

## What JSON changes

- `content.title`: the takeaway above the diagram.
- `content.table_image`: image path resolved **relative to the scene JSON file**, or an absolute path for a local experiment. The portable default is `../../assets/research/toy-table.png`. Keep shared assets inside the project. The image must exist and be readable; the renderer does not recover from a missing asset.
- `content.token_ids`: optional twelve short labels in row-major order, default `["A","B","C","A","D","B","A","C","B","D","C","A"]`. Supply exactly twelve entries. The vocabulary illustration itself still shows A–D, so keep those symbols unless adapting the source too.
- `content.labels`: optional exact source-string replacements, for example `{"Tokenizer":"Image tokenizer", "Soft selection":"Soft assignment", "Reconstruction":"Reconstructed image"}`. Multi-line labels use one entry per displayed line. This map changes text, not the data flow or image pixels.
- `timeline`, `duration`, `fps`, output dimensions, `poster_time`, and `preview_times` control timing and delivery.

There are no semantic fields named `encoder`, `token_label`, `output_label`, or `takeaway`. Use `labels` for existing words. `predictions` and `masked_positions` belong to the second training scene and do not change the visible first-step diagram.

## Timing

`timeline` is an ordered list of `{ "at": output_seconds, "reference": source_seconds }` anchors. The renderer linearly interpolates reference time between anchors, then evaluates the original stage animations at that time. Keep at least two anchors; `at` values must strictly increase, while `reference` values should stay nondecreasing. Repeat a reference value at a later output time to insert a hold. The renderer does not validate malformed anchors. Update the last `at`, `poster_time`, and `preview_times` when changing duration. The empty `timing` object is reserved and is not read for event timing by this renderer.

The default is `0→0`, `16→16`, so output seconds equal reference seconds. To shorten the explanation without rushing the error/update stage, add intermediate anchors around reference 8.5 and 11 rather than scaling every stage equally.

| Reference seconds | Visible action |
| --- | --- |
| 0–3 | Input image → tokenizer encoder → visual vocabulary. |
| 3–6.2 | Soft selection produces the 4×3 token grid. |
| 6.2–8.3 | Decoder reconstructs the table. |
| 8.5–10 | Input and reconstruction appear side by side; show reconstruction error. |
| 10.4–14.4 | Error returns along the feedback path; update encoder, vocabulary, and decoder. |
| 14.4–16 | Hold the complete training loop. |

## Fixed topology and asset preparation

The diagram has six fixed stages, four vocabulary entries, and a **4-column × 3-row token grid**. Token letters and activity are illustrative, not computed by a trained tokenizer. Both the input and reconstructed image are the provided image; the animation teaches the training objective rather than simulating reconstruction quality.

The source table has aspect ratio 380:288. Images are drawn into that ratio without automatic fit/crop, so prepare a matching image or change the rectangles in `learnCodebook` to avoid distortion. Use `runtime/renderers/research-training.swift` to change topology, vocabulary size, image geometry, stage labels' placement, or the comparison/feedback paths. Keep each label readable before the related movement starts.

## Layout and theme limits

Geometry uses a 1920×1080 design canvas and scales with the output dimensions. The renderer currently reads `theme.background` and `theme.foreground`; the other embedded theme fields are project metadata, not controls for this renderer. Semantic colors, line widths, font sizes, and font choices live in the Swift source. Text is drawn at fixed sizes: it does **not** automatically wrap or shrink. Keep replacements short and inspect every affected stage.

## Provenance

See `assets/research/provenance.json` for source lineage and the packaged table asset. Both training scenes derive from the optional historical recipe `assets/reference/recipes/masked-token-training.swift.txt`, whose original source contained both steps. That archive is not needed to render. The table and token sequence are synthetic teaching examples.
