from __future__ import annotations

import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def digest(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def slug(value):
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-") or "untitled"


def local_path(base, reference):
    """Project-relative references cannot silently escape the portable project."""
    reference = Path(reference)
    if reference.is_absolute():
        raise ValueError(f"Expected a portable relative path, got {reference}")
    result = (Path(base) / reference).resolve()
    if not result.is_relative_to(Path(base).resolve()):
        raise ValueError(f"Path escapes its project: {reference}")
    return result


def load_project(path):
    project_dir = Path(path).resolve()
    project = read_json(project_dir / "project.json")
    story = read_json(local_path(project_dir, project.get("storyboard", "storyboard.json")))
    project["slides"] = story.get("slides", [])
    name = project.get("theme", "anthony-dark")
    custom = project_dir / "theme.json"
    theme_path = custom if custom.exists() else ROOT / "templates" / "themes" / f"{slug(name)}.json"
    theme = read_json(theme_path)
    return project_dir, project, theme


def merged(base, updates):
    result = dict(base)
    for key, value in updates.items():
        result[key] = merged(result[key], value) if isinstance(value, dict) and isinstance(result.get(key), dict) else value
    return result


def compile_swift(source, cache=None):
    source = Path(source).resolve()
    if platform.system() != "Darwin" or not shutil.which("swiftc"):
        raise RuntimeError("This renderer needs macOS and Xcode Command Line Tools (swiftc). Static SVG previews still work on other systems.")
    cache = Path(cache or ROOT / "build" / ".cache")
    cache.mkdir(parents=True, exist_ok=True)
    # Include the compiler version: binaries are cache, never distributed source.
    version = subprocess.run(["swiftc", "--version"], capture_output=True, text=True, check=True).stdout
    key = hashlib.sha256((digest(source) + version).encode()).hexdigest()[:16]
    target = cache / f"{source.stem}-{key}"
    if not target.exists():
        subprocess.run(["swiftc", "-O", str(source), "-o", str(target)], check=True)
    return target


def environment():
    return {
        "platform": platform.platform(),
        "python": platform.python_version(),
        "macos_native_rendering": platform.system() == "Darwin",
        "swiftc": bool(shutil.which("swiftc")),
        "keynote_installed": Path("/Applications/Keynote.app").exists(),
        "pdftotext": bool(shutil.which("pdftotext")),
        "no_api_key_required": True,
    }
