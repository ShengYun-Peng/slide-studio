"""Read-only source intake. Extraction is not a promise of layout conversion."""
from __future__ import annotations
import hashlib
import platform
import shutil
import subprocess
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse
from .common import ROOT,compile_swift,digest,read_json,slug,write_json


def ingest(value, project, kind="auto"):
    project=Path(project).resolve();sources=project/"sources";sources.mkdir(parents=True,exist_ok=True)
    manifest=sources/"manifest.json"
    records=read_json(manifest).get("sources",[]) if manifest.exists() else []
    if value.startswith(("http://","https://")):
        key=hashlib.sha256(value.encode()).hexdigest()[:12]
        record={"id":key,"kind":"figma-reference" if "figma.com" in urlparse(value).netloc else "web-reference","url":value,"status":"reference-only; agent must read with a connected tool or add a local export","trusted_instructions":False,"redistribution":"unreviewed"}
    else:
        original=Path(value).expanduser().resolve()
        if not original.exists():raise FileNotFoundError(original)
        if original.is_dir():
            # Keynote packages can be directories. Keep a deterministic archive.
            if original.suffix.lower()!=".key":raise ValueError("Directory intake is supported only for a Keynote .key package. Add other files individually.")
            staging=sources/(slug(original.stem)+"-package")
            archive=Path(shutil.make_archive(str(staging),"zip",root_dir=original))
            checksum=digest(archive);dest=sources/(checksum[:12]+"-"+original.name+".zip")
            archive.replace(dest)
        else:
            checksum=digest(original);dest=sources/(checksum[:12]+"-"+original.name)
            if original!=dest:shutil.copy2(original,dest)
        suffix=original.suffix.lower();detected={".pdf":"pdf",".pptx":"pptx",".ppt":"legacy-ppt",".key":"keynote",".png":"image",".jpg":"image",".jpeg":"image",".svg":"vector",".md":"text",".txt":"text",".mp4":"video",".mov":"video"}.get(suffix,"file")
        kind=detected if kind=="auto" else kind
        record={"id":checksum[:12],"kind":kind,"path":str(dest.relative_to(project)),"sha256":checksum,"original_filename":original.name,"trusted_instructions":False,"redistribution":"unreviewed","status":"registered"}
        derived=project/"derived"/checksum[:12];derived.mkdir(parents=True,exist_ok=True)
        if kind=="pptx":
            ns={"a":"http://schemas.openxmlformats.org/drawingml/2006/main"}
            with zipfile.ZipFile(dest) as z:
                texts=[]
                for name in sorted(z.namelist()):
                    if (name.startswith("ppt/slides/slide") or name.startswith("ppt/notesSlides/notesSlide")) and name.endswith(".xml"):
                        root=ET.fromstring(z.read(name));text="\n".join(t.text or "" for t in root.findall(".//a:t",ns));texts.append({"source_part":name,"text":text})
                    elif name.startswith("ppt/media/") and not name.endswith("/"):
                        target=derived/"media"/Path(name).name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
                write_json(derived/"extracted.json",{"parts":texts,"limitation":"Text and media only; layout, animation, and evidence context require visual inspection."})
            record["status"]="text/media extracted; visual inspection required"
        elif kind=="pdf":
            if platform.system()=="Darwin" and shutil.which("swiftc"):
                binary=compile_swift(ROOT/"runtime/pdf_extract.swift")
                subprocess.run([str(binary),str(dest),str(derived),"8"],check=True)
                record["status"]="text plus first 8 page previews extracted"
            elif shutil.which("pdftotext"):
                subprocess.run(["pdftotext","-layout",str(dest),str(derived/"extracted.txt")],check=True);record["status"]="text extracted; visual previews need a PDF renderer"
            else:record["status"]="registered; PDF extraction needs macOS Swift/PDFKit or pdftotext"
        elif kind=="keynote":
            if zipfile.is_zipfile(dest):
                with zipfile.ZipFile(dest) as z:
                    for name in z.namelist():
                        if name.startswith("Metadata/") and name.endswith(".plist"):continue
                        if name.startswith("preview") and name.lower().endswith((".jpg",".png",".jpeg")):
                            (derived/Path(name).name).write_bytes(z.read(name))
                record["status"]="registered with embedded preview when available; inspect editable slides in native Keynote"
            else:record["status"]="registered; inspect in native Keynote"
        elif kind=="legacy-ppt":record["status"]="registered; convert a copy to PPTX in its native application before extraction"
        if any(derived.iterdir()):record["derived"]=str(derived.relative_to(project))
    records=[r for r in records if r["id"]!=record["id"]]+[record]
    write_json(manifest,{"schema_version":1,"sources":records})
    return record
