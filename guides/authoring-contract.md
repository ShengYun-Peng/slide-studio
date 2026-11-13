# Authoring contract

This describes the current local renderer, not a promise that arbitrary presentation features are supported. The JSON schemas and runtime are the final reference when extending the project.

## Project files

`project.json` identifies the talk:

```json
{
  "schema_version": 1,
  "title": "Your talk title",
  "theme": "anthony-dark",
  "duration_minutes": 20,
  "speaking_wpm": 140,
  "storyboard": "storyboard.json"
}
```

The speaking rate is a planning input, not an assertion about the presenter. `storyboard.json` has one `slides` array. Each slide needs a unique lowercase semantic `id`, a supported `layout`, and a relative `notes` path. IDs begin with a letter and use letters, digits, or hyphens; use descriptive IDs rather than page numbers.

Notes files contain spoken text. Do not put Markdown headings, editorial comments, or production instructions in those files. Selective `**bold**` emphasis is supported: native assembly strips the delimiters and applies actual bold font ranges, then applies the configured notes size and native adaptive color. Other Markdown formatting is not a general rich-text interface.

## Slide fields

Common fields include `title`, `subtitle`, `body` (an array of strings), `part` (a zero-based color index), and `page_number` (boolean). A field's effect depends on the chosen layout. Do not assume that adding an arbitrary field changes the output.

| Layout | Fields used by the built-in composition |
|---|---|
| `title` | `eyebrow`, `title`, `subtitle`, `presenter` |
| `question` | `eyebrow`, `title`, `subtitle`, `part` |
| `bullets`, `takeaway` | `title`, `subtitle`, `body`, `part` |
| `comparison` | `title`, `subtitle`, up to two `columns`, each with `title`, `body`, and optional `image` |
| `roadmap` | `title`, `subtitle`, `parts`, optional `active_part`; each part has `title` and `papers` with `title` and `detail` |
| `paper-cover` | `title`, `subtitle`, `part`, `authors`, `venue`; each author has `name`, optional `portrait`, `focal_x`, `focal_y`, `initials`, and `presenter` |
| `impact` | `title`, `subtitle`, up to three `columns` with `title` and `body`, optional `footer` |
| `acknowledgements` | `title`, and either up to four `images`, or `subtitle` plus `body` |
| `scene` | `scene.template`, `scene.overrides`; the scene owns its full-slide visual and labels |

The layouts are intentionally simple and inspectable. Their source is `runtime/layout.py`. For a custom composition, adapt that renderer or supply explicit native `items`; do not expect a metadata field named `assets` to place media automatically. `comparison`'s optional image occupies its content area, so avoid simultaneously filling the same area with a long body.

Paper-cover portraits use circular crops. Set `focal_x` and `focal_y` as normalized source-image coordinates between 0 and 1 to place the face in the center of the crop; both default to 0.5. This is an explicit focal point, not automatic face detection. The macOS PNG and native Keynote paths honor those coordinates. The portable SVG-only fallback uses a centered fill crop, so inspect the native preview when a face is off-center in its source photo.

## Custom editable items

An `items` array appends native objects to the layout. Use it for simple diagrams or additions that need direct Keynote editing. Coordinates use the theme canvas, normally 1920 × 1080.

```json
{
  "type": "text",
  "text": "A readable label",
  "x": 140,
  "y": 280,
  "w": 800,
  "h": 90,
  "size": 56,
  "font": "HelveticaNeue",
  "color": "#F6F6F4",
  "bold": false,
  "align": "left"
}
```

Other supported primitive types are `rect`, `ellipse`, `line`, and `image`. Shapes use `fill`, `stroke`, and `stroke_width` where relevant; rectangles can have `corner_radius`. Images use a project-relative `path`, with optional `mask: "circle"`, `focal_x`, and `focal_y` for the supported crop. A line uses its `x`, `y` as the start and `x + w`, `y + h` as the end. Curved arrows require a suitable source asset, scene renderer, native extension, or more capable adapter; a straight line primitive is not a curve.

In native Keynote, text is editable text. Shapes/connectors are separate PNG primitives that can be moved and resized; their vector geometry is edited through source manifests and regenerated. A movie is a native movie object, not a collection of editable slide shapes.

Because items are appended, they do not erase the layout's built-in objects. Inspect the resulting manifest and preview if constructing a substantially custom page. The scene layout has no built-in title or page number, which avoids duplicating labels over a full-screen movie.

Theme `min_readable_size` controls warnings for audience-read text; the Anthony dark profile uses 50 logical units. Custom text items keep their explicit size so validation can expose undersized content rather than silently enlarge it into an overlap. `reading_role` defaults to `primary`; `page-number` and `reference` are reserved exemptions for navigation and nonessential source citations. Never use these roles to hide a small result, label, or explanation from the check. Raster text and movie labels still need visual review.

## Scene configuration

A slide can bind a catalog scene:

```json
{
  "id": "framework-reveal",
  "layout": "scene",
  "notes": "notes/framework-reveal.md",
  "claim_type": "illustrative",
  "scene": {
    "template": "framework-to-portfolio",
    "overrides": {
      "duration": 8,
      "content": {
        "center": "Your mission",
        "parts": ["Observe", "Decide", "Act"]
      }
    }
  }
}
```

Use the selected scene's complete `scene.json` to see its content fields and expected counts. A particular demo can implement a fixed number of branches even if the design concept is general. Changing an unsupported count requires adapting the renderer, not only editing the JSON. Put the title inside scene content when the movie should display it.

For isolated rendering, `--config` supplies a complete scene configuration. For project rendering, `scene.overrides` adapts the catalog template. Check the generated output after any change; successful JSON parsing is not proof that all content fits.

A project-level `duration` override retimes inherited events, poster time, and preview times proportionally. Explicit `timing` values supplied with that override are seconds in the new duration and take precedence. Standalone `--config` is already a complete timeline; out-of-range times are rejected. Device `content.screen_image` paths are relative to the project for project rendering, or to the config's folder for standalone rendering. Absolute resolved asset paths belong only in generated build files.

## Evidence and validation

Set `claim_type` to one of `measured`, `illustrative`, `reconstructed`, `proposed`, or `editorial`. Measured claims need evidence, for example:

```json
{
  "claim_type": "measured",
  "evidence": [
    {
      "source_id": "the-ingested-source-id",
      "locator": "Figure 3, page 6",
      "claim": "The highlighted comparison under the reported budget"
    }
  ]
}
```

Use the source ID produced by ingestion, not this example string. Validation checks file and content structure, approximate bounds, some text contrast/overlap, and missing evidence references. It does not read the paper to prove the claim or validate every layout feature.

Notes-length warnings use starting budgets, not mandatory word limits. Timing uses an approximate overlap between narration and movie duration. Human rehearsal is still required, especially when a clip contains deliberate silent holds or when appendix material is included in the same storyboard.
