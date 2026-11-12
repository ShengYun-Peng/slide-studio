# Visual review v2

Reviewed the two cinematic-title-reveal variants, device-story, and the five new presentation-pattern demos. Read `cinematic-quality.md`; inspected source contact sheets, full-size end frames, and 112 timestamped frames extracted directly from the eight encoded MP4s, plus three full-size decoded detail frames. This is a composition and sampled-motion review, not a real-time Keynote playback certification. No scene or renderer files were changed.

## Fix before calling the demos polished

1. **Device-story — overlapping labels during the merge (about 6.3 s).** The three app icons converge while “Write,” “Explore,” “Create,” and the new “AI assistant” caption are still visible. “Explore” and “AI assistant” occupy the same position. The translucent icons also stack into a muddy cluster. Fade the old captions before the contraction, then reveal the single new caption only once the merge has settled.
2. **Device-story — competing layers during app opening (about 7.0 s).** A large launcher icon and its caption remain over a translucent, growing application window, whose own icon and heading are already visible. The result resembles a double exposure. Give the launcher a clean exit or morph its shape into the window, and delay window text until there is enough space to read it.
3. **Evidence-to-insight — data precedes its coordinate system (0–1.5 s).** Two colored dots appear at time zero before the axes and legend. They read as unexplained stray marks. Start the curve and its moving endpoint together after the axes are established; `trace()` currently draws an endpoint even at zero progress.
4. **Before-after — untidy final split (6.5 s onward).** The divider settles at x=960, approximately 29 px before the Q2 column boundary. This leaves a narrow strip of green Q1 cell borders immediately beside the divider. For the default table, settle on the actual column boundary. The rest of the wipe remains accurately registered.

These findings refer to the reviewed MP4 snapshot. Recheck those timestamps after rerendering; fixes may be underway concurrently.

## Already strong

- **Cinematic default:** confident title scale, balanced margins, restrained platinum shading, and a clean final hold. No cropped glyphs, persistent bright outline, or black halo was visible. The eyebrow is small but appropriately secondary; the subtitle is legible at full resolution.
- **Tesla variant:** clear red-symbol/white-title hierarchy, footage with useful depth, and sufficient darkening to protect the title. The reveal transitions from contour to solid face without a lasting halo. No visual-quality reason to redo this variant.
- **Device hardware and UI:** opening and closing screen mapping is convincing in the sampled frames. The full-screen handoff, typography, spacing, cursor targeting, and app panel look substantially more finished than a schematic device mockup. The two transition collisions above are its main polish gap.
- **Context-zoom:** the source remains visible, the selected rows exactly match the enlarged detail, and connector endpoints follow the correct corners. The enlarged table is readable. Temporary overlap while the crop leaves its source is meaningful motion, not an accidental collision.
- **Metric-focus:** the comparison is easy to scan, +14.4 agrees with 94.6−80.2, capability remains visible, and dimming preserves the other rows as context. Good type scale and no crowding.
- **Research-timeline:** ordered node arrivals, consistent alignment, spacious type, and a restrained final hold. No cropped stage text or wrong association between labels and nodes was found.
- **Evidence-to-insight final hold:** legible axes and legend, uncluttered callout column, correct +15 difference at the selected sample, and a focus band that does not obscure the curves.

## Showcase limitations

The timeline is still the most schematic example: generic stage names and a line do not yet demonstrate how a real research contribution carries into the next. Before-after is visually clean, but the two procedural tables make the transformation look chiefly like added cell borders. A concrete source fragment and recognizable research artifacts would make those two demos stronger showcases. Context-zoom and metric-focus already demonstrate useful research-defense composition without extra decoration.

All five newly decoded presentation-pattern MP4s visibly label the example as illustrative. A few PNGs were being refreshed during review, so the encoded movie was treated as authoritative. Apple/Tesla local-reference rights flags remain as documented; no broader rights audit was performed.

## Follow-up disposition — 2026-11-12

**All four actionable findings above are resolved in the updated encoded movies.** The original findings remain as review history.

- Device-story, sampled densely from 6.1–7.8 s: old captions disappear before contraction; the assistant caption appears beneath one clean tile; the desktop heading/icon clear before the application window grows. Neither the label collision nor the double exposure remains.
- Evidence-to-insight, checked at 0, 0.7, 1.5, and 8 s: no premature dots; axes and legend establish the coordinate system before the curves.
- Before-after, checked during the wipe and at 6.5/8 s: the final divider lands on the column boundary, with no residual Q1 strip.
- Research-timeline, checked at four encoded stages: the new document, relationship, method, and result artifacts give the stages more specific visual roles. Node order remains clear, and the final frame has no overlap. This addresses the earlier schematic-showcase concern.

Also inspected fresh source contact sheets, full-resolution posters, and encoded contact sheets for framework-to-portfolio, branch-and-merge, learn-visual-vocabulary, masked-token-training, video-budget, and text-and-score. **No material overlap, clipped title, or unreadable primary label was found in those reviewed frames.** Their decoder reports all pass.

The portfolio columns remain aligned; the table branches preserve merged-cell structure; the reconstruction feedback arrows land on the intended modules; masked-token comparison highlights corresponding positions and returns only to the trainable encoder; the video-budget sequence keeps labels outside the token flow; and text-and-score preserves clear text, chart, and legend separation. The revised “Soft selection” label fits between its heading and codebook without touching either.

No additional visual blocker is open from this review. Before-after remains an illustrative procedural example, as labeled. The scope is sampled encoded-frame and presentation-scale inspection; native Keynote playback remains a separate rehearsal check.
