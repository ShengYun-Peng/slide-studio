from __future__ import annotations
import re
from pathlib import Path
from .common import ROOT,load_project,local_path,read_json
from .layout import LAYOUTS,make_manifest,char_width


def contrast(a,b):
    def luminance(h):
        rgb=[int(h.lstrip("#")[i:i+2],16)/255 for i in (0,2,4)]
        rgb=[v/12.92 if v<=0.04045 else ((v+0.055)/1.055)**2.4 for v in rgb]
        return sum(v*w for v,w in zip(rgb,(.2126,.7152,.0722)))
    x,y=sorted([luminance(a),luminance(b)])
    return (y+.05)/(x+.05)


def validate(project_path):
    issues=[];summaries=[]
    try: directory,project,theme=load_project(project_path)
    except (ValueError,OSError,KeyError) as e:return {"ok":False,"issues":[{"level":"error","message":str(e)}],"slides":[]}
    def report(level,message,slide=None):issues.append({"level":level,"slide":slide,"message":message})
    if project.get("schema_version")!=1:report("error","Expected schema_version 1")
    slides=project["slides"];seen=set();elapsed=0
    if not slides:report("error","Storyboard has no slides")
    for n,s in enumerate(slides,1):
        sid=s.get("id","")
        if not re.fullmatch(r"[a-z][a-z0-9-]{1,79}",sid):report("error","Use a stable lower-case semantic ID, not a slide number",sid)
        if sid in seen:report("error","Duplicate slide ID",sid)
        seen.add(sid)
        if s.get("layout") not in LAYOUTS:report("error",f"Unknown layout {s.get('layout')}",sid);continue
        try:m=make_manifest(s,theme,directory,n,len(slides))
        except (ValueError,OSError,KeyError) as e:report("error",str(e),sid);continue
        if not s.get("notes") or not m["notes"]:report("warning","No spoken notes yet",sid)
        words=len(re.findall(r"\b[\w'-]+\b",m["notes"]))
        limit=95 if s.get("scene") else 65
        if words>limit:report("warning",f"Notes have {words} words (review against a {limit}-word starting budget)",sid)
        if re.search(r"<!--|\bTODO\b|\[production\]|^#{1,6}\s",m["notes"],re.M):report("warning","Notes contain likely production comments or headings; keep spoken text only",sid)
        duration=0
        if s.get("scene"):
            from .pipeline import scene_config
            scene_id=s["scene"].get("template","")
            config=ROOT/"scenes"/scene_id/"scene.json"
            if not config.exists():report("error",f"Missing scene template {scene_id}",sid)
            else:
                try:duration=scene_config(scene_id,s["scene"].get("overrides"),theme)["duration"]
                except (ValueError,TypeError,KeyError) as e:report("error",str(e),sid)
            if s.get("layout")!="scene":report("warning","Scene video may cover a static layout; prefer layout=scene or explicit movie bounds",sid)
        elapsed+=max(words/float(project.get("speaking_wpm",140))*60,duration)+1.5
        for item in m["items"]:
            x,y,w,h=(item.get(k,0) for k in ("x","y","w","h"))
            if min(x,y)<-1 or x+w>m["width"]+1 or y+h>m["height"]+1:report("error",f"Item outside canvas: {item.get('text',item['type'])[:65]}",sid)
            if item["type"]=="text":
                size=item.get("size",44)
                reading_role=item.get("reading_role","primary")
                floor=theme.get("min_readable_size",28)
                if item.get("text","").strip() and reading_role not in ("page-number","reference") and size<floor:
                    report("warning",f"Audience-read text is {size}pt; profile minimum is {floor}pt. Shorten, split, or enlarge: {item['text'][:55]}",sid)
                if len(item.get("text","").splitlines())*size*1.22>h+2:
                    report("warning",f"Text height is too small for its lines: {item['text'][:55]}",sid)
                if max((char_width(line)*size for line in item["text"].split("\n")),default=0)>w+2:report("warning",f"A long word may overflow: {item['text'][:55]}",sid)
                if contrast(item.get("color",theme["foreground"]),theme["background"])<3:report("warning",f"Low text/background contrast; inspect any panel behind it: {item['text'][:55]}",sid)
            if item["type"]=="image" and not Path(item["path"]).exists():report("error",f"Missing image {item['path']}",sid)
        # Text-to-text collisions matter; text intentionally inside a panel does not.
        texts=[i for i in m["items"] if i["type"]=="text" and i.get("text")]
        for a_i,a in enumerate(texts):
            for b in texts[a_i+1:]:
                dx=min(a["x"]+a["w"],b["x"]+b["w"])-max(a["x"],b["x"])
                dy=min(a["y"]+a["h"],b["y"]+b["h"])-max(a["y"],b["y"])
                if dx>12 and dy>12:report("warning",f"Text boxes overlap; inspect: {a['text'][:32]} / {b['text'][:32]}",sid)
        if s.get("claim_type")=="measured" and not s.get("evidence"):report("error","Measured claim needs an evidence reference (source ID + page/figure/URL)",sid)
        summaries.append({"id":sid,"words":words,"movie_seconds":duration,"estimated_seconds":round(max(words/float(project.get("speaking_wpm",140))*60,duration)+1.5,1)})
    return {"ok":not any(i["level"]=="error" for i in issues),"issues":issues,"slides":summaries,"estimated_minutes":round(elapsed/60,1),"timing_caveat":"Narration and movie overlap; this is a planning estimate, not a rehearsal. Appendix inclusion is controlled by the storyboard."}
