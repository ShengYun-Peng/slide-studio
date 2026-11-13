"""Safe native Keynote assembly and notes updates (macOS, Python standard library).

Static text remains editable. Shapes are individual PNG primitives because
Keynote's AppleScript dictionary exposes no shape-fill setter. Movies remain
native movie objects; autoplay needs a one-time manual Keynote setting.
This module never reads or writes the defense deck or another project.
"""
from __future__ import annotations
from functools import lru_cache
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import time
import uuid

from .keynote_helpers import primitives

MARKER = 'slide-studio:id='
ID_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$')


class KeynoteError(RuntimeError):
    pass


class NotesConflict(KeynoteError):
    """No notes were changed because the saved baseline no longer matches."""


def _q(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r') + '"'


def _n(value):
    value = float(value)
    if not (-100000 < value < 100000):
        raise ValueError(f'Invalid slide coordinate {value}')
    return str(int(value)) if value.is_integer() else str(value)


def _rgb(value):
    return '{' + ','.join(str(c*257) for c in primitives.rgba(value)[:3]) + '}'


def parse_notes(markdown):
    """Return plain text and 1-based inclusive bold ranges.

    Only **emphasis** is markup. [pause] remains a spoken pacing cue. Native
    Keynote character indexing was checked with non-BMP emoji: it uses Unicode
    characters, not UTF-16 code units. Unmatched ** is rejected, not discarded.
    """
    text, ranges, start, cursor = [], [], None, 1
    pieces = str(markdown).split('**')
    if len(pieces) % 2 == 0:
        raise ValueError('Unmatched ** in presenter notes')
    for i, piece in enumerate(pieces):
        if i % 2:
            start = cursor
        text.append(piece)
        cursor += len(piece)
        if i % 2 and piece:
            ranges.append((start, cursor - 1))
    return ''.join(text), ranges


def _write(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding='utf-8')
    return path


def _json(path, value):
    _write(path, json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def _read_expr(path):
    return f'(read POSIX file {_q(path)} as «class utf8»)'


def _within(path, root):
    path, root = Path(path).expanduser().resolve(), Path(root).expanduser().resolve()
    if not path.is_relative_to(root):
        raise ValueError(f'Output must stay in this project: {path}')
    return path


def _run(script, directory, timeout=240):
    if platform.system() != 'Darwin':
        raise KeynoteError('Native Keynote assembly requires macOS and Keynote. PNG/MP4 preview is portable.')
    path = _write(Path(directory) / 'operation.applescript', script)
    try:
        r = subprocess.run(['osascript', str(path)], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        raise KeynoteError(f'Keynote timed out. Inspect the owned document before retrying; script: {path}') from exc
    if r.returncode:
        raise KeynoteError(f'Keynote operation failed: {r.stderr.strip()}\nScript retained: {path}')
    return r.stdout.strip()


def capabilities():
    return {
        'platform':'macOS + Keynote', 'static_text_editable':True,
        'image_objects':True, 'native_movies':True, 'native_notes':True,
        'notes_font_size':25, 'notes_color':'native black, adaptive in dark notes UI',
        'movie_autoplay_via_applescript':False,
        'custom_movie_poster_via_applescript':False,
        'slide_advance':'manual',
        'native_builds_via_applescript':False,
        'circle_mask':'non-destructive AppKit crop; optional Swift helper',
        'panel_fill':'individual generated PNG primitives',
        'text_alignment':'positioned native editable text lines; explicit line breaks preserve spacing',
        'notes_binding':'stable ID in background image description, independent of slide order',
    }


AS_HEADER = '''on writeUTF8(value, targetPath)
 set fileRef to open for access POSIX file targetPath with write permission
 try
  set eof fileRef to 0
  write value to fileRef as «class utf8»
  close access fileRef
 on error msg number num
  close access fileRef
  error msg number num
 end try
end writeUTF8
'''


@lru_cache(maxsize=4096)
def _measure_text(value, font, size):
    # AppKit imports collide with Keynote's image/file terminology. Keep font
    # measurement in a separate process from the native document operation.
    script = '''use framework "Foundation"
use framework "AppKit"
use scripting additions
'''
    script += f'set f to current application\'s NSFont\'s fontWithName:{_q(font)} |size|:{_n(size)}\n'
    script += 'if f is missing value then error "Requested font is not installed"\n'
    script += 'set attrs to current application\'s NSDictionary\'s dictionaryWithObject:f forKey:(current application\'s NSFontAttributeName)\n'
    script += f'set txt to current application\'s NSString\'s stringWithString:{_q(value)}\n'
    script += "set dims to txt's sizeWithAttributes:attrs\nreturn (width of dims) as real"
    r = subprocess.run(['osascript','-e',script],capture_output=True,text=True,timeout=30)
    if r.returncode:
        raise KeynoteError(f'Cannot measure font {font}: {r.stderr.strip()}')
    return float(r.stdout.strip().replace(',','.'))


def _notes_script(slide_ref, markdown, directory, stem, theme):
    plain, ranges = parse_notes(markdown)
    path = _write(Path(directory) / f'{stem}.txt', plain)
    source = _read_expr(path) if plain else '""'
    code = [f'set presenter notes of {slide_ref} to {source}']
    if plain:
        code += [f'set font of presenter notes of {slide_ref} to {_q(theme.get("font_regular","HelveticaNeue"))}',
                 f'set size of presenter notes of {slide_ref} to 25']
        for lo, hi in ranges:
            code += [f'set font of characters {lo} thru {hi} of presenter notes of {slide_ref} to {_q(theme.get("font_bold","HelveticaNeue-Bold"))}']
        # Set native black LAST. Explicit off-white can turn black in dark editor UI.
        code += [f'set color of presenter notes of {slide_ref} to {{0,0,0}}']
    return code, plain


def _add_image(code, path, x, y, w, h, description=None, locked=False):
    # Keynote preserves image aspect ratio. Match the preview adapter's
    # contain/center behavior instead of distorting a figure into its slot.
    code += [f'tell s to set im to make new image with properties {{file:POSIX file {_q(path)}}}',
             'if im is missing value then error "Keynote could not import an image"',
             'set originalW to width of im', 'set originalH to height of im',
             f'set fitScale to {_n(w)} / originalW',
             f'if originalH * fitScale > {_n(h)} then set fitScale to {_n(h)} / originalH',
             'set width of im to originalW * fitScale',
             f'set position of im to {{{_n(x)} + ({_n(w)} - (width of im))/2, {_n(y)} + ({_n(h)} - (height of im))/2}}']
    if description is not None:
        code += [f'set description of im to {_q(description)}']
    if locked:
        code += ['set locked of im to true']


def _add_text(code, item, theme, directory, stem):
    text = str(item.get('text',''))
    if not text:
        return 0
    font = item.get('font', theme.get('font_regular','HelveticaNeue'))
    if item.get('bold') and font == theme.get('font_regular','HelveticaNeue'):
        font = theme.get('font_bold','HelveticaNeue-Bold')
    size = float(item.get('size',44))
    x,y,w = (float(item.get(k,0)) for k in ('x','y','w'))
    align = item.get('align','left')
    if align not in ('left','center','right'):
        raise ValueError(f'Unsupported alignment {align}')
    lines = text.split('\n')
    for index, line in enumerate(lines):
        if not line:
            continue
        p = _write(Path(directory) / f'{stem}-{index}.txt',line)
        code += [f'set txText to {_read_expr(p)}']
        # Check left-aligned lines too: Keynote can silently wrap them and grow
        # a text box over the next object, invalidating the manifest's geometry.
        measured = _measure_text(line,font,size)+12
        if measured > w+1:
            raise ValueError(f'Text needs an explicit line break or wider box: {line!r} ({measured:.0f}pt > {w:.0f}pt)')
        if align != 'left':
            # Native text boxes have 5pt insets. Position each native line using
            # AppKit font metrics instead of rasterizing centered titles.
            code += [f'set measuredW to {_n(measured)}']
            if align == 'center':
                code += [f'set txX to {_n(x)} + ({_n(w)} - measuredW) / 2']
            else:
                code += [f'set txX to {_n(x+w)} - measuredW']
            width = 'measuredW'
        else:
            code += [f'set txX to {_n(x)}']
            width = _n(w)
        code += ['tell s to set tx to make new text item with properties {object text:txText}',
                 f'set font of object text of tx to {_q(font)}',
                 f'set size of object text of tx to {_n(size)}',
                 f'set color of object text of tx to {_rgb(item.get("color",theme.get("foreground","#F6F6F4")))}',
                 f'set width of tx to {width}',
                 f'set position of tx to {{txX,{_n(y+index*size*1.22)}}}']
    return sum(bool(x) for x in lines)


def _inspection_code(directory):
    """Inspect only the document explicitly bound to d; never front document."""
    return [
        'set reportLines to {(id of d) as text}',
        'repeat with i from 1 to count slides of d',
        ' set s to slide i of d',
        ' set markerList to {}',
        ' repeat with im in images of s',
        f'  if description of im starts with {_q(MARKER)} then set end of markerList to description of im',
        ' end repeat',
        ' if (count markerList) is not 1 then error "Missing or duplicate slide-studio ID marker on slide " & i',
        ' set mark to item 1 of markerList',
        ' set n to (presenter notes of s) as text',
        f' my writeUTF8(n, {_q(str(directory)+os.sep)} & i & ".txt")',
        ' set ns to "empty"',
        ' if n is not "" then set ns to (size of character 1 of presenter notes of s) as text',
        ' set end of reportLines to mark & tab & i & tab & (count text items of s) & tab & (count movies of s) & tab & ns',
        'end repeat',
        'set oldDelim to AppleScript\'s text item delimiters',
        'set AppleScript\'s text item delimiters to linefeed',
        'set reportText to reportLines as text',
        'set AppleScript\'s text item delimiters to oldDelim',
        f'my writeUTF8(reportText, {_q(Path(directory)/"inspection.tsv")})',
    ]


def _read_inspection(directory):
    lines = (Path(directory)/'inspection.tsv').read_text().splitlines()
    slides = {}
    for line in lines[1:]:
        marker,index,texts,movies,size = line.split('\t')
        stable_id = marker.removeprefix(MARKER)
        if stable_id in slides:
            raise KeynoteError(f'Duplicate stable slide ID {stable_id}')
        slides[stable_id] = {'index':int(index),'native_text_count':int(texts),
            'native_movie_count':int(movies),'notes_size':size,
            'notes':(Path(directory)/f'{index}.txt').read_text()}
    return {'document_id':lines[0], 'slides':slides}


def _closed_document_guard(path):
    """Used before replacing a file; a copied file must never overwrite an open doc."""
    return [
        'repeat with existingDoc in documents',
        ' try',
        '  set existingPath to POSIX path of (file of existingDoc)',
        f'  if existingPath is {_q(path)} then error "Target is open in Keynote; close that generated deck before rebuilding it." number -2700',
        ' on error msg number num',
        '  if num is -2700 then error msg number num',
        ' end try',
        'end repeat',
    ]


def assemble(project_dir, output_path, slide_manifests, theme, overwrite=False):
    """Create a new .key deck, verify notes, then atomically publish its file.

    output_path must be inside project_dir. Existing files require overwrite=True;
    an open target is rejected. All native work happens in a new owned document.
    Save/report assets live under build/keynote/ and are disposable.
    """
    if platform.system() != "Darwin":
        raise KeynoteError("Native Keynote assembly requires macOS and Keynote.")
    project = Path(project_dir).expanduser().resolve()
    output = _within(output_path,project)
    if output.suffix != '.key':
        raise ValueError('Keynote output must have .key extension')
    if output.exists() and not overwrite:
        raise FileExistsError(f'{output} exists; use overwrite=True deliberately.')
    slides = list(slide_manifests)
    if not slides:
        raise ValueError('A deck needs at least one slide')
    ids = [s['id'] for s in slides]
    if len(set(ids)) != len(ids) or any(not ID_RE.fullmatch(s) for s in ids):
        raise ValueError('Slide IDs must be unique portable identifiers: letters, digits, dot, dash, underscore.')
    width,height = int(slides[0].get('width',1920)),int(slides[0].get('height',1080))
    if any(int(s.get('width',width))!=width or int(s.get('height',height))!=height for s in slides):
        raise ValueError('All slides need the same canvas size')
    work = project/'build'/'keynote'/('assemble-'+uuid.uuid4().hex[:12])
    work.mkdir(parents=True)
    staged = work/'candidate.key'
    verify_dir = work/'verify'
    verify_dir.mkdir()
    code = [AS_HEADER,'tell application "Keynote"'] + _closed_document_guard(output)
    code += [f'set d to make new document with properties {{document theme:theme "Black", width:{width}, height:{height}}}',
             'set auto play of d to false','set slide numbers showing of d to false',
             'set createdID to id of d','try']
    expected = {}; editable = 0; movies = 0; warnings = []
    for index,slide in enumerate(slides,1):
        stable_id = slide['id']
        code += ['set s to slide 1 of d' if index==1 else 'set s to make new slide at end of slides of d',
                 'set base layout of s to slide layout "Blank" of d',
                 'set title showing of s to false','set body showing of s to false',
                 'set transition properties of s to {automatic transition:false}']
        backdrop = work/f'{stable_id}-background.png'
        primitives.solid(backdrop,slide.get('background',theme.get('background','#2B2B2D')),width,height)
        _add_image(code,backdrop,0,0,width,height,MARKER+stable_id,True)
        movie = slide.get('movie')
        if movie:
            media = Path(movie['path']).expanduser().resolve()
            if not media.is_file():
                raise FileNotFoundError(media)
            code += [# Keynote's media importer uses the image constructor and returns a
                     # native movie object for an MP4/MOV. The movie constructor
                     # rejects file and silently ignores file name on current macOS.
                     f'tell s to set mv to make new image with properties {{file:POSIX file {_q(media)}}}',
                     'if class of mv is not movie then error "Media did not import as a native movie"',
                     f'set width of mv to {_n(movie.get("w",width))}',
                     f'set height of mv to {_n(movie.get("h",height))}',
                     f'set position of mv to {{{_n(movie.get("x",0))},{_n(movie.get("y",0))}}}',
                     'set movie volume of mv to 0']
            movies += 1
            if movie.get('autoplay'):
                warnings.append(f'{stable_id}: movie is embedded; deselect “Start movie on click” in Keynote Format → Movie, then test in Play mode. Slide advance stays manual.')
        for j,item in enumerate(slide.get('items',[])):
            if item['type']=='text':
                editable += _add_text(code,item,theme,work,f'{stable_id}-text-{j}')
            elif item['type']=='image':
                image = Path(item['path']).expanduser().resolve()
                if not image.is_file():
                    raise FileNotFoundError(image)
                if item.get('mask') == 'circle':
                    masked = work/f'{stable_id}-circle-{j}.png'
                    helper = Path(__file__).parent/'keynote_helpers'/'circle_mask.swift'
                    r = subprocess.run(['swift',str(helper),str(image),str(masked),
                                        str(max(1,round(max(item['w'],item['h'])*2))),
                                        str(item.get('focal_x',.5)),str(item.get('focal_y',.4)),
                                        str(item.get('zoom',1))],capture_output=True,text=True,timeout=90)
                    if r.returncode:
                        raise KeynoteError(f'Circle crop failed: {r.stderr.strip()}')
                    image = masked
                elif item.get('mask'):
                    raise ValueError('Supported image mask: circle')
                _add_image(code,image,*(item[k] for k in ('x','y','w','h')))
            elif item['type'] in ('rect','ellipse','line'):
                p = primitives.render(work/f'{stable_id}-primitive-{j}.png',item)
                _add_image(code,p['path'],*(p[k] for k in ('x','y','w','h')))
            else:
                raise ValueError(f'Unsupported item type {item["type"]!r}')
        notes,plain = _notes_script('s',slide.get('notes',''),work,f'{stable_id}-notes',theme)
        code += notes
        expected[stable_id] = plain
    code += [f'save d in POSIX file {_q(staged)}']
    code += _inspection_code(verify_dir)
    code += ['close d saving yes','on error errText number errNum',
             ' try','  close d saving no',' end try',
             ' error errText number errNum','end try','end tell']
    _run('\n'.join(code),work,timeout=max(240,len(slides)*12))
    inspected = _read_inspection(verify_dir)
    if set(inspected['slides'])!=set(expected):
        raise KeynoteError('Created slides do not match stable IDs; candidate retained.')
    for stable_id,plain in expected.items():
        row = inspected['slides'][stable_id]
        if row['notes'] != plain or (plain and float(row['notes_size'])!=25):
            raise KeynoteError(f'Notes verification failed on {stable_id}; candidate retained.')
    output.parent.mkdir(parents=True,exist_ok=True)
    # Keynote normally writes a ZIP, but package documents are supported too.
    if output.exists():
        backup = work/('previous-'+output.name)
        shutil.move(str(output),str(backup))
    shutil.move(str(staged),str(output))
    binding = {'schema_version':1,'output':str(output.relative_to(project)),
               'document_id':inspected['document_id'],'theme':theme,
               'slides':inspected['slides']}
    binding_path = output.with_suffix('.bindings.json')
    _json(binding_path,binding)
    report = {'output':str(output),'binding':str(binding_path),'slides':len(slides),
              'editable_text_objects':editable,'movie_objects':movies,
              'notes_verified':True,'slide_advance':'manual','warnings':warnings,
              'capabilities':capabilities()}
    _json(work/'report.json',report)
    return report


def _open_owned(output, code):
    # Work only with an exact path, never the frontmost/current document.
    code += ['set d to missing value','set openedHere to false',
             'repeat with candidate in documents',' try',
             f'  if POSIX path of (file of candidate) is {_q(output)} then set d to candidate',
             ' end try','end repeat','if d is missing value then',
             f' set d to open POSIX file {_q(output)}',' set openedHere to true','end if',
             'if d is missing value then error "Keynote did not return the requested generated document; it may be open as another copy."']


def update_notes(project_dir, output_path, updates, expected_old=None):
    """Update only notes by stable ID, preserving all visual objects.

    updates maps slide ID -> Markdown notes. expected_old optionally supplies
    exact expected plain text (or **markup**) for conflicts manually resolved by
    the caller. By default use last generated notes in the sibling bindings file.
    Preflight checks every targeted slide before any edit. Reordered slides work;
    duplicate/deleted markers or manual notes changes fail closed.
    """
    project = Path(project_dir).expanduser().resolve()
    output = _within(output_path,project)
    binding_path = output.with_suffix('.bindings.json')
    binding = json.loads(binding_path.read_text())
    if binding['output']!=str(output.relative_to(project)):
        raise KeynoteError('Binding file belongs to another deck')
    if not updates:
        return {'updated':0,'output':str(output),'conflicts':[]}
    for stable_id in updates:
        if stable_id not in binding['slides']:
            raise NotesConflict(f'Unbound slide ID: {stable_id}')
    work = project/'build'/'keynote'/('notes-'+uuid.uuid4().hex[:12])
    work.mkdir(parents=True)
    before = work/'before'; before.mkdir()
    code = [AS_HEADER,'tell application "Keynote"']
    _open_owned(output,code)
    code += _inspection_code(before)
    code += ['if openedHere then close d saving no','end tell']
    _run('\n'.join(code),work)
    inspected = _read_inspection(before)
    expected_old = expected_old or {}
    conflicts=[]
    for stable_id,markdown in updates.items():
        if stable_id not in inspected['slides']:
            conflicts.append(stable_id+': stable marker missing')
            continue
        expected = parse_notes(expected_old[stable_id])[0] if stable_id in expected_old else binding['slides'][stable_id]['notes']
        if inspected['slides'][stable_id]['notes'] != expected:
            conflicts.append(stable_id+': notes have been edited since the recorded baseline')
        parse_notes(markdown)
    if conflicts:
        raise NotesConflict('No notes changed. '+ '; '.join(conflicts))
    after=work/'after'; after.mkdir()
    code=[AS_HEADER,'tell application "Keynote"']; _open_owned(output,code)
    # Repeat all guards inside the single native mutation, closing the TOCTOU gap.
    for stable_id in updates:
        index=inspected['slides'][stable_id]['index']
        old_path=_write(work/f'expected-{stable_id}.txt',inspected['slides'][stable_id]['notes'])
        old_expr=_read_expr(old_path) if old_path.stat().st_size else '""'
        code += [f'set s to slide {index} of d',
                 'set foundMarker to false',
                 'repeat with markerImage in images of s',
                 f' if description of markerImage is {_q(MARKER+stable_id)} then set foundMarker to true',
                 'end repeat',
                 'if not foundMarker then error "Slide order changed during update"',
                 f'if (presenter notes of s as text) is not {old_expr} then error "Notes changed during update; no further edits applied"']
    for stable_id,markdown in updates.items():
        index=inspected['slides'][stable_id]['index']
        code += [f'set s to slide {index} of d']
        note_code,_=_notes_script('s',markdown,work,'new-'+stable_id,binding['theme'])
        code += note_code
    code += ['save d'] + _inspection_code(after) + ['if openedHere then close d saving yes','end tell']
    _run('\n'.join(code),work)
    actual=_read_inspection(after)
    for stable_id,markdown in updates.items():
        plain,_=parse_notes(markdown)
        row=actual['slides'][stable_id]
        if row['notes']!=plain or (plain and float(row['notes_size'])!=25):
            raise KeynoteError(f'Native notes readback failed for {stable_id}')
        binding['slides'][stable_id]=row
    _json(binding_path,binding)
    return {'updated':len(updates),'output':str(output),'notes_verified':True,'conflicts':[]}


def export_preview(project_dir, output_path, destination=None):
    """Export PNGs for visual inspection. Does not modify notes or visual objects."""
    project=Path(project_dir).expanduser().resolve(); output=_within(output_path,project)
    if not output.with_suffix('.bindings.json').is_file():
        raise KeynoteError('Preview requires an owned generated deck and its bindings file')
    dest=_within(destination or project/'build'/'keynote'/'preview',project)
    if dest.exists():
        raise FileExistsError(f'Use a fresh preview directory: {dest}')
    dest.parent.mkdir(parents=True,exist_ok=True)
    work=project/'build'/'keynote'/('export-'+uuid.uuid4().hex[:12]); work.mkdir(parents=True)
    code=[AS_HEADER,'tell application "Keynote"']; _open_owned(output,code)
    code += [f'export d to POSIX file {_q(dest)} as slide images with properties {{image format:PNG, all stages:false, skipped slides:false}}',
             'if openedHere then close d saving no','end tell']
    _run('\n'.join(code),work,timeout=300)
    return {'directory':str(dest),'images':[str(p) for p in sorted(dest.glob('*.png'))]}
