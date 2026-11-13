# Replace movies without rebuilding a tuned Keynote deck

Use this recipe when a new encoded movie should replace an existing movie while keeping the slide's native titles, notes, crops, geometry and layering. It requires one existing movie per target slide. Resolve each slide number against the **latest saved deck** before supplying the mapping.

The helper creates a new review copy. It never overwrites the source or promotes the copy to the final deliverable automatically. An unmodified open source can stay open; unsaved source edits must be saved first. Keep the copied window free of manual editing while automation runs.

## Plan, then apply

From the repository root:

```sh
python3 -m runtime.keynote_media --help
python3 -m runtime.keynote_media --deck my-project/output/talk.key \
  --slide 5 --movie my-project/build/motion/trace/movie.mp4 \
  --duration 36 --poster 34
```

The default prints a read-only plan. This is a mapping check, not a new approval requirement when the user has already requested the revision. Add `--apply` to create and edit the review copy. `--output my-project/review/talk-media-review.key` can choose its location; that path and its review sidecars must not exist. Otherwise a unique filename is generated beside the source.

For multiple movies, save a JSON mapping such as `my-project/review/movie-replacements.json`:

```json
[
  {"slide": 5, "movie": "../build/motion/trace/movie.mp4", "duration": 36, "poster": 34},
  {"slide": 8, "movie": "../build/motion/compare/movie.mp4", "duration": 38, "poster": 36}
]
```

Movie paths are relative to the mapping file, not the current shell directory.

```sh
python3 -m runtime.keynote_media --deck my-project/output/talk.key \
  --map my-project/review/movie-replacements.json --apply
```

`duration` is the full encoded length in seconds. The helper checks it against AVFoundation metadata before importing; it does not trust an old render manifest. Choose a stable, readable poster with complete labels, not a frame midway through zooming. Whole-second or frame-aligned poster timestamps are easiest to inspect.

## Why this follows the native Replace path

Deleting and recreating the movie can alter its layer order and geometry. Native **Format → Movie → Replace** preserves the existing object. The tested interaction sequence adds several details that are easy to miss:

- Resolve the document by full filesystem path before each native edit. Use a unique window name for Accessibility operations; a matching basename alone is insufficient.
- An imported 4K movie may open a compatibility warning. Clear the recognized warning with **OK**, preserving the file. Do not optimize/downsample it. An unexpected dialog stops the adapter.
- Wait until import sheets disappear **before sending Keynote AppleEvents**. A synchronous AppleScript `save` during import was observed to wait indefinitely on Keynote's document serialization. Use UI Cmd-S after import settles instead.
- Assign file-picker paths through Accessibility and trigger a reversible edit event; a stream of simulated keystrokes can lose characters.
- Set the poster through its native slider, deselect/reselect the movie, and re-read the time. Typing a poster time can appear correct while leaving the saved poster unchanged.
- Reset the trim to the new movie's entire duration. Replacing a shorter clip with a longer one must not retain the old end time.
- Movie autoplay and slide advance are independent. This recipe turns off **Start movie on click**, turns off cross-slide movie playback, and requires manual slide advance. It refuses an automatically advancing source slide rather than silently changing its transition.

The UI adapter targets the English Movie inspector observed in Keynote 14.4. Other versions or languages may need selector adaptation. It fails on missing controls or unexpected modals, and never kills or restarts Keynote. After an error, inspect the retained review copy and report before retrying; do not blindly repeat the whole import.

## What the helper proves—and what still needs viewing

The `.media-review.json` report records actual movie metadata, requested trim/poster settings, native checks, and the exact embedded media hash. A renamed file inside `Data/` is fine; its bytes must match the intended encoded source. Native before/after snapshots compare text, notes, styles, geometry, images, shapes and transitions, excluding the intentionally replaced movie filename. If the source changes during the run, the helper retains both versions and stops short of declaring the review copy ready.

The helper does **not** decode every video frame, judge the poster composition, verify dark-mode notes readability, or watch the movie run. Finish with these targeted checks:

1. Run the movie verification described in [motion](motion.md), including focused samples around the affected movement or state-change boundary.
2. Inspect native slide previews with title overlays and page numbers. A correct movie can still be covered by a native object or end on a cropped label.
3. Play the slide from entry and wait beyond the movie duration. Confirm that the video starts automatically, holds its end state, and stays on the same slide.
4. Review the copied deck, then publish it through the current project's normal latest-version check. The source may have gained new manual edits since copying.

Portable wrapper tests use temporary files and mocked native calls. A native end-to-end smoke check on English Keynote 14.4 replaced a bundled 12-second clip with a 24-second clip in a new disposable deck. It verified the compatibility-dialog path, full trim, a persisted 22-second poster, autoplay, manual slide advance, unchanged native title/notes/geometry, unchanged source bytes, and the exact embedded movie hash. Existing user decks remained open and unchanged. This verifies native settings and preservation; it does not replace visual playback review.

To repeat that regression on a Mac with Automation and Accessibility access, explicitly opt in:

```sh
SLIDE_STUDIO_KEYNOTE_MEDIA_SMOKE=1 python3 -m unittest tests.test_keynote_media.NativeMediaSmokeTests -v
```

The native test creates its own source and review deck under `build/keynote/media-smoke/` using bundled scene movies. It does not accept a user deck or close unrelated documents. Run it only when no other automation is controlling Keynote. A fresh Keynote version or UI language still needs this check before use.
