# Start here

Slide Studio turns a research story into an editable Keynote presentation, with reproducible source for the animations that are easier to explain as movies. It includes a dark visual profile, layout recipes, an animation catalog, writing guidance, and local build tools.

Give a new agent this folder and a request such as:

> Read START_HERE.md. Use my-project for this talk. I am giving a 25-minute research presentation to engineers about reliable document extraction. My materials are in my-project/sources. Start with the story and a few representative slides, use the dark profile, and adapt the relevant animation demos. Keep the claims grounded in my papers and the notes easy to say aloud.

The agent does not need the original defense folder, previous chat, or personal filesystem paths. It does need to inspect this project and the materials you provide.

## First run

From the folder containing `studio.py`:

```sh
python3 studio.py doctor
python3 studio.py catalog
python3 studio.py --help
```

`doctor` reports which local capabilities are available. Read the reported limitations before promising native output. Python handles the portable project workflow; the bundled movie renderer uses Swift and macOS frameworks. Native Keynote assembly also requires Keynote and local application access.

For the exact options supported by this checkout, use:

```sh
python3 studio.py init --help
python3 studio.py ingest --help
python3 studio.py preview --help
python3 studio.py render --help
python3 studio.py assemble --help
python3 studio.py verify --help
python3 studio.py gallery --help
```

The working folder is named **`my-project`**. Keep input sources, deck content, scene configurations, and generated output in the project locations created by `init`; do not use the library's example content as the user's research. Use `ingest` to register local source material. The CLI help is authoritative for command arguments.

A sample talk is already included in `my-project`. To try that sample, skip `init` and run:

```sh
python3 studio.py validate --project my-project
python3 studio.py preview --project my-project
python3 studio.py render --project my-project --preview-only
python3 studio.py render --project my-project
python3 studio.py assemble --project my-project
python3 studio.py verify --project my-project
python3 studio.py gallery --output review/index.html
```

For your own talk, edit the included `my-project` deliberately, or preserve it under another name and initialize a fresh `my-project`. `init` refuses to replace a populated folder. To initialize into a different empty folder instead:

```sh
python3 studio.py init my-next-talk --title "Reliable Document Extraction" --theme anthony-dark
python3 studio.py ingest /path/to/source.pdf --project my-next-talk --kind auto
```

Replace the source path with a real local file and pass `--project my-next-talk` to later commands. The initialized content is an illustrative garden example: replace its story, notes, scene labels, and assumptions with your researched topic. The agent writes the storyboard and notes between ingestion and validation. These commands do not call a language model or automatically turn a paper into a scientifically verified talk. See the [authoring contract](guides/authoring-contract.md) for actual supported fields.

## Choose a starting route

| Starting point | First useful action | Read |
|---|---|---|
| Topic only | Establish audience, promise, evidence needs, and talk length; draft an argument | [Workflow](guides/workflow.md) |
| Papers, PDFs, figures | Extract claims and figure roles; retain page and source references | [Input materials](guides/input-materials.md) |
| Existing Keynote or PowerPoint | Inventory the current deck and manual edits before adapting | [Review and adaptation](guides/review-adaptation.md) |
| Figma assets | Capture source identifiers plus local exports; preserve meaning and editability where available | [Input materials](guides/input-materials.md) |
| Animation request | Pick a demo family, replace content, then tune timing to narration | [Motion](guides/motion.md) |
| Script revision | Read adjacent slides and introduce the visible evidence before the conclusion | [Spoken notes](guides/spoken-notes.md) |

## The repeatable loop

1. **Understand the talk.** Record audience, purpose, duration, sources, and what must stay unchanged. Map the argument before numbering slides.
2. **Choose a visual profile and patterns.** Start with `templates/themes/anthony-dark.json`, `templates/layouts/catalog.json`, and the scene catalog. Use the gallery to compare representative demos.
3. **Make a small coherent slice.** Build an opening, a method sequence, a result, and a takeaway. Check the style and level of detail before scaling out.
4. **Build the full story.** Keep claims, diagrams, notes, and scene timing linked by semantic IDs. Use native objects for text and simple diagrams; use movies when continuous motion makes the method clearer.
5. **Validate, preview, render, and assemble.** Use the CLI commands for the project and supported scene formats. Rendering a scene does not by itself assemble or validate a native slide.
6. **Review at presentation scale.** Inspect title and body alignment, figure legibility, scientific fidelity, notes visibility, movie boundaries, and actual playback. Rehearse to calibrate time.
7. **Deliver a clean project.** Keep the final `.key` easy to find; preserve raw material, editable sources, and rendering settings separately. Do not export a PDF or PPTX for every revision unless requested.

## What to adapt, what to preserve

The default profile uses a 1920 × 1080 canvas, graphite background, off-white text, three semantic accents, large type, and 25 pt presenter notes. These are defaults for a spacious research talk. The number of parts, their colors, venue conventions, speaker identity, and exact duration belong to the current project.

Preserve these regardless of style: accurate claims, visible evidence, clear reading order, consistent semantic colors, useful transitions, spoken-only notes, reproducible inputs, and honest verification status.

See [visual design](guides/visual-design.md) for the profile, [lessons learned](guides/lessons-learned.md) for concrete before/after decisions, and [the Chinese review guide](guides/review-zh.md) for a compact review path.
