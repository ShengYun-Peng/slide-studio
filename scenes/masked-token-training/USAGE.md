# Predict masked visual tokens

Step 2 begins with the full image and a **frozen tokenizer** to obtain target visual tokens. A separate, trainable visual encoder sees a masked image and predicts the missing tokens. Only masked positions contribute to the comparison, and the feedback updates only the visual encoder. Introduce the visual vocabulary with `learn-visual-vocabulary` first.

## Run and inspect

From the repository root on macOS, compile this scene's actual renderer:

```sh
swiftc runtime/renderers/research-training.swift -o /tmp/slide-studio-masked-token-training
/tmp/slide-studio-masked-token-training --config "$PWD/scenes/masked-token-training/scene.json" --output "$PWD/scenes/masked-token-training/demo" --video
```

Use `--preview` instead of `--video` for stills. Both modes produce `poster.png`, `end.png`, `contact-sheet.png`, and `render-manifest.json`; video mode also produces `movie.mp4`. The current demo is **1920×1080, 60 fps, 16 seconds**. Review the decoded movie as well as the poster, especially arrow endpoints, small labels, and the final hold. In Keynote, autoplay the movie while keeping slide advancement manual unless continuous advancement is intentional.

## What JSON changes

- `content.title`: the main takeaway.
- `content.table_image`: readable image path, resolved **relative to the scene JSON file**, or an absolute path for a local experiment. The portable default is `../../assets/research/toy-table.png`; keep shared replacements inside the project.
- `content.token_ids`: optional twelve target labels in row-major order; default `["A","B","C","A","D","B","A","C","B","D","C","A"]`.
- `content.predictions`: optional twelve predicted labels; default `["A","C","C","A","D","B","B","C","B","A","C","A"]`. Only masked positions are shown as predictions. Keep at least one visible mismatch if the explanation needs a training signal.
- `content.masked_positions`: zero-based cell indices in the 4×3 grid, default `[1,4,6,9,10]`. Use unique integers from 0 to 11. The same selection controls image masks, target emphasis, and prediction visibility.
- `content.labels`: exact source-string replacements. The default maps `Target token IDs` → `Target visual tokens` and `Predicted token IDs` → `Predicted visual tokens`. Other useful keys include `Frozen tokenizer`, `Masked table`, `Visual encoder`, `Trainable`, `Compare only`, `masked positions`, and `Update visual encoder only`. Each line of a multi-line caption is a separate string.
- `timeline`, `duration`, `fps`, output dimensions, `poster_time`, and `preview_times` control timing and delivery.

Supply exactly twelve entries for both token arrays; the source indexes them directly and does not validate their lengths. These letters are illustrative targets and predictions, not results of tokenizing the supplied image. Changing text labels does not change which components are frozen or trained.

## Timing

`timeline` is an ordered list of `{ "at": output_seconds, "reference": source_seconds }` anchors. The renderer linearly interpolates reference time between anchors, then evaluates the original stage animations at that time. Keep at least two anchors; `at` values must strictly increase, while `reference` values should stay nondecreasing. Repeat a reference value at a later output time to insert a hold. The renderer does not validate malformed anchors. Update the last `at`, `poster_time`, and `preview_times` when changing duration. The empty `timing` object is reserved and is not read for event timing by this renderer.

The default is `0→0`, `16→16`.

| Reference seconds | Visible action |
| --- | --- |
| 0–4.1 | Full image → frozen tokenizer → target tokens. |
| 4.4–6.6 | Copy the image downward, cover selected patches, and reveal the trainable encoder. |
| 7.8–9.1 | Show predictions at masked positions. |
| 9.6–11.3 | Emphasize corresponding targets and predictions; compare masked positions only. |
| 11.5–14.6 | Draw the feedback route and update the visual encoder only. |
| 14.6–16 | Hold the complete training loop. |

## Fixed topology and mask semantics

The image and token grids have **4 columns × 3 rows**. Opaque teal masks cover the shared border underneath; letters sit on top and remain readable. Purple marks the trainable path. Keep these roles distinct from downstream task colors.

The image is stretched into the original 380:288 aspect ratio. Prepare a matching image or edit image rectangles in `pretrain` to avoid distortion. To change grid dimensions, loss geometry, topology, colors, or feedback routing, edit `runtime/renderers/research-training.swift`; updating JSON array lengths alone cannot change the grid. Recheck `grid`, `maskImage`, and `pretrain` together so targets and masked image patches stay aligned.

## Layout and theme limits

Geometry uses a 1920×1080 design canvas and scales with the output dimensions. The renderer currently reads `theme.background` and `theme.foreground`; the other embedded theme fields are project metadata, not controls for this renderer. Semantic colors, line widths, font sizes, and font choices live in the Swift source. Text is drawn at fixed sizes: it does **not** automatically wrap or shrink. Keep replacements short and inspect every affected stage.

## Provenance

See `assets/research/provenance.json`. The optional historical source `assets/reference/recipes/masked-token-training.swift.txt` contains both training steps; it is not a runtime dependency. The runnable version uses only the packaged table image and project code. All token values are synthetic teaching data.
