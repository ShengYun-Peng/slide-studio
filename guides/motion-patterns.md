# Choosing a motion pattern

Choose the audience's reading task first. Motion is useful when it preserves
context, guides a comparison, shows a dependency, or gives a chapter transition
a clear rhythm. The gallery has 16 runnable patterns and a Tesla AI variant of
the cinematic title. This guide covers seven additions to the original nine.

The legacy examples are 1920 × 1080 at 60 fps; the interface tour is 3840 × 2160
at 60 fps with high-density source states. Their numerical examples are
illustrative unless replaced with properly sourced data. Use each pattern's
`USAGE.md` for the actual supported fields and renderer limits.

| Audience needs to… | Choose | Main effect |
|---|---|---|
| Understand what an interactive tool lets someone do | [Interface tour](../scenes/interface-tour/USAGE.md) | One visible action changes a real state; one camera focuses the result and holds for reading |
| Find a small piece of evidence inside a larger source | [Context → linked detail](../scenes/context-zoom/USAGE.md) | A marked region lifts into a linked enlargement while the source stays visible |
| Judge a change at the same viewpoint | [Before → after](../scenes/before-after/USAGE.md) | A controlled reveal exposes two registered layers |
| Read the important comparison in a dense table | [Metric focus](../scenes/metric-focus/USAGE.md) | Baseline and method remain prominent while unrelated rows recede |
| Understand how a research program developed | [Research timeline](../scenes/research-timeline/USAGE.md) | A path reaches milestones and their small visual artifacts in sequence |
| See the result before hearing its interpretation | [Evidence → insight](../scenes/evidence-to-insight/USAGE.md) | Curves trace first, then a focused region and delta support the conclusion |
| Recognize a new chapter or closing promise | [Cinematic title](../scenes/cinematic-title-reveal/USAGE.md) | Light catches glyph edges before a clean title and mark settle |

## Interface tour

Choose a representative question and carry it through the actual interface.
Establish the overview, show one action, reveal the changed result, then pause
on readable evidence. Use one camera and settled, lossless states with matching
source coordinates. A 4K output does not recover detail from a small screenshot.

The bundled original interface is a neutral adaptation example with illustrative
values. Replace its states with your tool's real outputs. See
[interactive talks](interactive-talks.md) for the story, and the scene's
[configuration contract](../scenes/interface-tour/README.md) for capture density,
detail crops, click timing, camera keys, and encoded-frame checks.

## Context → linked detail

Use this for a table image, attention map, failure screenshot, paper figure, map,
or interface where a small region matters. Show enough of the source to establish
what it is; mark the evidence; enlarge that exact region; then explain its meaning.
The connectors and crop are derived from one source rectangle, which keeps their
geometry consistent during the move.

The default is an original procedural report. Replace it with an exported image
and a meaningful `focus_rect` for real work. Preserve row/column labels, units,
or surrounding context in the crop. The enlargement should help the audience
verify a claim, not simply make the slide busier.

Suggested spoken opening: “Here is the full result. Look at this region—the
enlarged view shows where the output loses the structure.”

## Before → after

Use this for reconstruction, restoration, segmentation, visualization design,
or another result that can be compared in one coordinate system. Keep the camera,
crop, and scale fixed. The reveal boundary, handle, and labels share a common
state, so the comparison feels controlled instead of sliding two unrelated
images past each other.

Supply matched `before_image` and `after_image` assets. If they depict different
viewpoints or conditions, align or relabel them before using a wipe. The visual
effect otherwise suggests a fair direct comparison that the evidence may not
support. Leave a balanced final view long enough for the audience to inspect it.

## Metric focus

Use this when the complete table provides credibility but only two rows or a few
columns support the current point. Start with a stable table. Keep the relevant
baseline visible, emphasize the proposed method, and lower the contrast of
unrelated rows. Reveal a large result only after the comparison is readable.

The demo's result label is configurable; it is not an automatic statistical
calculation. Update the delta, units, and any qualifier when replacing the values.
If there is a tradeoff, retain the column needed to see it. Color should guide
attention, not conceal a weaker metric.

Suggested spoken opening: “Look at the two highlighted rows. This is the
comparison that matters for the result.” Then state the relevant difference.

## Research timeline

Use this for a project history, related contributions, or the progression from
an observation to a tool and an evaluation. The included layout has four stages;
each includes a compact artifact rather than another paragraph. A stage activates
when the advancing path reaches it, so timing communicates sequence.

Replace the milestones, dates, and short details. More stages need a different
layout or another slide; shrinking all the labels defeats the purpose. A timeline
can show chronology or a stated dependency, but chronology alone does not prove
that one publication caused a later discovery.

## Evidence → insight

Use this for a threshold, performance gap, learning regime, or trend. Introduce
the axes first, trace both curves from the same clock, and then highlight the
region that supports the interpretation. The delta bracket attaches to the
actual corresponding samples; a short takeaway gives the audience a conclusion
after they have had a chance to see the evidence.

Replace the arrays, tick labels, bounds, and highlighted sample together. The
current renderer joins supplied samples piecewise linearly; it does not invent
smooth values between sparse measurements. Its default x positions and focus
band are specific to the example and may need adaptation for another dataset.

## Cinematic title

Use this sparingly for a significant section break, a final promise, or a “what's
next” reveal. The title begins unseen; narrow light catches its vector contours;
the face gains exposure; a broad reflection passes; then the title holds cleanly.
The final state has no persistent fuzzy border.

The neutral **NEXT CHAPTER** example uses a procedural light field and an original
mark. The **TESLA AI** variant demonstrates the defense-style composition with
the red vector logo and Cybercab footage. That variant's media is for local review,
with separate provenance and unreviewed redistribution status. The generic effect
can use another title, your own mark, and your own stable background clip.

Let the title be legible before adding a subtitle. A reveal should give the
speaker a useful beat rather than force several seconds of unexplained waiting.

## Possible later additions — ideas, not implemented demos

- **Ablation by removing a module:** keep an architecture fixed, disable one
  component, then reveal the corresponding measured change. Useful for explaining
  what a component contributes; it needs actual ablation evidence.
- **Budget frontier:** move between configurations on a cost/performance plot,
  showing which constraint makes a choice attractive. Useful for compute and
  deployment tradeoffs; conditions and units must stay explicit.
- **Error → diagnosis → repair:** replay a compact failed sequence, identify the
  responsible step, and show the changed outcome. Useful for agent behavior or
  debugging, with an honest distinction between observed trace and illustration.
- **Coarse → fine architecture:** expand one block into its internal mechanism,
  then return to the larger system. Useful when two levels of detail are needed
  without losing the audience's place.
- **Uncertainty becoming a decision:** show a distribution or confidence band,
  then the decision rule it supports. Useful for calibration and reliability;
  the animation should preserve the underlying uncertainty instead of making it
  look more precise than the data.

These candidates should be implemented only when a real talk has a clear need.
The existing patterns can already be combined across manual slide boundaries;
there is no need to place every effect into one continuous video.
