# Editable Keynote starter

`anthony-dark-template.key` contains eight native layouts: opening, bridge question,
comparison, roadmap, paper cover, takeaway, impact, and acknowledgements. They use
large editable text, charcoal backgrounds, off-white text, and three semantic accents.
The cover uses initials in place of private photos. It is a `.key` starter deck,
not an installed `.kth` theme and not a screenshot deck.

Rebuild it from this repository with:

```sh
python3 templates/keynote/build_template.py
```

The source is `template-manifests.json`, generated from the shared layout functions.
The adjacent `.bindings.json` associates each slide's stable semantic ID with its
notes. Keep it with the generated deck when working through the adapter.

## Native objects and limits

- Each explicit text line is a native text box. Its font, color, position, and content
  remain editable in Keynote. This also avoids inherited Keynote paragraph spacing.
- Backgrounds, rounded panels, circles, and arrows are separate PNG objects, not a
  flattened slide. Their editable source geometry lives in the JSON manifest.
- Photos preserve their aspect ratio and are centered within their slots. Circle
  crops support normalized `focal_x`, `focal_y`, and optional `zoom`, so a person's
  head can be centered even when the original photo is not. The source is untouched.
- Movies are embedded as native movie objects. Labels inside a rendered movie are
  changed in the scene configuration and re-rendered, not edited as Keynote text.
  Keynote uses its default movie poster; a custom poster image is used by the
  preview gallery, not injected through an unsupported native property.
- Keynote's native scripting API does not expose movie-start or object-build timing.
  For each imported movie, deselect **Start movie on click** in **Format → Movie**,
  then test in presentation mode. Keep slide advance **On Click** unless the script
  explicitly calls for a continuous sequence. The build report lists every movie
  that needs this check.

## Notes and manual edits

Notes are written as native 25pt rich text. `**Emphasis**` becomes native bold; native
black is set last so Keynote can render readable text in its dark notes editor.
Check one page in your own Keynote version before a presentation.

`runtime.keynote.update_notes` changes notes only and locates slides by a stable ID
stored in the locked background image's accessibility description. Reordering slides
is safe. Removing or duplicating the marker is reported as a conflict. If a person
has edited a note since the last baseline, the entire request stops before any note
changes. Resolve the mismatch deliberately using `expected_old`; never replace an
unrelated slide based only on its current page number.

Visual changes made manually in Keynote are not imported into the JSON source.
A fresh assembly creates a fresh document. Existing output requires explicit
`overwrite=True`, and an open output is never overwritten. Rebuild into a new path
when you want to compare against manual visual edits.

Native assembly requires macOS and Keynote. Circle masking uses the macOS Swift/AppKit
helper. The renderer itself has no third-party Python package dependency.
Native PNG export is available for inspection; PDF export is not part of the default
workflow.
