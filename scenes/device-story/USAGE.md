# Photographic device story

This is the high-fidelity device composition used by the local gallery: real hardware footage, a registered screen plane, and an original configurable desktop/chat interface. It replaces the earlier generic polygon laptop.

The difference in quality comes primarily from **the hardware asset and screen registration**, not just increasing frame rate. The physical rim, keyboard, material reflections, and contact shadow come from the source plate. The screen, app tiles, cursor, window, typing, and button interaction are rendered from source at every output frame.

## Run

From the repository root:

```sh
python3 studio.py render --scene device-story --output my-project/build/device-preview --preview-only
python3 studio.py render --scene device-story --output my-project/build/device-video
```

The standalone renderer uses the same contract:

```sh
swiftc -O runtime/renderers/device-story.swift -o /tmp/device-story
/tmp/device-story --config scenes/device-story/scene.json --output /tmp/device-demo --video
```

Outputs are `movie.mp4`, `poster.png`, `end.png`, `contact-sheet.png`, and `render-manifest.json`. The gallery delivery is **1920×1080, 60 fps, 16.5 seconds**. The hardware source is 30 fps; registered neighboring lid poses are blended at a common geometry rather than simply repeating the source frames. The screen and interaction graphics are rendered natively at output frame rate.

## Story beats

1. The physical laptop opens; its display lights while the lid is still moving.
2. The camera moves continuously into the registered display plane.
3. The cursor passes over three central app tiles. Distance from the cursor drives their enlargement, so they do not animate ahead of it.
4. The old captions clear before the tiles converge. One assistant icon/label settles, receives a visible click, then clears with the desktop heading before the window opens.
5. The prompt types character by character. The cursor moves onto the centered send button and visibly presses it.
6. The assistant starts working, then the camera pulls back and the same physical lid closes.

The output is intended as a continuous demonstration. In a spoken talk, split at the end of a useful beat, or extend the explicit hold before sending/closing. Movie autoplay and slide advance remain separate controls.

## Configurable content

`content.screen_heading`, `screen_subtitle`, `apps` (three labels), `app_title`, `chat_heading`, `chat_subtitle`, `prompt`, `status`, and `status_detail` are consumed directly. Keep the prompt to roughly one short sentence. The UI uses native SF Pro when available, with system-font fallback, so no font files are distributed.

`content.hardware_video` and `content.screen_tracking` can be absolute resolved paths or paths relative to the supplied scene JSON. The bundled defaults point to `../../assets/device/`. `content.screen_image` optionally replaces the entire live interface with an image while retaining camera and hardware motion. For a different laptop, replace the hardware footage **and** its geometric registration; changing only the source video is not sufficient.

The registration is specifically calibrated for the included source, with a fixed hinge and photographic rim correction. `screen_tracking` preserves measured source-frame quads; the smooth front-lid path uses fitted coordinates in the renderer to avoid the jitter of nearest-frame tracking.

## Timing

All named events in `timing` are seconds. A standalone configuration must keep them inside `duration`. The project CLI can proportionally retime inherited events when using a project-level duration override.

- `open_start`, `open_end`
- `zoom_start`, `zoom_end`
- `cursor_start`, `cursor_visible`, `cursor_end`
- `app_labels_out_start`, `app_labels_out_end` (clear old captions before contraction)
- `collapse_start`, `collapse_end`
- `assistant_label_start`, `assistant_label_end`, `app_click_start`
- `desktop_out_start`, `desktop_out_end` (clear heading/icon before the window enters)
- `app_start`, `app_end`
- `typing_start`, `typing_end`
- `send_cursor_start`, `send_start`, `send_end`, `cursor_hide`
- `zoom_out_start`, `zoom_out_end`
- `close_start`, `close_end`

For an uninterrupted handoff, let `zoom_start` overlap the final part of opening and let `close_start` occur shortly before `zoom_out_end`. The renderer transforms the entire registered live hardware frame, so the lid and screen stay connected while both motions overlap. Avoid adding independent animation clocks to connected geometry.

## Asset provenance and release

The original Apple hardware movie is copied into this independent project, with its source URL and SHA-256 recorded in `assets/device/provenance.json`. The hardware footage and this derivative gallery movie are **not claimed to be original procedural assets and have not been cleared for public redistribution**. The UI drawing and composition code are reusable; review or replace the footage before a public release. Do not mistake the ability to render an asset for permission to redistribute it.

The earlier lightweight procedural device remains in `runtime/swift/main.swift` as a fallback/example, but is no longer the gallery's quality reference.
