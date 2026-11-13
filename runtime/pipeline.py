from __future__ import annotations
import html
import math
import os
import platform
import shutil
import subprocess
from pathlib import Path
from .common import ROOT,compile_swift,digest,environment,load_project,local_path,merged,read_json,write_json
from .layout import make_manifest,svg

ASSET_FIELDS=("screen_image","hardware_video","screen_tracking","logo_pdf","background_video","table_image","frame_image","source_image","before_image","after_image")

def renderer_for(scene_id):
    catalog=read_json(ROOT/"scenes/catalog.json")
    if isinstance(catalog,dict):catalog=catalog["scenes"]
    entry=next((s for s in catalog if s["id"]==scene_id),None)
    if not entry:raise ValueError(f"Unknown scene: {scene_id}")
    path=local_path(ROOT,entry.get("renderer","runtime/swift/main.swift"))
    if not path.is_relative_to(ROOT/"runtime") or path.suffix!=".swift":raise ValueError("Scene renderer must be a bundled Swift source under runtime/")
    return path


def scene_config(scene_id,overrides=None,theme=None):
    # Resolve by catalog ID, not arbitrary paths.
    if not scene_id or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-" for c in scene_id):raise ValueError("Invalid scene ID")
    config=read_json(ROOT/"scenes"/scene_id/"scene.json")
    if theme:config=merged(config,{"theme":theme})
    overrides=overrides or {}
    # A duration-only override is a speed change: retime every inherited event,
    # poster and review timestamp together. Explicit supplied times win afterward.
    if "duration" in overrides:
        ratio=float(overrides["duration"])/float(config["duration"])
        config=merged(config,{"timing":{k:v*ratio for k,v in config.get("timing",{}).items()}})
        if "poster_time" in config:config["poster_time"]*=ratio
        if "preview_times" in config:config["preview_times"]=[v*ratio for v in config["preview_times"]]
        if "timeline" in config:config["timeline"]=[dict(v,at=v["at"]*ratio) for v in config["timeline"]]
        if config.get("kind")=="interface-tour":
            for track in ("shots","camera","pointer","captions"):
                for event in config.get("content",{}).get(track,[]):
                    event["time"]*=ratio
                    if "fade" in event:event["fade"]*=ratio
    result=merged(config,overrides)
    validate_scene_config(result)
    return result


def validate_scene_config(config):
    duration=float(config.get("duration",0))
    if not 0<duration<=300:raise ValueError("Scene duration must be in (0, 300] seconds")
    for name,time in config.get("timing",{}).items():
        if not isinstance(time,(int,float)) or not 0<=time<=duration:raise ValueError(f"Scene timing {name}={time} is outside 0..{duration}s")
        if name.endswith("_end"):
            start=config.get("timing",{}).get(name[:-4]+"_start",0)
            if start>time:raise ValueError(f"Scene {name} occurs before its start")
    for time in config.get("preview_times",[])+([config["poster_time"]] if "poster_time" in config else []):
        if not 0<=time<=duration:raise ValueError(f"Scene preview/poster time {time} is outside 0..{duration}s")
    for key in ("parts","modules","apps"):
        if key in config.get("content",{}) and len(config["content"][key])!=3:raise ValueError(f"The current {key} topology uses exactly 3 labels; adapt the renderer for another count")
    anchors=config.get("timeline",[])
    if anchors:
        if anchors[0].get("at")!=0 or abs(anchors[-1].get("at",-1)-duration)>.001:raise ValueError("Timeline must begin at 0 and end at duration")
        for a,b in zip(anchors,anchors[1:]):
            if b["at"]<=a["at"] or b.get("reference",0)<a.get("reference",0):raise ValueError("Timeline anchors must advance in order")
    if config.get("kind")=="interface-tour":validate_interface_tour(config)


def validate_interface_tour(config):
    """Protect deterministic camera/state interpolation before invoking Swift."""
    def finite(value):return isinstance(value,(int,float)) and not isinstance(value,bool) and math.isfinite(value)
    duration=config["duration"];content=config.get("content",{})
    if not isinstance(content,dict):raise ValueError("Interface content must be an object")
    w,h,fps=(config.get(k) for k in ("width","height","fps"))
    if any(not isinstance(v,int) or isinstance(v,bool) or v<=0 for v in (w,h,fps)) or fps>120:
        raise ValueError("Interface tour needs positive integer width, height and fps (1..120)")
    if w%2 or h%2 or abs(w/h-16/9)>.001:raise ValueError("Interface tour uses even-sized 16:9 output and 1920×1080 logical geometry")
    viewport=content.get("viewport",[96,238,1728,720])
    if not isinstance(viewport,list) or len(viewport)!=4 or not all(finite(v) for v in viewport) or min(viewport[2:])<=0:
        raise ValueError("Interface viewport must be [x,y,positive width,positive height]")
    if min(viewport[:2])<0 or viewport[0]+viewport[2]>1920 or viewport[1]+viewport[3]>1080:
        raise ValueError("Interface viewport must fit the 1920×1080 logical slide")
    assets=content.get("assets",{})
    if not isinstance(assets,dict) or not assets:raise ValueError("Interface tour needs named lossless state assets")
    def asset(value):
        if not isinstance(value,dict):raise ValueError("Each interface asset must be an object")
        r=value.get("rect",[])
        if not isinstance(value.get("file"),str) or not value["file"] or not isinstance(r,list) or len(r)!=4 or not all(finite(v) for v in r) or min(r[2:])<=0:
            raise ValueError("Each interface asset needs file and [x,y,positive width,positive height]")
        if not isinstance(value.get("layers",[]),list):raise ValueError("Interface detail layers must be an array")
        for layer in value.get("layers",[]):asset(layer)
    for value in assets.values():asset(value)
    for name in ("shots","camera","pointer","captions"):
        events=content.get(name,[])
        if not isinstance(events,list) or not all(isinstance(event,dict) for event in events):
            raise ValueError(f"Interface {name} must be an array of event objects")
        if name in ("shots","camera") and (not events or events[0].get("time")!=0):
            raise ValueError(f"Interface {name} must begin at 0")
        previous=-1
        for event in events:
            t=event.get("time")
            if not finite(t) or not previous<t<=duration:raise ValueError(f"Interface {name} times must increase inside 0..duration")
            previous=t
            if "fade" in event and (not finite(event["fade"]) or event["fade"]<0 or t+event["fade"]>duration):
                raise ValueError(f"Interface {name} fade must finish inside the scene")
            if name=="shots" and event.get("asset") not in assets:raise ValueError("Interface shot refers to an unknown asset")
            if name in ("camera","pointer") and not all(finite(event.get(k)) for k in ("x","y")):
                raise ValueError(f"Interface {name} needs finite x/y coordinates")
            if name=="camera" and (not finite(event.get("w")) or event["w"]<=0):raise ValueError("Interface camera width must be positive")
            if name=="captions" and not isinstance(event.get("text"),str):raise ValueError("Interface caption needs text")


def resolve_scene_assets(config,base,template_base=None,overrides=None):
    result=merged(config,{})
    hashes={}
    # Bundled scene assets may use ../../assets within this repository. Project
    # overrides resolve against the working project, never the staging folder.
    for key in ASSET_FIELDS:
        image=config.get("content",{}).get(key)
        if not image:continue
        origin=Path(template_base if template_base and key not in (overrides or {}).get("content",{}) else base).resolve()
        path=(origin/image).resolve()
        allowed=ROOT if origin.is_relative_to(ROOT) else origin
        if not path.is_relative_to(allowed):raise ValueError(f"Scene asset escapes its portable root: {image}")
        if not path.is_file():raise FileNotFoundError(path)
        result=merged(result,{"content":{key:str(path)}})
        hashes[image]=digest(path)
    # A captured interface is a set of full states plus high-DPR detail layers.
    # Resolve each overridden file independently, so changing a camera or one
    # layer does not accidentally relocate every inherited bundled asset.
    def resolve_asset(value,override):
        result=merged(value,{})
        reference=value["file"]
        origin=Path(template_base if template_base and "file" not in override else base).resolve()
        path=(origin/reference).resolve();allowed=ROOT if origin.is_relative_to(ROOT) else origin
        if not path.is_relative_to(allowed):raise ValueError(f"Scene asset escapes its portable root: {reference}")
        if not path.is_file():raise FileNotFoundError(path)
        result["file"]=str(path)
        # Include the namespace to distinguish same-named assets in two roots.
        key=f"{'template' if template_base and 'file' not in override else 'project'}:{reference}"
        hashes[key]=digest(path)
        if "layers" in value:
            layer_overrides=override.get("layers")
            result["layers"]=[resolve_asset(layer,layer if layer_overrides is not None else {}) for layer in value["layers"]]
        return result
    if config.get("kind")=="interface-tour":
        overrides_assets=(overrides or {}).get("content",{}).get("assets",{})
        result["content"]=dict(result["content"])
        result["content"]["assets"]={name:resolve_asset(asset,overrides_assets.get(name,{})) for name,asset in config["content"]["assets"].items()}
    return result,hashes


def render_scene(scene_id,output,overrides=None,theme=None,preview_only=False,config_path=None,asset_base=None):
    output=Path(output).resolve();output.mkdir(parents=True,exist_ok=True)
    config=read_json(config_path) if config_path else scene_config(scene_id,overrides,theme)
    validate_scene_config(config)
    write_json(output/"requested-scene.json",config)
    base=Path(config_path).resolve().parent if config_path else Path(asset_base) if asset_base else ROOT/"scenes"/scene_id
    resolved,asset_hashes=resolve_scene_assets(config,base,ROOT/"scenes"/scene_id if asset_base and not config_path else None,overrides)
    config_file=output/"resolved-scene.json";write_json(config_file,resolved)
    renderer=renderer_for(scene_id)
    binary=compile_swift(renderer)
    subprocess.run([str(binary),"--config",str(config_file),"--output",str(output),"--preview" if preview_only else "--video"],check=True)
    write_json(output/"inputs.json",{"schema_version":1,"config_sha256":digest(config_file),"renderer":str(renderer.relative_to(ROOT)),"renderer_sha256":digest(renderer),"asset_hashes":asset_hashes,"environment":environment()})
    return output


def manifests(project_path,include_motion=True):
    directory,project,theme=load_project(project_path)
    result=[]
    for number,s in enumerate(project["slides"],1):
        m=make_manifest(s,theme,directory,number,len(project["slides"]))
        if include_motion and s.get("scene"):
            out=directory/"build"/"motion"/s["id"]
            if (out/"end.png").exists():
                m["items"].insert(0,{"type":"image","path":str(out/"end.png"),"x":0,"y":0,"w":m["width"],"h":m["height"]})
            if (out/"movie.mp4").exists():
                m["movie"]={"path":str(out/"movie.mp4"),"poster":str(out/"end.png"),"x":0,"y":0,"w":m["width"],"h":m["height"],"autoplay":True}
        result.append(m)
    return directory,project,theme,result


def render_project(project_path,preview_only=False):
    directory,project,theme=load_project(project_path)
    for s in project["slides"]:
        if not s.get("scene"):continue
        print(f"Rendering {s['id']} …",flush=True)
        render_scene(s["scene"]["template"],directory/"build/motion"/s["id"],s["scene"].get("overrides"),theme,preview_only,asset_base=directory)


def motion_is_current(directory, slide, theme, require_movie=True):
    out=Path(directory)/"build/motion"/slide["id"]
    try:
        config=scene_config(slide["scene"]["template"],slide["scene"].get("overrides"),theme)
        inputs=read_json(out/"inputs.json")
        resolved,hashes=resolve_scene_assets(config,directory,ROOT/"scenes"/slide["scene"]["template"],slide["scene"].get("overrides"))
        return (read_json(out/"requested-scene.json")==config
                and inputs.get("asset_hashes",{})==hashes
                and inputs["renderer_sha256"]==digest(renderer_for(slide["scene"]["template"]))
                and (out/("movie.mp4" if require_movie else "end.png")).exists())
    except (OSError,ValueError,KeyError):return False


def preview_project(project_path):
    directory,project,theme=load_project(project_path)
    if platform.system()=="Darwin" and shutil.which("swiftc"):
        for slide in project["slides"]:
            if slide.get("scene") and not motion_is_current(directory,slide,theme,False):
                render_scene(slide["scene"]["template"],directory/"build/motion"/slide["id"],slide["scene"].get("overrides"),theme,True,asset_base=directory)
    directory,project,theme,slides=manifests(project_path)
    out=directory/"build"/"preview";out.mkdir(parents=True,exist_ok=True)
    binary=compile_swift(ROOT/"runtime/static_render.swift") if platform.system()=="Darwin" and shutil.which("swiftc") else None
    cards=[]
    for i,m in enumerate(slides,1):
        file=out/f"{m['id']}.json";write_json(file,m)
        (out/f"{m['id']}.svg").write_text(svg(m),encoding="utf-8")
        if binary:subprocess.run([str(binary),str(file),str(out/f"{m['id']}.png"),"1280"],check=True)
        ext="png" if binary else "svg"
        note=html.escape(m["notes"])
        cards.append(f'<article><h2>{i:02} · {html.escape(m["id"])}</h2><img src="{m["id"]}.{ext}" alt="Slide {i}"><details><summary>Spoken notes</summary><p>{note}</p></details></article>')
    page=html_page(project["title"],"Static previews. Native Keynote playback and presenter-notes appearance need a separate review.","\n".join(cards))
    (out/"index.html").write_text(page,encoding="utf-8")
    paths=[directory/"project.json",directory/project.get("storyboard","storyboard.json")]+[directory/s["notes"] for s in project["slides"] if s.get("notes")]
    write_json(directory/"build"/"manifest.json",{"schema_version":1,"slides":slides,"environment":environment(),"theme":theme,"input_hashes":{str(p.relative_to(directory)):digest(p) for p in paths}})
    return out/"index.html"


def html_page(title,subtitle,body):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)}</title><style>
    :root{{color-scheme:dark}}*{{box-sizing:border-box}}body{{margin:0;background:#202123;color:#f6f6f4;font:17px/1.55 system-ui,-apple-system,sans-serif}}header,main{{max-width:1280px;margin:auto;padding:36px}}h1{{font-size:46px;line-height:1.1;margin:16px 0}}h2{{font-size:24px;margin:10px 0}}p{{max-width:900px;color:#c5ccd5}}a{{color:#8bbcff}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:24px}}article{{background:#2b2b2d;padding:20px;border-radius:18px;margin-bottom:24px}}img,video{{width:100%;display:block;border-radius:8px}}code{{background:#17181a;padding:3px 6px;border-radius:4px}}details{{margin-top:14px}}summary{{cursor:pointer}}.tag{{display:inline-block;color:#95cd89;margin-right:15px}}@media(max-width:600px){{header,main{{padding:20px}}.grid{{grid-template-columns:1fr}}h1{{font-size:34px}}}}
    </style><header><span class="tag">SLIDE STUDIO · LOCAL REVIEW</span><h1>{html.escape(title)}</h1><p>{html.escape(subtitle)}</p></header><main>{body}</main></html>'''


def gallery(output):
    from .gallery import build_gallery
    return build_gallery(output)


def verify_project(project_path):
    from .checks import validate
    result=validate(project_path);directory,project,theme=load_project(project_path)
    checks=[]
    previous=read_json(directory/"build/manifest.json") if (directory/"build/manifest.json").exists() else {}
    checks.append({"check":"preview manifest exists","ok":bool(previous)})
    for reference,checksum in previous.get("input_hashes",{}).items():
        p=directory/reference
        checks.append({"check":f"current preview input: {reference}","ok":p.exists() and digest(p)==checksum})
    checks.append({"check":"preview theme is current","ok":previous.get("theme")==theme})
    for s in project["slides"]:
        for suffix in ("svg","json"):
            p=directory/"build/preview"/f"{s['id']}.{suffix}";checks.append({"check":f"{s['id']} preview {suffix}","ok":p.exists()})
        if s.get("scene"):
            out=directory/"build/motion"/s["id"]
            config=scene_config(s["scene"]["template"],s["scene"].get("overrides"),theme)
            current=read_json(out/"requested-scene.json") if (out/"requested-scene.json").exists() else None
            checks.extend([{"check":f"{s['id']} motion config matches","ok":current==config},{"check":f"{s['id']} movie exists","ok":(out/"movie.mp4").exists()}])
            checks.append({"check":f"{s['id']} renderer matches","ok":motion_is_current(directory,s,theme)})
    result["artifact_checks"]=checks;result["ok"]=result["ok"] and all(c["ok"] for c in checks)
    result["requires_visual_review"]=["Open static previews: wrapping, alignment, contrast, labels, image crop.","Play movies and native Keynote: timing, movie autoplay, manual slide advance, end-frame continuity.","Check native presenter notes in your actual light/dark editor; RGB metadata alone is insufficient."]
    write_json(directory/"build/verification.json",result);return result
