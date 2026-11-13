# Interface → interaction → readable detail

Use this scene to explain an interactive tool through one meaningful action. The bundled example is an original synthetic interface with illustrative values. Replace its PNG states, source coordinates, and narration beats with your tool; do not present its values as experimental evidence.

From the repository root:

```sh
python3 studio.py render --scene interface-tour --output my-project/build/interface-review --preview-only
python3 studio.py render --scene interface-tour --output my-project/build/interface-review
```

The default is **3840 × 2160, 60 fps, 12 seconds**. The camera stays still during the click/state change, moves for 3 seconds, then holds the enlarged result for 4 seconds. PNG states are composited at each output frame; this is not an uninterrupted screen recording.

To customize, copy this directory into your working project's sources, edit `scene.json`, then supply its path with `--config`. Relative image paths resolve beside that config. For a project scene binding, use `"template":"interface-tour"` with `"overrides"`; overridden files resolve inside the project while inherited bundled images keep their original source. Duration overrides retime camera keys, shot fades, cursor keys, captions and poster/review times together. A complete standalone config owns its explicit timing.

## Content contract

All interface geometry is in **CSS/source coordinates**. The surrounding slide is 1920 × 1080 logical units; output pixel resolution scales the whole composition. Other output sizes must remain 16:9 with even width/height.

- `content.viewport`: `[x,y,width,height]` on the logical slide. Defaults to `[96,238,1728,720]`.
- `content.assets`: named full states, each with `file` and `rect:[source_x,source_y,source_width,source_height]`.
- An asset's optional `layers` array uses the same format for sharper PNG crops from **that exact state**. `rect` records the crop's origin in the full source. A cropped image is not a new coordinate system.
- `content.shots`: `{time,asset,fade}` events; the first starts at 0. During a fade both states use the same camera. Change state on a fixed-camera hold unless the motion is intentionally choreographed.
- `content.camera`: `{time,x,y,w}` keys; height follows the viewport aspect ratio. Duplicate geometry at later times creates a hold. Center motion uses quintic easing; width interpolates in log space. There is one camera, not a native browser zoom underneath another compositor zoom.
- `content.pointer`: optional `{time,x,y,down,visible}` keys. Position moves between keys; `down` and `visible` belong to the interval starting at that key. Coordinate the press/release with the state-change event.
- `content.captions`: optional `{time,text,color,fade}` events. Main captions default to 56 logical units; the optional title defaults to 72.

Keep camera moves around 2–3 seconds and reading holds around 3–6 seconds as starting points. Tune them to the actual spoken explanation. These values are pacing choices, not universal rules.

## Capture and resolution

Capture settled, lossless PNG states at a fixed CSS viewport, with identical fonts, scroll positions and panel geometry where continuity is intended. Record what the interaction changed. If a native application relayout is part of the action, show that deliberately; do not hide it under a second pan/zoom.

Base states here are DPR 6. The final reading crop is DPR 12. Higher DPR is only useful when the resulting file really contains those pixels: check decoded image sizes, not the screenshot request. Browser screencasts can silently remain 1080p, and large browser captures may omit composited SVG layers. Inspect curves, connector endpoints and text after capture.

The renderer emits `source-density.json`. At each camera anchor it compares:

`required DPR = output viewport width / camera source width`

against the actual pixel density of the finest source that covers the **entire** camera view. `upsampling_ratio >1` means source pixels are enlarged. A 4K export of a small screenshot is still a small screenshot. Partial detail crops can improve one region but cannot establish full-frame coverage. Verify that crop edges remain out of view, or blend seamlessly into a matching state.

## Review and reproducibility

Inspect `contact-sheet.png`, `poster.png` and `end.png`, then the encoded movie. The renderer also accepts `--sample-times 7.967,7.983,8,8.017,8.033` when run directly from its compiled binary, for exact boundary inspection. Sampling is configurable rather than hardcoded to this demo's events. Adjacent frames around a camera arrival should settle without a one-frame jump; a static hold should keep geometry fixed.

Compile and run the existing frame decoder after encoding:

```sh
swiftc -O runtime/swift/verify.swift -o /tmp/slide-studio-verify
/tmp/slide-studio-verify my-project/build/interface-review
```

This checks every frame, duration, dimensions, fps and monotonic timestamps. It does not replace visual inspection or native Keynote playback. Verify movie autoplay separately from manual slide advance, and check the actual embedded movie hash after replacement.

`make-assets.swift` regenerates the original synthetic PNGs with no previous project, network source or private files:

```sh
swift scenes/interface-tour/make-assets.swift scenes/interface-tour
```

`provenance.json` records each PNG's CSS bounds and pixel density. Keep equivalent provenance when substituting real captures. The renderer and capture model are reusable; application-specific selectors, interactions and scientific claims remain the new project's responsibility.
