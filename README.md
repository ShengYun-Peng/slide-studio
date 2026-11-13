# Slide Studio

A local, agent-readable studio for research talks: clear storytelling, editable
Keynote slides, spoken notes, and short code-rendered animations. It extracts the
reusable patterns from a heavily rehearsed thesis defense without depending on
that thesis, its temporary files, or its private chat history.

Start with **[START_HERE.md](START_HERE.md)**. Open **[the demo gallery](review/index.html)**
in a browser to choose a motion pattern. The included **[my-project](my-project/brief.md)**
is your current presentation folder; its urban-garden content is an illustrative
example you can replace.

The gallery now contains **16 motion patterns plus a Tesla AI reference variant**.
Legacy demos use **1920 × 1080 at 60 fps**; the new interface walkthrough uses
**3840 × 2160 at 60 fps** with lossless source states and a single camera. The second pass
restores more of the defense's production detail: registered photographic
hardware, the crop-dependent modular sequence, richer training diagrams, and
vector-derived cinematic edge light. Reusability comes from separating the
content, timing, assets, and renderer—not from replacing every visual with a
generic box. See [the pattern guide](guides/motion-patterns.md) to choose a useful
animation before changing its content.

```text
slide-studio/
├── START_HERE.md / AGENTS.md / SKILL.md   # entry points for humans and agents
├── guides/                              # story, design, scripts, motion, QA, lessons
├── templates/                           # theme tokens, layouts, native Keynote sample
├── scenes/                              # 16 patterns + Tesla variant: config, demo, usage
├── assets/                              # reusable assets and provenance
├── runtime/                             # Python orchestration + catalog-selected Swift renderers
├── studio.py                            # one CLI, no API key required
├── schemas/                             # portable content/config contracts
├── examples/urban-gardens/               # clean example on a different topic
├── my-project/                          # your current brief, sources, story, notes
│   ├── project.json / storyboard.json
│   ├── notes/                           # spoken words only
│   ├── production.md                    # timing and editing comments
│   ├── sources/ / derived/              # originals and read-only extraction
│   ├── build/                           # regenerable previews and media
│   └── output/                          # final native Keynote
├── review/                              # gallery and local verification report
└── tests/                               # meaningful pipeline and adapter checks
```

From this folder:

```sh
python3 studio.py doctor
python3 studio.py validate --project my-project
python3 studio.py preview --project my-project
python3 studio.py render --project my-project
python3 studio.py assemble --project my-project
python3 studio.py verify --project my-project
python3 studio.py gallery
```

`assemble` refuses to replace an existing output by default. After manual editing,
use the Keynote adapter's safe notes-update workflow or build to a new filename;
do not regenerate over the only edited copy.

For interactive system talks, follow [the tool-talk route](guides/interactive-talks.md)
and adapt [interface-tour](scenes/interface-tour/USAGE.md). The Anthony dark
profile uses 72/56/50/50 typography, with 50 as the minimum for core reading text.
For movie-only revisions, use [the native media replacement helper](guides/keynote-media.md)
to work on a review copy and verify full trim, poster, autoplay, and embedded bytes.

**What is portable:** documentation, JSON plans, source ingestion, validation,
and SVG previews use Python 3.9+ and its standard library. There is no hidden
LLM service: an agent researches and writes the content, then uses these tools.

**What needs a Mac:** native PNG/movie rendering uses Swift and Apple's graphics
frameworks; editable `.key` assembly needs Keynote and Automation access. Movie
autoplay must be checked in Keynote because its AppleScript interface does not
expose that setting. Slide advance should remain manual unless intentionally
configured otherwise. See the adapter's capability report rather than assuming
all animations have been wired automatically.

**Source intake:** PDF text/page previews, PPTX text/media, Keynote originals and
embedded previews, images, video, plain text, and Figma/web references. Intake
does not magically reconstruct every original layout or animation. A Figma URL
needs a connected read tool or exported SVG/PNG/PDF to supply actual content.

**Reproducibility:** scene parameters and timing drive each frame. Keep the source,
configuration, asset hashes, and environment report. Matching visuals is the goal;
movie bytes may differ across hardware/OS encoders. Every new topic still needs
evidence checking, visual review, and a rehearsal.

**Renderer selection:** `scenes/catalog.json` maps each scene ID to its Swift
renderer. Use `studio.py render` so the correct implementation and assets are
selected. Some patterns share the base renderer; the device, modular table,
training, video-budget, new presentation patterns, and cinematic title use
specialized renderers. A project-level duration override retimes inherited event
times together; a complete standalone config must contain its own valid schedule.

**Sharing and asset provenance:** most demos use
procedural graphics or packaged teaching assets. The high-fidelity device demo
uses Apple hardware footage, and the Tesla reference variant uses the Tesla logo
and Cybercab footage; these are explicitly marked local-review media, with no
redistribution clearance implied. Their provenance and the optional historical
archive remain separate from the neutral examples. See
[LICENSE_STATUS.md](LICENSE_STATUS.md) before making a public release or assuming
that every local gallery asset belongs in a public download.
