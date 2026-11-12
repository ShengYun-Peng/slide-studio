#!/usr/bin/env python3
"""Slide Studio: an agent-neutral command line for local presentation projects."""
from __future__ import annotations
import argparse
import json
import shutil
import sys
from pathlib import Path
from runtime.common import ROOT,environment,load_project,read_json,write_json


def parser():
    p=argparse.ArgumentParser(description=__doc__)
    sub=p.add_subparsers(dest="command",required=True)
    sub.add_parser("doctor",help="Report local capabilities without changing the machine")
    sub.add_parser("catalog",help="List reusable scenes and themes")
    init=sub.add_parser("init",help="Create an independent presentation working folder")
    init.add_argument("path",nargs="?",default="my-project");init.add_argument("--title",default="A new research talk");init.add_argument("--theme",default="anthony-dark")
    intake=sub.add_parser("ingest",help="Copy and index a source, preserving the original")
    intake.add_argument("input");intake.add_argument("--project",default="my-project");intake.add_argument("--kind",default="auto")
    for name in ("validate","preview","verify"):
        command=sub.add_parser(name);command.add_argument("--project",default="my-project")
    render=sub.add_parser("render",help="Render a scene or every scene used in a project")
    group=render.add_mutually_exclusive_group(required=True);group.add_argument("--scene");group.add_argument("--project")
    render.add_argument("--config",help="Full scene JSON (when --scene is used)");render.add_argument("--output");render.add_argument("--preview-only",action="store_true")
    assemble=sub.add_parser("assemble",help="Build an editable native Keynote presentation on macOS")
    assemble.add_argument("--project",default="my-project");assemble.add_argument("--output");assemble.add_argument("--overwrite",action="store_true")
    gal=sub.add_parser("gallery",help="Build the local demo selection page");gal.add_argument("--output",default=str(ROOT/"review/index.html"))
    return p


def main():
    args=parser().parse_args();cmd=args.command
    if cmd=="doctor":
        print(json.dumps(environment(),indent=2));print("\nStatic planning, validation and SVG previews work without Keynote. Movie rendering needs macOS + swiftc. Keynote assembly needs Keynote and Automation permission.")
    elif cmd=="catalog":
        catalog=read_json(ROOT/"scenes/catalog.json")
        print(json.dumps({"scenes":catalog,"themes":[p.stem for p in (ROOT/"templates/themes").glob("*.json")]},indent=2))
    elif cmd=="init":
        destination=Path(args.path).resolve()
        if destination.exists() and any(destination.iterdir()):raise ValueError(f"Refusing to replace an existing project: {destination}")
        source=ROOT/"examples/urban-gardens"
        shutil.copytree(source,destination,dirs_exist_ok=True,ignore=shutil.ignore_patterns("build","output","demo",".DS_Store"))
        project=read_json(destination/"project.json");project.update(title=args.title,theme=args.theme);write_json(destination/"project.json",project)
        story=read_json(destination/"storyboard.json");story["slides"][0]["title"]=args.title;write_json(destination/"storyboard.json",story)
        print(f"Created {destination}. Replace the illustrative garden content and notes with your researched topic; start with brief.md.")
    elif cmd=="ingest":
        from runtime.ingest import ingest
        print(json.dumps(ingest(args.input,args.project,args.kind),indent=2))
    elif cmd=="validate":
        from runtime.checks import validate
        result=validate(args.project);print(json.dumps(result,indent=2));return 0 if result["ok"] else 1
    elif cmd=="preview":
        from runtime.pipeline import preview_project
        print(preview_project(args.project))
    elif cmd=="render":
        from runtime.pipeline import render_project,render_scene
        if args.project:render_project(args.project,args.preview_only)
        else:print(render_scene(args.scene,args.output or ROOT/"build/scenes"/args.scene,preview_only=args.preview_only,config_path=args.config))
    elif cmd=="assemble":
        from runtime.checks import validate
        from runtime.pipeline import render_project,preview_project,manifests,motion_is_current
        from runtime import keynote
        result=validate(args.project)
        if not result["ok"]:print(json.dumps(result,indent=2));return 1
        directory,project,theme=load_project(args.project)
        output=Path(args.output).resolve() if args.output else directory/"output"/"presentation.key"
        if output.exists() and not args.overwrite:raise ValueError(f"Output exists: {output}. Preserve manual edits; choose a new --output, or use --overwrite deliberately.")
        if any(s.get("scene") and not motion_is_current(directory,s,theme) for s in project["slides"]):render_project(directory)
        preview_project(directory)
        directory,project,theme,slides=manifests(directory)
        print(json.dumps(keynote.assemble(directory,output,slides,theme,overwrite=args.overwrite),indent=2,default=str))
    elif cmd=="verify":
        from runtime.pipeline import verify_project
        result=verify_project(args.project);print(json.dumps(result,indent=2));return 0 if result["ok"] else 1
    elif cmd=="gallery":
        from runtime.pipeline import gallery
        print(gallery(args.output))
    return 0


if __name__=="__main__":
    try:sys.exit(main())
    except (OSError,ValueError,RuntimeError) as error:
        print(f"Slide Studio: {error}",file=sys.stderr);sys.exit(1)
