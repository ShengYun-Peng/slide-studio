"""Portable, file://-friendly demo browser. No server or JS dependencies."""
from __future__ import annotations
import html
import json
import os
import platform
import shutil
import subprocess
from pathlib import Path
from string import Template
from .common import ROOT, compile_swift, read_json, write_json
from .layout import make_manifest, svg


def build_gallery(output):
    output = Path(output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    def link(path):
        return html.escape(Path(os.path.relpath(path, output.parent)).as_posix(), quote=True)
    def escape(value):
        return html.escape(str(value), quote=True)
    catalog = read_json(ROOT / "scenes/catalog.json")
    if isinstance(catalog, dict):
        catalog = catalog["scenes"]
    entries = []
    for entry in catalog:
        entries.append(dict(entry, variant=False))
        variants = ROOT / "scenes" / entry["id"] / "variants.json"
        if variants.exists():
            for variant in read_json(variants)["variants"]:
                if variant["id"] == "neutral":
                    continue
                entries.append(dict(entry, **{
                    "id": entry["id"] + "--" + variant["id"],
                    "parent": entry["id"], "title": variant["title"],
                    "demo": variant["demo"], "poster": variant["poster"],
                    "config": variant["config"], "variant": True,
                    "description": "Red Tesla emblem, a moving edge light, platinum lettering, and the Cybercab background. A local reference variant of the reusable title scene.",
                }))
    order = ["device-story", "cinematic-title-reveal--tesla-ai", "framework-to-portfolio",
             "branch-and-merge", "learn-visual-vocabulary", "masked-token-training",
             "surface-build", "surface-trajectories", "video-budget", "text-and-score",
             "interface-tour", "cinematic-title-reveal", "context-zoom", "before-after", "metric-focus",
             "research-timeline", "evidence-to-insight"]
    entries.sort(key=lambda e: order.index(e["id"]) if e["id"] in order else len(order))
    cards = []
    for i, entry in enumerate(entries):
        sid = entry["id"]
        parent = entry.get("parent", sid)
        folder = ROOT / "scenes" / parent
        movie, poster = ROOT / entry["demo"], ROOT / entry["poster"]
        manifest = movie.parent / "render-manifest.json"
        config = read_json(ROOT / entry["config"])
        metadata = read_json(manifest) if manifest.exists() else config
        spec = f'{metadata.get("duration", "—"):g}s · {metadata.get("height", 1080)}p · {metadata.get("fps", 60)} fps'
        media = (f'<video controls playsinline preload="none" poster="{link(poster)}" aria-label="{escape(entry["title"])}"><source src="{link(movie)}" type="video/mp4"></video>'
                 if movie.exists() else f'<img src="{link(poster)}" alt="{escape(entry["title"])}">' if poster.exists() else '<div class="missing">Render this scene to see the preview.</div>')
        label = "Reference footage" if sid in ("device-story", "cinematic-title-reveal--tesla-ai") else "Original demo"
        open_button = (f'<button class="expand" data-movie="{link(movie)}" data-title="{escape(entry["title"])}">View large ↗</button>' if movie.exists() else '')
        cards.append(f'''<article class="motion-card {"featured" if i < 2 else ""}" id="{sid}" data-category="{escape(entry.get("category", "Narrative"))}" data-search="{escape(entry["title"] + " " + entry["description"] + " " + sid).lower()}">
          <div class="card-top"><span>{escape(entry.get("category", "Narrative"))}</span><span>{spec}</span></div>
          <div class="media">{media}</div><div class="card-body"><div class="title-row"><h2>{escape(entry["title"])}</h2>{open_button}</div>
          <p>{escape(entry["description"])}</p><div class="card-links"><a href="{link(folder / "USAGE.md")}">Adapt this pattern</a><a href="{link(ROOT / entry["config"])}">Config</a><a href="{link(ROOT / entry["renderer"])}">Source</a><span>{label}</span></div></div></article>''')
    # Profile previews stay below the videos: first choose the visual explanation,
    # then its palette. These use the same layout, content and scale.
    style_cards = []
    example = ROOT / "examples/urban-gardens"
    roadmap = next(s for s in read_json(example / "storyboard.json")["slides"] if s["layout"] == "roadmap")
    binary = compile_swift(ROOT / "runtime/static_render.swift") if platform.system() == "Darwin" and shutil.which("swiftc") else None
    styles = output.parent / "styles"
    styles.mkdir(parents=True, exist_ok=True)
    for theme_path in sorted((ROOT / "templates/themes").glob("*.json")):
        theme = read_json(theme_path)
        manifest = make_manifest(roadmap, theme, example, 4, 9)
        source = styles / f"{theme_path.stem}.json"
        write_json(source, manifest)
        (styles / f"{theme_path.stem}.svg").write_text(svg(manifest), encoding="utf-8")
        ext = "svg"
        if binary:
            subprocess.run([str(binary), str(source), str(styles / f"{theme_path.stem}.png"), "1280"], check=True)
            ext = "png"
        style_cards.append(f'<article class="profile"><img src="{link(styles / f"{theme_path.stem}.{ext}")}" alt="{escape(theme["name"])}"><h3>{escape(theme["name"])}</h3><a href="{link(theme_path)}">Edit theme tokens ↗</a></article>')
    page = Template((ROOT / "templates/gallery/index.html").read_text()).substitute(
        count=len(catalog), cards="\n".join(cards), profiles="\n".join(style_cards),
        start=link(ROOT / "START_HERE.md"), brief=link(ROOT / "my-project/brief.md"),
        pattern_guide=link(ROOT / "guides/motion-patterns.md"),
        sample=link(ROOT / "examples/urban-gardens/demo/index.html"),
        keynote=link(ROOT / "templates/keynote/anthony-dark-template.key"),
        quality=link(ROOT / "review/quality-v2.md"),
    )
    output.write_text(page, encoding="utf-8")
    return output
