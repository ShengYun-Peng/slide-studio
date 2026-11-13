"""Small, inspectable layout functions. Geometry is in a 1920x1080 canvas.

The resulting manifest is shared by SVG, PNG, and editable Keynote adapters.
Use an `items` override on a slide for a custom diagram; do not screenshot text.
"""
from __future__ import annotations

import html
import math
import re
from pathlib import Path

from .common import local_path

LAYOUTS = {"title", "question", "bullets", "takeaway", "comparison", "roadmap", "paper-cover", "impact", "acknowledgements", "scene"}


def char_width(text):
    return sum(0.28 if c in " ilI.,:;'!|" else 0.85 if c in "MW@%" else 1.0 if ord(c) > 0x2FFF else 0.53 for c in text)


def wrap(text, width, size):
    lines = []
    for paragraph in str(text).split("\n"):
        current = ""
        for word in paragraph.split():
            candidate = f"{current} {word}".strip()
            if current and char_width(candidate) * size > width:
                lines.append(current)
                current = word
            else:
                current = candidate
        lines.append(current)
    return "\n".join(lines)


def make_manifest(slide, theme, project_dir, number, total):
    W, H = theme.get("canvas", [1920, 1080])
    fg, muted, panel = theme["foreground"], theme["muted"], theme["panel"]
    accents = theme["accents"]
    regular, bold = theme["font_regular"], theme["font_bold"]
    items = []

    def text(value, x, y, w, size=44, color=fg, weight=False, align="left", h=None, reading_role="primary"):
        role,baseline=("title_size",64) if size>=60 else ("body_size",44) if size>=38 else ("label_size",32) if size>=30 else ("caption_size",28)
        size=round(size*theme.get(role,baseline)/baseline,2) if reading_role!="page-number" else size
        if reading_role=="primary":size=max(size,theme.get("min_readable_size",0))
        # Approximate character widths need tolerance for native font metrics and
        # text-box insets. Reserve wrapped height before placing the next object.
        value = wrap(value, w*.92, size)
        items.append(dict(type="text", text=value, x=x, y=y, w=w,
                          h=h or (len(value.split("\n")) * size * 1.22 + 12),
                          size=size, font=bold if weight else regular,
                          color=color, bold=weight, align=align,reading_role=reading_role))

    def rect(x,y,w,h,fill=panel,radius=24):
        items.append(dict(type="rect",x=x,y=y,w=w,h=h,fill=fill,corner_radius=radius))

    def image(reference,x,y,w,h,**options):
        path=local_path(project_dir,reference)
        items.append(dict(type="image",path=str(path),x=x,y=y,w=w,h=h,**options))

    def heading():
        text(slide.get("title",""),104,78,1712,64,weight=True)
        bottom=items[-1]["y"]+items[-1]["h"]
        if slide.get("subtitle"):
            text(slide["subtitle"],106,max(178,bottom+14),1708,32,muted)
            bottom=items[-1]["y"]+items[-1]["h"]
        return bottom

    layout=slide.get("layout","bullets")
    body=slide.get("body",[])
    if layout=="title":
        text(slide.get("eyebrow","RESEARCH TALK"),106,158,1690,30,accents[0],True)
        text(slide.get("title",""),104,280,1680,104,weight=True)
        text(slide.get("subtitle",""),110,668,1660,44,muted)
        text(slide.get("presenter","Your name · Your organization"),110,877,1660,34,fg)
    elif layout=="question":
        text(slide.get("eyebrow","THE NEXT QUESTION"),106,130,1700,30,accents[slide.get("part",0)%3],True)
        text(slide.get("title",""),104,330,1690,100,accents[slide.get("part",0)%3],True)
        if slide.get("subtitle"):
            text(slide["subtitle"],110,748,1660,40,muted)
    elif layout in ("bullets","takeaway"):
        y=max(280,heading()+44)
        for i, line in enumerate(body):
            text("•",110,y,50,48,accents[slide.get("part",0)%3],True)
            before=len(items)
            text(line,174,y,1580,50,fg,layout=="takeaway")
            y+=max(128,items[before]["h"]+46)
    elif layout=="comparison":
        top=max(274,heading()+44)
        columns=[]
        for i,col in enumerate(slide.get("columns",[])[:2]):
            x=104+i*880
            rect(x,top,832,610)
            text(col.get("title",""),x+42,top+38,748,52,accents[i],True)
            columns.append((col,x,items[-1]["y"]+items[-1]["h"]))
        body_top=max([top+148]+[end+28 for _,_,end in columns])
        for col,x,_ in columns:
            y=body_top
            for line in col.get("body",[]):
                text(line,x+42,y,748,42)
                y+=items[-1]["h"]+35
            if col.get("image"):
                image(col["image"],x+42,body_top,748,390)
    elif layout=="roadmap":
        header_bottom=heading()
        parts=slide.get("parts",[])
        y=max(226,header_bottom+30)
        for i,p in enumerate(parts):
            c=accents[i%3] if slide.get("active_part") in (None,i) else muted
            # Ring and number are separate, editable primitives, with a stable center.
            items.append(dict(type="ellipse",x=110,y=y+4,w=78,h=78,fill=theme["background"],stroke=c,stroke_width=6))
            text(str(i+1),110,y+12,78,42,c,True,"center")
            text(p.get("title",""),220,y,1540,62,c,True)
            py=y+max(92,items[-1]["h"])
            for paper in p.get("papers",[]):
                text(paper.get("title",""),266,py,565,42,c)
                left=items[-1]
                text(paper.get("detail",""),864,py,930,38,fg if slide.get("active_part") in (None,i) else muted)
                right=items[-1]
                # Baseline spacing follows the actual wrapped text. Never pack
                # larger profile fonts into the old fixed 56-unit rows.
                left["h"]-=12;right["h"]-=12
                py+=max(left["h"],right["h"])
            y=py+20
    elif layout=="paper-cover":
        text(slide.get("title",""),104,110,1712,88,accents[slide.get("part",0)%3],True)
        text(slide.get("subtitle",""),108,242,1680,54,fg,True)
        authors=slide.get("authors",[])
        gap=min(380,1570/max(len(authors),1)); start=(W-gap*len(authors))/2
        portrait_size=min(220,gap*.72)
        for i,a in enumerate(authors):
            cx=start+gap*(i+0.5)
            if a.get("portrait"):
                image(a["portrait"],cx-portrait_size/2,456,portrait_size,portrait_size,mask="circle",focal_x=a.get("focal_x",.5),focal_y=a.get("focal_y",.5))
            else:
                items.append(dict(type="ellipse",x=cx-portrait_size/2,y=456,w=portrait_size,h=portrait_size,fill=panel))
                text(a.get("initials","?"),cx-portrait_size/2,456+(portrait_size-80)/2,portrait_size,60,accents[slide.get("part",0)%3],True,"center")
            text(a.get("name","Author"),cx-gap*.46,716,gap*.92,32,fg,a.get("presenter",False),"center")
        text(slide.get("venue","Venue · Year"),104,894,1712,42,muted,False,"center")
    elif layout=="impact":
        top=max(280,heading()+44)
        columns=[]
        for i,col in enumerate(slide.get("columns",[])[:3]):
            x=104+i*582
            rect(x,top,546,600)
            text(col.get("title",""),x+34,top+38,478,48,accents[i],True)
            columns.append((col,x,items[-1]["y"]+items[-1]["h"]))
        body_top=max([top+160]+[end+30 for _,_,end in columns])
        for col,x,_ in columns:
            y=body_top
            for line in col.get("body",[]):
                text(line,x+34,y,478,40)
                y+=items[-1]["h"]+38
        if slide.get("footer"):
            text(slide["footer"],106,930,1700,30,muted)
    elif layout=="acknowledgements":
        text(slide.get("title","Thank you"),104,120,1712,100,weight=True)
        title_bottom=items[-1]["y"]+items[-1]["h"]
        if slide.get("images"):
            images=slide["images"][:4]
            for i,ref in enumerate(images):
                image(ref,104+(i%2)*866,max(310,title_bottom+30)+(i//2)*310,830,280)
        else:
            text(slide.get("subtitle",""),110,max(348,title_bottom+30),1650,58,accents[0],True)
            text("\n".join(body),110,max(572,items[-1]["y"]+items[-1]["h"]+70),1640,46,muted)
    elif layout=="scene":
        # A full-bleed motion scene can own its labels. No duplicate Keynote title.
        pass
    else:
        raise ValueError(f"Unknown layout {layout}")
    if layout not in ("title","scene") and slide.get("page_number",True):
        text(str(number),1785,1005,65,28,muted,False,"right",reading_role="page-number")
    for original in slide.get("items",[]):
        item=dict(original)
        if item.get("type")=="image":item["path"]=str(local_path(project_dir,item["path"]))
        items.append(item)
    notes_path=local_path(project_dir,slide["notes"]) if slide.get("notes") else None
    notes=notes_path.read_text(encoding="utf-8").strip() if notes_path and notes_path.exists() else ""
    return dict(id=slide["id"],width=W,height=H,background=theme["background"],items=items,notes=notes)


def svg(manifest):
    W,H=manifest["width"],manifest["height"]
    s=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',f'<rect width="100%" height="100%" fill="{manifest["background"]}"/>']
    for item in manifest["items"]:
        t=item["type"];x=item.get("x",0);y=item.get("y",0);w=item.get("w",0);h=item.get("h",0)
        if t=="text":
            size=item.get("size",44);align=item.get("align","left")
            tx=x if align=="left" else x+w/2 if align=="center" else x+w
            anchor={"left":"start","center":"middle","right":"end"}.get(align,"start")
            family=html.escape(item.get("font","Helvetica Neue"),quote=True)
            for j,line in enumerate(item.get("text","").split("\n")):
                s.append(f'<text x="{tx}" y="{y+size+j*size*1.22}" font-family="{family},Arial,sans-serif" font-size="{size}" font-weight="{700 if item.get("bold") else 400}" fill="{item.get("color","#fff")}" text-anchor="{anchor}">{html.escape(line)}</text>')
        elif t=="rect":
            s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{item.get("corner_radius",0)}" fill="{item.get("fill","none")}" stroke="{item.get("stroke","none")}" stroke-width="{item.get("stroke_width",0)}"/>')
        elif t=="ellipse":
            s.append(f'<ellipse cx="{x+w/2}" cy="{y+h/2}" rx="{w/2}" ry="{h/2}" fill="{item.get("fill","none")}" stroke="{item.get("stroke","none")}" stroke-width="{item.get("stroke_width",0)}"/>')
        elif t=="line":
            s.append(f'<line x1="{x}" y1="{y}" x2="{x+w}" y2="{y+h}" stroke="{item.get("stroke","#fff")}" stroke-width="{item.get("stroke_width",6)}"/>')
            if item.get("arrow_end"):
                angle=math.atan2(h,w);length=22
                a=(x+w-length*math.cos(angle-.5),y+h-length*math.sin(angle-.5))
                b=(x+w-length*math.cos(angle+.5),y+h-length*math.sin(angle+.5))
                s.append(f'<polyline points="{a[0]},{a[1]} {x+w},{y+h} {b[0]},{b[1]}" fill="none" stroke="{item.get("stroke","#fff")}" stroke-width="{item.get("stroke_width",6)}" stroke-linejoin="round"/>')
        elif t=="image":
            import base64,mimetypes
            p=Path(item["path"])
            if p.exists():
                data=base64.b64encode(p.read_bytes()).decode();mime=mimetypes.guess_type(p.name)[0] or "image/png"
                if item.get("mask")=="circle":
                    clip=f"portrait-{len(s)}"
                    s.append(f'<defs><clipPath id="{clip}"><ellipse cx="{x+w/2}" cy="{y+h/2}" rx="{w/2}" ry="{h/2}"/></clipPath></defs>')
                    # SVG-only hosts provide a center-filled fallback; the native PNG
                    # and Keynote paths honor the exact face focal point.
                    s.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" clip-path="url(#{clip})" href="data:{mime};base64,{data}" preserveAspectRatio="xMidYMid slice"/>')
                else:
                    s.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:{mime};base64,{data}" preserveAspectRatio="xMidYMid meet"/>')
    s.append("</svg>")
    return "\n".join(s)
