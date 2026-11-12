# Explanatory motion

Use motion to make a process, change, or dependency easier to understand. The reusable method is to define a timeline in code, evaluate the visual state at each frame, and encode the result as a movie for Keynote. It is not necessary to create one Keynote slide per frame.

## Pick the least complex useful representation

| Need | Useful representation |
|---|---|
| A few labels or bullets appear | Native Keynote builds |
| Editable modules and a simple data path | Native shapes and connectors |
| Continuous branching, masking, synchronized charts, cursor interaction | Code-rendered movie |
| A genuine surface growing or a trajectory in 3D | Mesh-based rendering with a fixed camera |
| Real footage under a designed reveal | Compositing with recorded source trim/crop and masks |

Use `python3 studio.py catalog` to inspect the available scene families. The demos are starting points: replace their labels, examples, timing, and geometry. Similar appearance does not make a demo scientifically suitable for the new work.

The current gallery has **15 patterns plus the Tesla AI title variant**, with
shipped configs at **1080p60**. See [the pattern guide](motion-patterns.md) for
the six newer options and when each earns its place in a talk. The CLI selects
the renderer recorded in the catalog; several richer scenes now have specialized
implementations rather than using the earlier simplified shared implementation.

Render a particular scene with:

```sh
python3 studio.py render --scene SCENE_ID --output my-project/build/scene-review --preview-only
python3 studio.py render --scene SCENE_ID --output my-project/build/scene-review --config /path/to/scene.json
```

Replace `SCENE_ID` with an actual catalog ID. Use a project scene binding when it belongs to a slide so rendering and assembly keep their association. Consult the CLI and scene configuration rather than assuming every renderer supports the same external tools.

## Preserve source fidelity when making a template

An abstraction can keep the timing logic and still lose the quality that made the
original convincing. Compare against the accepted source sequence before calling
an adaptation complete. Check the actual materials, image detail, relative scale,
light, curve geometry, timing, and causal steps—not only the number of frames.

In this library's second pass, the device returns to photographic hardware and
a registered screen plane. The modular table sequence retains location-driven
cropping before recognition. The two training steps keep their distinct learning
objectives and intermediate states. The title reveal uses high-resolution vector
edges with a temporary light pass. These are reusable production decisions, not
decorative detail to discard when replacing labels.

Keep the source-to-output record with the template. A real hardware plate has a
different provenance from procedural geometry; a synthetic teaching table is
different from a measured result. The Apple hardware footage and the Tesla
logo/Cybercab variant are local-review assets with unreviewed redistribution
status. Their presence in a polished gallery does not establish publication
rights. The independent project contains the needed local assets and provenance;
it must not silently reach back into the original defense's temporary folders.

## A scene is content, geometry, and time

Keep these concerns separate:

- **Content:** labels, paper names, examples, values, and source assets.
- **Theme:** fonts, semantic colors, background, line weights.
- **Geometry:** anchors, object bounds, camera, curve control points, crop regions.
- **Timeline:** named events, durations, easing, and holds.
- **Output:** canvas, frame rate, codec, poster/end frames, provenance.

Use semantic events such as `prompt_complete`, `cursor_arrives`, `permission_granted`, or `outputs_assembled`, rather than unrelated hardcoded timers scattered through drawing functions. Linked objects must read the same event progress. The curve and response text should advance together, not merely finish at similar times.

The renderer should determine the scene from time `t` and configuration. This allows arbitrary frame inspection, deterministic rebuilds, shorter previews, and precise changes without hand-editing hundreds of frames.

A project-level duration override retimes inherited event times, preview/poster
timestamps, and supported timeline anchors together. Explicit event overrides
then take precedence. A standalone full scene JSON owns its entire schedule:
changing its duration alone does not imply that its event timestamps changed.

## Narrative beats and slide boundaries

Write the spoken beats before setting final timing. A continuous opening may combine opening a laptop, entering the screen, and highlighting applications. Stop at a useful speaking beat when the presenter needs flexibility. A separate clip can open the assistant and begin the prompt without repeating the interface introduction.

Movie autoplay and slide advance are separate controls. The common default is: the movie starts when the slide appears, plays once, holds its end state, and the presenter advances the slide manually. Automatic object builds do not imply automatic slide advance. Avoid hidden builds that add an unexplained click.

For adjacent scenes, inspect the outgoing final frame and incoming first frame together. Match device pose, camera, object position, labels, color, background, and focus. A laptop cannot end half-open and restart fully closed unless the story explicitly shows that jump. A shutdown line must begin where the screen actually closes.

Native text laid over a movie is another layer that must match. Check the assembled slide, not only the movie file. Keep page numbers and essential labels visible, or intentionally place full-screen media above them where appropriate.

## Reusable scene patterns

- **Framework to portfolio:** start with a stable mission; reveal part words and connectors; bring the icons into the framework; rotate connected elements together; settle into the same icon-and-label positions used by the paper list. Labels should not disappear simply because the movie ends.
- **Branch and merge:** show the common input, branch into meaningful tasks, then assemble their outputs. Keep labels temporary when they describe a transient operation such as cropping. Emphasize dependencies, not just moving dots.
- **Two-step visual pretraining:** distinguish learning a visual vocabulary through reconstruction from predicting masked targets. Explain what is learned or kept fixed only as supported by the method. Do not invent shared weights or decoder connections to simplify the picture.
- **Text with score:** reveal the answer at a readable pace and update the score at the matching textual position. Introduce the score's meaning before its technical acronym.
- **Surface build and trajectories:** reveal a real geometric surface from its lower region upward. Keep coordinates and projected positions stable; place checkpoint annotations on the corresponding points. Approximate geometry is an illustration, not recovered experimental data.
- **Compute tradeoff:** vary the factors in a consistent order, show the budget and performance meaning explicitly, then reveal insights with their experimental conditions. Avoid overloading both point color and size without a clear purpose.
- **Device story:** registered screen content, smoothly timed cursor interactions, actual click state, clear permissions, and a continuous end pose. Presenter readability can justify centering the application icons rather than imitating a desktop literally.

## Motion quality checks

Frame rate alone does not make a clip smooth. Check acceleration, deceleration, registration, and the order of events. A cursor should arrive before the icon responds to its hover; a click should have a visible down/up response. Avoid accidental bouncing or a simultaneous scale jump across all icons.

Use thick, connected arrowheads and line geometry. A moving dot should support the dataflow, not become the brightest object on the slide. Remove a trailing label once the operation is complete. Keep masked patches and borders clean at intermediate frames, not only at the start and end.

For scientific surfaces, preserve the source phenomenon's proportions. Do not stretch a 2D image upward to imitate a 3D build. Use a mesh, a fixed camera, and a meaningful reveal plane; retain enough variation to avoid an unrealistically flat basin or rim. Coordinate arrows should remain interpretable through appropriate placement or opacity.

For cinematic text, use restrained edge illumination and a clean final mark. Low-resolution glow around an otherwise sharp logo looks worse than no glow. Stable source footage and good composition matter more than extra effects.

Higher output fps does not create new source evidence. The photographic device
uses a lower-rate source plate with registered interpolation between neighboring
lid poses, while its drawn interface runs at output fps. Record this distinction
instead of describing the entire composition as natively captured at 60 fps.

## Render and review economically

First inspect a poster and selected timestamps at a small output size. Check one frame before and after every important event. Then render the final resolution and inspect actual encoded playback. A source preview does not prove the encoded video has the right frame timing or colors.

Keep the exact scene configuration, source assets, font choices, source footage trim, transformations, output settings, and generated end frame. Record whether a scene is empirical, illustrative, or a composite. Do not locate source by “highest version number”; compare the current deck's embedded media to the actual rendered output when provenance is uncertain.

Motion can clarify a talk, but it also constrains timing. Make long explanatory scenes easy to retime through holds and event durations. Rehearsal should set those values; a one-time estimate of speaking speed is not a permanent timing contract.
