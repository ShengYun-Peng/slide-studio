# Device demo quality revision

## What was missing

The first reusable demo kept the opening/closing idea but replaced the original photographic hardware with simple flat polygons. That discarded the materials, thin rim, real keyboard, hinge geometry, and contact lighting that made the defense version convincing. Higher resolution alone could not restore those cues.

## What changed

- Restored the actual hardware plate and the carefully registered display/lid path from the defense method, packaged locally under `assets/device`.
- Preserved the physical front-rim correction at grazing angles. Neighboring source frames are registered to a common edge before blending, which avoids doubled outlines.
- Added a shared camera transform over the live registered device. The camera can start entering before the lid finishes opening, and the lid can start closing before the pullback finishes.
- Rebuilt the screen in source: restrained dark wallpaper, subtle light bands, accurate menu/battery spacing, dimensional app tiles, large centered labels, glass-like window panels, and crisp type.
- Tied magnification to cursor distance; added real down/up click compression, character-by-character typing, centered send arrow, and a pulsing thinking state.
- Rendered the demo at 1920×1080, 60fps. The original hardware clip remains 30fps; UI/camera motion is output-frame-rate, with registered interpolation for the hardware handoff.

## Reuse

`scenes/device-story/scene.json` controls screen text and the named timeline. `runtime/renderers/device-story.swift` is the self-contained render entry. The runtime has no defense-folder dependency. Replacing the physical source also requires replacing its registration; swapping an unrelated movie into the existing calibration is not supported.

The original Apple source URL and file hashes are in `assets/device/provenance.json`. The hardware and this derivative movie are local review assets, not cleared for public redistribution. The original configurable UI and rendering source are separate from that footage.

## Checks

Poster/contact-sheet layouts were inspected at full size. The actual encoded movie is decoded by `runtime/swift/verify.swift`; see `scenes/device-story/demo/verification.json` for dimensions, frame count, frame rate, duration and timestamp checks. Structural verification is supplemented by opening/closing handoff frame inspection.

## Follow-up handoff review

Independent encoded review found that the original app captions could overlap while their tiles converged, and the desktop heading could coexist with the expanding chat window. The updated timeline now clears old captions before contraction, reveals the assistant caption only after the icon settles, then clears the desktop heading/icon before the window begins. The same review also caught nested icon/cursor helpers resetting the outer CGContext alpha. Proper transparency groups now apply the handoff fade to every nested element. Old tiles fade before their geometry overlaps; the new assistant appears as a single clean tile. Dedicated encoded contact sheets inspect the dense 5.7–7.8-second interval, in addition to the physical hinge checks. The final movie again passed all 990-frame decoding checks.
