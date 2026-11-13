# Visual design profile

The default is a spacious research talk viewed from the back of a room. It should feel composed and continuous, with one obvious place to look. Adapt the profile for other audiences or output formats instead of treating every number below as universal.

## Defaults, preferences, and correctness

| Category | Meaning | Example |
|---|---|---|
| Correctness constraint | Changing it can mislead or break the presentation | A plotted curve preserves its data; an arrow reaches the intended node |
| Default profile | A useful starting value that can change together | Graphite background, 1920 × 1080 canvas, three accent colors |
| Editorial preference | A strong starting preference, relaxed when content requires it | One-line takeaway titles; short pure-bullet takeaways |
| Talk-specific fact | Belongs to the current research and speaker | Paper count, author order, award, venue, impact number |

The bundled theme uses:

| Role | Default |
|---|---|
| Background | `#2B2B2D` |
| Foreground | `#F6F6F4` |
| Secondary readable text | `#BAC1CC` |
| Panel | `#36383D` |
| Part accents | `#7ABC73`, `#66A7FF`, `#FFB253` |
| Font | Helvetica Neue; bold variant for emphasis |
| Title / body / label / caption | 72 / 56 / 50 / 50 logical units on 1920 × 1080 |
| Diagram line | 6 logical units |
| Presenter notes | 25 pt |

The theme file is the source of truth. For the Anthony conference profile, use **50 logical units as the floor for text the audience needs to read**, including diagram labels and captions. Page numbers and secondary source references may be smaller if they carry no part of the argument. This is a profile preference, not a universal rule for every format.

The same reading test applies inside images and videos: a 12 px interface label can become readable through a focused camera view; a tiny label in a full-interface overview is context, not evidence the audience is expected to read. Higher pixel resolution makes text sharper but does not make it larger on the slide. Some existing scene renderers have their own type sizes, so changing a theme does not establish that every movie label follows it.

If the composition does not fit at that scale, remove secondary material, shorten a label, enlarge the figure, or split the slide. Do not solve density with a cloud of small, pale phrases. One large visual and one useful caption usually give the eye a clearer path than several equally weighted text islands.

## Titles and hierarchy

A title should tell the audience what the slide contributes. Prefer “Token-level safety signals preserve more useful data” over “Method” when the evidence supports that claim. Method overviews can use a precise descriptive title before the result is established; not every slide needs to announce a discovery.

Use the actual visible problem or action rather than an abstract slogan. A motivation page dominated by equations can say “These objectives are hard to understand from equations alone.” A tool demonstration can say “Click a token to see its learning signal.” Do not use a title about a reward curve when the visual is really showing hard-to-read mathematics. A strong title is direct and source-supported; it need not exaggerate the contribution.

Try a readable one-line title first. Remove redundant setup, use a familiar short expression, and consider `&` where appropriate. When wrapping is needed, use an intentional two-line title with the same vertical anchor and line height as adjacent slides. Do not let a title jump down because it changed layout family.

Use bold for hierarchy or semantic emphasis, not randomly on every other slide. Keep equivalent prompt/response labels, caption roles, and model names styled consistently. A long sentence can be bold as the central mission; detailed explanations usually cannot sustain that weight.

## Semantic color

Maintain a short color-role map in the current project. Part colors can carry through its title, roadmap, paper covers, takeaways, and question prompts. Use separate roles for safe/unsafe, baseline/proposed method, measured/illustrative data, and pretraining/task-specific outputs. Do not reuse an accent for a conflicting meaning within the same sequence.

A staged mission starts neutral. As each concept appears, color its matching word and reveal its connector. Preserve color semantics across the following framework and portfolio sequence. Icons, legs, and outer rings should look like one family, including their saturation and line weight.

Colors need sufficient contrast in the final render. A saturated dark green can disappear on graphite even if its role is correct. Brighten the foreground or add a restrained light inset rather than outlining every glyph with a white halo.

## Layout families

See [catalog.json](../templates/layouts/catalog.json) for the renderer's ten content layouts. The following are compositional recipes within those families:

- **Mission:** a large stable statement, two lines when needed; parts emerge from words without displacing the statement.
- **Roadmap:** a part icon and title establish the group; papers are indented beneath it; descriptions share a clear column and baseline. Darker part labels can separate “Part II” from the bright subject title. When horizontal space is tight, stack parts vertically and use available height.
- **Paper cover:** shorthand, full title, face-centered author circles, names, venue, and small recognition badge. Use one author row where readable; otherwise two deliberate rows. Avoid adding the whole method on the cover.
- **Comparison:** align related images, use the same display scale where meaningful, and attach captions to the actual image centers. A change in image dimensions should have a scientific reason.
- **Result table:** show the relevant baselines, mute secondary values, and accent the proposed method or key contrast. Preserve row heights and column widths between builds.
- **Takeaway:** a few direct bullets, each a complete contribution or consequence. Do not attach a second explanatory line in a smaller font to every bullet.
- **Impact:** group verified evidence by contribution. Reveal recognition, part-specific effects, and aggregate numbers in the chosen spoken order; avoid a dense page that requires reading in several directions.
- **Acknowledgements:** clear face/name pairing for people; a prioritized collage for memories; a restrained logo grid for institutions. Different social purposes deserve different layouts.
- **Q&A:** a very large short topic cue as a navigation slide, then a visual answer with a short answer first. Use question associations in notes or a secondary area only when requested.

## Figures on a dark canvas

Inspect axes, tick labels, legends, annotations, thin borders, and transparent regions. A figure can look fine as a thumbnail while its actual labels disappear during projection. Transparent conversion alone does not solve a white-background figure.

Three valid treatments are:

1. Redraw the supporting text and geometry with the talk's style while preserving data.
2. Keep the scientific image intact inside a clean light panel and adapt its outer labels.
3. Rebuild an explanatory diagram as editable shapes or reproducible code.

Choose the treatment that retains meaning. Heatmaps and attention maps often benefit from option 2. Avoid low-resolution resampling, white speckles left after background removal, gray text on near-black panels, thick white text halos, and gradients that disappear into the slide background.

Keep complete reference tables visible for error comparisons. Annotate a wrong merged cell, row/column assignment, or missing content precisely. For a large complex example, show an overview and an enlarged crop linked to the source region.

A screenshot is a source, not a required layout. When its prose or equation would remain too small, select the needed content and typeset it again as native text or clean math. Preserve notation, values, and provenance; state when an equation is a selected term rather than the full objective. Keep the original screenshot only when its appearance is itself evidence, then provide a readable detail view.

## Learn from a design reference

Inspect a complete sequence, including its expanded and comparison states. Record the transferable decision: where attention starts, which component enlarges, what context remains, how colors keep their meaning, and how one interaction changes the visible evidence. Adapt those decisions to this talk's content and reading distance. Copying a palette or rounded panel alone does not reproduce the reference's clarity.

For interactive research projects, see [interactive talks](interactive-talks.md). Favor one continuous example and progressive detail over a tour of unrelated screenshots. A polished interface may still need much larger framing for a conference audience.

## Diagram geometry

Anchor arrows to objects, not to visually guessed coordinates. Use consistent clearances between an arrow and the box boundary. Curved connectors are useful when three branches would otherwise overlap: keep the middle connection horizontal where natural, with symmetric top/bottom branches. The arrowhead must follow the endpoint tangent and connect to the line without a notch or gap.

Measure group bounds, not only individual nodes. Encoder and decoder groups should be centered as a composition. Align table baselines, output boxes, captions, and labels to their own related objects. Avoid a caption that is mathematically centered on a column but visibly left of its image.

For token and masked-cell diagrams, use inner borders or gutters so adjacent semantic colors do not fight over one shared edge. A masked patch should fully cover its intended region. Its fill, border, and center glyph should read as one object; leftover edge fragments suggest an error.

## People, logos, equations, and details

For circular headshots, locate the head and eyes, then crop to fill. The source photo's geometric center is often not the person's center. Check both the top of the head and face position after the mask. Center the name beneath the circle, and keep spacing uniform across the row. The same treatment can make the opening author credits more readable and personal; preserve author order, and use two rows when a single row would shrink the names.

Use accurate logo variants with a source record. Awards, oral icons, stars, and company logos have different roles; align them with stable title or end-of-row anchors so they do not compete. Prefer a recognizable simple solid icon over a decorative symbol that needs explanation.

Use true mathematical notation where the notation helps: correct Greek glyphs, deliberate italic variables, consistent operator spacing. Simplify equations to the mechanism the audience needs; move ranges and secondary definitions to backup. A one-line explanation of what a bound guarantees is more useful than displaying a large formal expression with no interpretation.

Keep page numbers away from critical video content and omit the number on the title slide by default. Check for redundant text boxes after import, but do not delete an apparently empty object until confirming it is not a deliberate animation or mask component.
