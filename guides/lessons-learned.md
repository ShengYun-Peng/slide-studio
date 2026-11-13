# Lessons from defense and conference-talk revisions

This is the detailed decision reference. Search by symptom; do not impose every historical preference on every new talk. **Invariant** means accuracy or operational correctness. **Profile** means a default for this research-talk style. **Context** means use the pattern when it supports the current story.

The numerical examples and method names below illustrate editing decisions. They are not reusable claims for a different research project.

## Story and contribution

### 01 — Start with shared context, then stakes · Context

**Before:** a slide says “Real-world consequences” before the audience knows what system is being discussed. **After:** begin with opening a familiar AI assistant, then show the risks of delegating actions. Evidence and stakes now have an object. **Check:** a listener who missed the title still knows who is doing what and why the problem matters.

### 02 — Give the intro visual evidence · Invariant + profile

**Before:** several introductory text slides, then an unrelated equation or table. **After:** a concrete image, interaction, or report supports each step of the argument. Real incident slides include enough headline and visual context to recognize what happened. **Check:** the image supports the spoken claim; it is not merely decorative, and the claim has a source.

### 03 — Make a promise and a distinct research question · Context

**Before:** read the thesis title, then ask the same sentence with a question mark. **After:** promise what the audience will understand and ask the gap that the mission answers. For example, a question about relying on a model in practice can lead to a mission about safe adaptation, reliable design, and scaling. **Check:** question and answer advance the story rather than repeat each other.

### 04 — Keep the mission stable while parts emerge · Profile

**Before:** each reveal moves the mission or colors all words immediately. **After:** keep a large two-line statement fixed, start neutral, then reveal a connector and color the matching concept as each part appears. **Check:** the audience can track the word-to-part mapping without rereading a shifted sentence.

### 05 — Roadmaps should show hierarchy, not compress everything · Profile

**Before:** part titles and paper names compete horizontally. **After:** stack parts, put a smaller part label near the icon, indent paper shorthands, and align larger descriptions in a second column. Use short parallel verbs such as “Align,” “Design,” and “Scale” where suitable. **Check:** the three levels—part, paper, explanation—are visible at thumbnail scale.

### 06 — Portfolio layers need a deliberate order · Context

**Before:** awards, GitHub counts, venues, and company logos fight for the same space. **After:** anchor badges at the end of each shorthand; use distinct venue styling; reveal recognition, collaboration, and practical impact in separate layers or clearly organized areas. **Check:** each layer adds meaning, and unchanged icons do not wander during the transition.

### 07 — A paper cover introduces people and identity · Profile

**Before:** a full method figure, question, title, and tiny author row compete. **After:** shorthand, full title, large face-centered headshots, author names, venue, and restrained recognition. Put the method question on the next slide. **Check:** names align with faces and the presenter can introduce the work without reading a miniature poster.

### 08 — Bridge with the unresolved question · Invariant + context

**Before:** “Early convolutions are useful for the next question…” invents a weak relationship to a new topic. **After:** explain the shared real-world reliability goal, distinguish adversarial input from table-image structure, and state why architecture or data is the next lever. **Check:** the bridge remains true even without the next paper's acronym.

### 09 — Claim titles and takeaways should carry the contribution · Profile

**Before:** “Choice 2,” “Method,” or “Explain abrupt failures.” **After:** a precise supported principle, mechanism, or discovery, such as “Discover a universal safety basin phenomenon.” Convert contribution bullets into brief complete takeaways; avoid a second tiny explanatory line beneath each bullet. **Check:** strong wording identifies what is new without expanding the evidence's scope.

### 10 — Close with grounded future directions and verified impact · Invariant + context

**Before:** future work sounds like unfinished thesis work, and an impact slide is a wall of mixed counts. **After:** derive a small number of future directions from completed foundations; then group verified adoption, recognition, open-source use, and other effects. **Check:** “cited by,” “featured in,” “adopted by,” and “deployed” mean different things and have matching evidence.

## Layout and typography

### 11 — Large type is a compositional decision · Profile

**Before:** every requested detail is squeezed in by reducing the font. **After:** shorten, group, sequence, or split the content, then use the available space for larger text. **Check:** title, diagram labels, table highlights, and video text remain readable from the back; “inside a video” is not an exemption.

### 12 — Prefer one-line titles, not one-word line stacks · Profile

**Before:** a narrow right-hand tagline wraps into five isolated words. **After:** widen the text region or shorten the phrase to one or two meaningful lines. Use `&` when it improves the layout without changing the meaning. **Check:** line breaks follow phrases, not arbitrary box widths; size remains consistent with neighboring slides.

### 13 — Anchor recurring elements consistently · Profile

**Before:** an imported section places titles lower, and the next page suddenly lifts the whole composition. **After:** set a shared title anchor and body region, then shift the group together. **Check:** compare adjacent frames, not just the slides separately; the title, table, and image should not appear to jump unintentionally.

### 14 — Color encodes a role · Invariant + profile

**Before:** yellow means a task, pretraining, an award, and a result on the same sequence. **After:** maintain a compact semantic map and use a separate pretraining color. **Check:** the same concept keeps its color through diagrams, notes references, and video. A reader should not need to reinterpret a color on each slide.

### 15 — Graphite and off-white need actual contrast checks · Profile

**Before:** black-on-black axes or muted text that disappears during projection. **After:** use the profile's readable foregrounds, brighten important panels or use a light inset. **Check:** contrast in the rendered slide, including gray secondary text and gradient edges; a plausible hex value is not enough.

### 16 — Make bold purposeful and consistent · Profile

**Before:** prompt and response labels change weight between adjacent examples, or every sentence is bold. **After:** define weight by role: claim, label, ordinary explanation, emphasis. **Check:** visually equivalent text uses equivalent weight; mathematical symbols retain correct notation rather than accidental bold/plain substitutions.

### 17 — Center images by content and captions by their image · Profile

**Before:** a circular crop centers the original photograph but leaves the person's head on the left. **After:** crop around the head and eyes, fill the circle, then center the name below. **Check:** all faces and names form a coherent row; related pictures have comparable visual scale and captions align to their actual bounds.

### 18 — Separate badges from company identity · Context

**Before:** a microphone, star count, and company logo overlap. **After:** use stable end-of-title recognition anchors and a dedicated collaboration layer or region. Prefer simple recognizable solid icons; use accurate colored company marks where appropriate. **Check:** badges remain close to the correct paper and do not require a legend to decode basic meaning.

### 19 — Space is functional, not empty by default · Profile

**Before:** a one-sentence chat bubble is huge while a two-sentence response is cramped; captions have giant padding. **After:** size containers to content with consistent insets and align the composition as a whole. **Check:** important objects have enough breathing room, without spending half a slide on padding that could make text larger.

### 20 — Preserve a clean visual grammar through the ending · Context

**Before:** takeaways switch abruptly to unrelated image collages, then tiny acknowledgements. **After:** keep takeaway bullets consistent; use a deliberate transition into a warmer photo collage or company grid. **Check:** priority photos fit without losing faces; names remain centered, spacing is even, and a humorous separator does not overpower the people being thanked.

## Scientific figures, tables, and diagrams

### 21 — Preserve the original visual evidence · Invariant

**Before:** attention maps are redrawn or cropped so their actual patterns are lost. **After:** retain the original scientific image, improve surrounding labels, and use a light panel when helpful. **Check:** the audience still sees the same measured attention, table cells, or failure as in the source. Styling must not change the evidence.

### 22 — Dark adaptation is more than transparency · Invariant + profile

**Before:** removing a white background leaves white speckles, invisible axes, or bright halos. **After:** inspect and adapt each foreground role, or retain a coherent light inset. **Check:** all edges, labels, ticks, and transparent regions are clean at full resolution; never recolor a heatmap without preserving its meaning and legend.

### 23 — Show where a table error happens · Invariant

**Before:** a cropped output is labeled “wrong,” but the reference cells are missing. **After:** show enough of the full table, then annotate the incorrect merged cell or row/column relationship. **Check:** the audience can identify the error without knowing the dataset. For image extraction, say and show that the source is a table image, not an existing spreadsheet.

### 24 — A crop needs a location · Profile

**Before:** a small decoded region appears without its original context. **After:** show an overview, a selection region, and corner connectors or a magnifier to the enlarged crop. **Check:** the crop's location and claimed result are unambiguous; its label does not imply a whole-table result when only a region is displayed.

### 25 — Highlight the comparison the audience should read · Profile

**Before:** every result number has equal emphasis. **After:** mute secondary rows, bold the relevant baseline, and color the key method or difference. **Check:** notes briefly tell the audience which highlighted rows or columns matter, then state the conclusion. Keep necessary baseline context rather than deleting all inconvenient values.

### 26 — Build methods in a clear reading order · Context

**Before:** a redesigned architecture has scattered small labels and unexplained tokens. **After:** reuse an effective source sequence: existing encoder/decoder, expensive backbone, lightweight alternative, the proposed stem, then results. **Check:** each added element answers the current question, and technical metrics do not replace the idea being explained.

### 27 — Arrows are geometry, not decoration · Invariant

**Before:** arrowheads float above lines, colored segments meet with a bump, or endpoints intrude into dashed boxes. **After:** define object anchors, use consistent clearances, and derive arrowhead direction from the curve tangent. **Check:** inspect start, middle, and end states; branch curves are symmetric when intended and the middle line reaches the box center.

### 28 — Masks must cover cleanly · Invariant

**Before:** colored patches leave remnants of the original cell border or fight over shared green/purple edges. **After:** use inner borders or gutters; make each patch a coherent fill with a contrasting glyph; cover the entire intended region. **Check:** intermediate animation frames have no accidental border slivers or ambiguous “mask versus content” colors.

### 29 — Simplify equations without changing what they mean · Invariant + profile

**Before:** a dense definition includes coefficient ranges and elaborate notation the talk never uses. **After:** show the essential relationship, correct Greek/italic symbols, and one plain-language interpretation. **Check:** a bound states what is bounded and under what relevant scope; “higher score” names the model state or outcome it refers to.

### 30 — Strong claims need the comparison setting · Invariant

**Before:** “larger language models are better” contradicts “smaller models are optimal.” **After:** distinguish the fixed-data comparison from allocation under increasing data or a fixed inference budget. **Check:** axes, bubble encodings, budget conditions, and metric names are explicit; an insight includes the condition that makes it true.

## Motion and timing

### 31 — Animate an explanation, not every object · Context

**Before:** every item flies in, delaying the talk. **After:** animate the relation that is hard to understand statically: branch, mask, measure, move, or assemble. **Check:** removing the animation would make some important mechanism less clear; ordinary text can remain static or use a simple build.

### 32 — One clock for events that belong together · Invariant

**Before:** a line chart lags behind the response text it scores. **After:** both reveal from the same response-progress event. **Check:** at any sampled timestamp, the plotted position corresponds to the visible text, not merely the same approximate total duration.

### 33 — Autoplay is not auto-advance · Invariant

**Before:** a slide's movie ends and unexpectedly jumps to the next slide, or a hidden build needs a second click. **After:** autoplay the movie on entry and preserve manual slide advance unless the sequence explicitly requires otherwise. **Check:** test the native slideshow through the exact boundary; object-build settings alone do not establish slide navigation.

### 34 — Match the outgoing and incoming state · Invariant

**Before:** a half-closed laptop restarts fully closed, or a video returns to a different dashed-arrow graphic. **After:** use consistent first/end frames and shared geometry. **Check:** device pose, coordinate origin, text position, color, camera, and labels agree across the boundary. Hold the final state rather than snapping to an older design.

### 35 — Cursor and interface responses need cause and effect · Profile

**Before:** icons enlarge before the cursor arrives, all icons jump together, or a click is only a “Return” caption. **After:** tie hover to cursor position, use smooth monotonic scale, and show a brief pressed state. **Check:** no unwanted bouncing, stalls, or discontinuous velocity; important icons are high enough for the audience to see.

### 36 — Connected structures should move together · Invariant

**Before:** three circles spin but their connecting center stays still, breaking the structure. **After:** transform the connected group, then settle icons and labels into their next layout. **Check:** a converging framework first moves the parts, then introduces the center and grows connectors in the intended order; nothing detaches by accident.

### 37 — A three-dimensional build needs geometry · Invariant

**Before:** a 2D basin image stretches upward to imitate depth. **After:** use a surface mesh and a height-based reveal plane with a fixed camera. **Check:** proportions resemble the source phenomenon, floor/rim variation is plausible, axes remain interpretable, and the scene is marked illustrative if the values are reconstructed.

### 38 — Trajectory labels should explain progression · Profile

**Before:** only e1/e5 appear, an arrow points to the wrong point, or e5/e10 overlap. **After:** reveal a few intermediate checkpoints and an end label with clear anchoring. **Check:** labels refer to actual trajectory positions, left/right comparisons share their color meaning, and annotations do not hide the change being shown.

### 39 — Temporary operations should have temporary labels · Profile

**Before:** “Crop” remains long after cropping ends; a final OCR box still shows an already-consumed cell. **After:** show the label while the action occurs, then remove or update it as the result completes. **Check:** the final frame communicates the finished state of all branches, not a mixture of intermediate and final states.

### 40 — Smoothness includes pacing and real playback · Invariant + profile

**Before:** a nominal 60 fps movie still jerks, waits halfway open, or uses low-resolution glow. **After:** inspect interpolation, screen registration, stable source footage, and edge quality; retime holds against narration. **Check:** play the encoded file and native slide, including first and last frames. High frame rate metadata is not proof of quality.

## Spoken script

### 41 — Notes contain speech, not production instructions · Profile

**Before:** notes say “animation starts here, approximately 15 seconds” alongside the script. **After:** move production instructions, sources, and review comments to project records; leave the words to say. **Check:** the presenter can read the notes directly without deciding which paragraphs are stage directions.

### 42 — Introduce the visual before the conclusion · Profile

**Before:** “Across these curves…” begins before the curves appear. **After:** “Here we plot the score as the answer unfolds. Higher means safer. Notice the drop…” **Check:** the audience has time to locate the evidence and knows what an axis or highlight represents before hearing the inference.

### 43 — Replace formal clauses with speakable sentences · Profile

**Before:** “Repeating this as the response grows tells us where safety changes.” **After:** “We check again as the answer gets longer.” **Check:** read it aloud; remove nested clauses and awkward sound sequences while preserving the necessary technical term.

### 44 — Transition through the previous result · Context

**Before:** a slide starts with a detached question after a different subject. **After:** “The basins have different sizes. So we need a way to compare the risk after finetuning.” **Check:** the first sentence tells the listener why the new slide follows the previous one; use adjacent notes, not isolated editing.

### 45 — Use questions and humor selectively · Profile

**Before:** repetitive “Are we teaching mistakes? No.” exchanges or a joke that obscures the result. **After:** a natural direct statement, with an occasional real question such as “Does that just mean saying no more often?” **Check:** the device helps attention or understanding and does not add verbal filler.

### 46 — Vary takeaway openings and preserve novelty · Profile

**Before:** every takeaway begins “We show…” and paraphrases strong contributions weakly. **After:** “To wrap up this work…” followed by a supported discovery, method, and result. **Check:** statements are concise but specific; brevity does not remove what the method actually contributes.

### 47 — Calibrate script length to the visual work · Context

**Before:** a static claim has a long paragraph, while a complex animation has no guidance. **After:** use short notes for simple slides and enough narration for staged visuals. **Check:** rehearse with the actual movies; do not add total video time on top of words that are spoken during those movies.

### 48 — Notes appearance must be checked in the notes pane · Invariant

**Before:** notes are set to an explicit light color but render black in Keynote's dark editing pane. **After:** test the native black notes style that Keynote adapts to dark mode, then propagate only after confirmation. **Check:** 25 pt text is visible in the actual pane, including emphasized runs; stored RGB values are not the acceptance test.

### 49 — Short answers can be confident and bounded · Invariant + context

**Before:** a long evasive Q&A answer or an unqualified “No” to whether the thesis solves agent safety. **After:** state the concrete foundation provided, then the remaining agent-level challenges. **Check:** the first sentence answers the question; the rest adds evidence and scope without falsely claiming a complete solution.

### 50 — Q&A is a navigation and evidence system · Profile

**Before:** full multi-line questions in small text and dense answer pages. **After:** a huge topic cue readable in thumbnails, then a visual answer with one short claim. Add possible question associations in the requested secondary area. **Check:** backup figures are relevant, sources are recoverable, and the presenter can find the answer quickly.

## Reproducible production and adaptation

### 51 — Separate reusable patterns from personal content · Invariant

**Before:** a “template” depends on the entire defense folder, personal photos, and absolute paths. **After:** a standalone library plus `my-project` for the current talk; demos use intentional reusable content. **Check:** a different topic can build from a relocated copy without the original defense or its `_tmp` directory.

### 52 — Use semantic IDs, not slide numbers as identity · Invariant

**Before:** a script edits “slide 115” after earlier slides were merged. **After:** resolve the current slide number to a stable content ID and inspect its neighbors. **Check:** scene bindings, note files, and native objects still refer to the intended content after reordering.

### 53 — Preserve human edits before regenerating · Invariant

**Before:** a newly generated deck overwrites the speaker's adjusted spacing or moved notes. **After:** compare the baseline, current saved deck, and proposed change; update only intended content. **Check:** the working copy reflects the latest saved state, and an older open window cannot overwrite the result later.

### 54 — Retain inputs and transforms, not only the movie · Invariant

**Before:** only a final MP4 remains. **After:** keep source footage or vectors, crop/trim, masks, fonts, camera settings, scene JSON, and output settings. **Check:** a new agent can change timing or a label and rerender without reverse-engineering frames.

### 55 — Prove what the embedded media actually is · Invariant

**Before:** the highest version filename is assumed to be the clip in the deck. **After:** inspect the current binding and compare hashes or extracted media. **Check:** source records correspond to the delivered movie, even if its filename contains an obsolete slide number.

### 56 — Separate evidence from illustration · Invariant

**Before:** inferred basin values or a synthetic example appear to be measured results. **After:** record empirical, reconstructed, illustrative, or future-proposal status alongside source provenance. **Check:** wording and presentation do not imply a guarantee or experiment that was never performed.

### 57 — Input format does not promise editability · Invariant

**Before:** a PDF screenshot is described as a fully editable diagram. **After:** state whether it is native text/shapes, editable vector source, renderable scene code, or a fixed raster. **Check:** expected future changes have an actual source path; Figma access is supplemented with local exports rather than treated as permanent.

### 58 — Generalize a demonstrated defect, not a whole redesign · Context

**Before:** only the reported arrow is fixed, leaving the same defect throughout a sequence; or a narrow request triggers a full restyle. **After:** inspect related instances that share the failing recipe while preserving unrelated manual choices. **Check:** the broader change is justified by the actual defect and stays within the user's scope.

### 59 — Validate at the level you claim · Invariant

**Before:** successful rendering is reported as proof of native playback and notes readability. **After:** distinguish source validation, preview, encoded movie, native deck, and rehearsal checks. **Check:** the review record says which levels passed and which require app access or speaker confirmation.

### 60 — Keep final output clean and public release intentional · Invariant + profile

**Before:** every iteration adds another PDF/PPTX and third-party assets enter a public repo without review. **After:** keep the final Keynote prominent, intermediates in build/review locations, and asset provenance separate from software licensing. **Check:** no accidental private material, unsupported license assumption, or publishing step is implied by local organization; the user reviews before any requested release.


## Interactive talks and media quality

### 61 — Demonstrate a tool through a real investigation · Context

**Before:** mostly static paper figures describe an interactive system. **After:** one real example moves through overview, selection, focused computation, and interpretation. **Check:** the audience sees what changed and why that interaction is useful. See [interactive talks](interactive-talks.md).

### 62 — Readability requires editing, not tiny text patches · Profile

**Before:** small muted short phrases and unreadable screenshot labels accumulate around the main figure. **After:** retain one clear reading order; the Anthony profile uses 72/56/50/50 type and a 50-unit floor for main reading content. Retype or redraw the needed screenshot terms. **Check:** context-only UI can be small during orientation, but the audience-read result is enlarged before it is discussed.

### 63 — Output resolution is not source resolution · Invariant

**Before:** a 4K container holds an enlarged 1080p capture or a Figma export backed by a small raster. **After:** inspect native pixels and calculate density at the closest zoom; use lossless or higher-density source regions. **Check:** the focused region has enough actual detail, and overlays match the same UI state and CSS bounds.

### 64 — Give one camera control of the zoom · Context

**Before:** browser wheel zoom or panel resize fights an external camera, creating jitter and reversals. **After:** keep one transform system in control, move smoothly, then hold. **Check:** inspect encoded frames around arrivals, not only the final screenshot. See [motion](motion.md).

### 65 — A clean layer must remain clean in motion · Invariant

**Before:** a card carries background dots, covers its own connectors, or loses links at the return to the captured frame. **After:** use an alpha card, actual path geometry, correct layer order, and a checked handoff. **Check:** crops and detail overlays do not expose rectangular seams, including after the camera moves.

### 66 — Native replacement has its own state · Context

**Before:** a movie is imported but saved behind a compatibility dialog; a poster-time edit appears changed without persisting. **After:** complete the known modal workflow before synchronous app calls, save through the tested native path, and verify after reselection. **Check:** source-byte match, full trim, persistent poster, autoplay, manual advance, and unchanged native content. This is version-dependent app behavior, not permission to kill Keynote or dismiss arbitrary dialogs. See [Keynote media](keynote-media.md).
