"""Replace native Keynote movies in a new review copy, never the source deck.

Run `python3 -m runtime.keynote_media --help`. Plan mode is portable and read-only.
Apply requires macOS, English Keynote's Movie inspector, and Automation/accessibility
access. The adapter is deliberately separate from the portable rendering pipeline.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import time
import uuid
import zipfile

from .keynote import KeynoteError, _q

SCRIPT = Path(__file__).with_suffix('.applescript')
VIDEO_SUFFIXES = {'.mp4', '.mov', '.m4v'}


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def deck_fingerprint(path):
    path = Path(path)
    if path.is_file():
        return sha256(path)
    return {str(p.relative_to(path)): sha256(p) for p in sorted(path.rglob('*')) if p.is_file()}


def stamp(seconds):
    milliseconds = round(float(seconds) * 1000)
    hours, rest = divmod(milliseconds, 3600000)
    minutes, rest = divmod(rest, 60000)
    secs, ms = divmod(rest, 1000)
    return f'{hours:02}:{minutes:02}:{secs:02}.{ms:03}'


def normalize_replacements(rows, base):
    if not isinstance(rows, list) or not rows:
        raise ValueError('Supply a nonempty list of replacements')
    result, seen = [], set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('Each replacement must be an object')
        slide = row.get('slide')
        if isinstance(slide, bool) or not isinstance(slide, int) or slide < 1 or slide in seen:
            raise ValueError('Slide numbers must be unique positive integers')
        seen.add(slide)
        raw = row.get('movie')
        if not isinstance(raw, str) or not raw or any(c in raw for c in '\n\r\t'):
            raise ValueError('Movie path must be a nonempty path without control characters')
        movie = (Path(base) / Path(raw).expanduser()).resolve()
        if not movie.is_file() or movie.suffix.lower() not in VIDEO_SUFFIXES:
            raise ValueError(f'Movie must be an existing MP4/MOV/M4V: {movie}')
        duration, poster = row.get('duration'), row.get('poster', 0)
        for name, value in [('duration', duration), ('poster', poster)]:
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
                raise ValueError(f'{name} must be a finite number of seconds')
        if duration <= 0 or not 0 <= poster < duration:
            raise ValueError('Require duration > 0 and 0 <= poster < duration')
        result.append({'slide': slide, 'movie': str(movie), 'duration': float(duration),
                       'poster': float(poster), 'sha256': sha256(movie)})
    return result


def prepare_copy(source, output):
    """Create only a new path and verify its bytes before any native operation."""
    source, output = Path(source).resolve(), Path(output).resolve()
    if source == output or output.exists():
        raise FileExistsError('Output must be a new review-copy path; source replacement is not supported')
    if source.is_dir() and output.is_relative_to(source):
        raise ValueError('A review copy cannot be placed inside the source Keynote package')
    if source.suffix.lower() != '.key' or output.suffix.lower() != '.key' or not source.exists():
        raise ValueError('Source and output must be .key documents')
    before = deck_fingerprint(source)
    output.parent.mkdir(parents=True, exist_ok=True)
    if source.is_dir():
        shutil.copytree(source, output)
    else:
        # Exclusive creation also prevents overwriting a path created after preflight.
        with source.open('rb') as src, output.open('xb') as dst:
            shutil.copyfileobj(src, dst)
    if deck_fingerprint(source) != before or deck_fingerprint(output) != before:
        raise KeynoteError('Source changed during copying; review copy retained, no native edits made')
    return before


def embedded_match(deck, movie):
    """Exact-byte proof; supports both zipped and package-format .key files."""
    deck, movie = Path(deck), Path(movie)
    expected, size = sha256(movie), movie.stat().st_size
    if deck.is_dir():
        for p in (deck / 'Data').rglob('*'):
            if p.is_file() and p.suffix.lower() in VIDEO_SUFFIXES and p.stat().st_size == size and sha256(p) == expected:
                return {'entry': str(p.relative_to(deck)), 'sha256': expected, 'bytes': size}
    else:
        with zipfile.ZipFile(deck) as z:
            for info in z.infolist():
                if info.filename.startswith('Data/') and Path(info.filename).suffix.lower() in VIDEO_SUFFIXES and info.file_size == size:
                    with z.open(info) as f:
                        h = hashlib.sha256()
                        for block in iter(lambda: f.read(1024 * 1024), b''):
                            h.update(block)
                    if h.hexdigest() == expected:
                        return {'entry': info.filename, 'sha256': expected, 'bytes': size}
    return None


def run_osa(script=None, *, language='AppleScript', args=(), timeout=35):
    command = ['osascript', '-l', language]
    if script is not None:
        command += ['-e', script, '--']
    else:
        command += [str(SCRIPT)]
    try:
        p = subprocess.run(command + [str(a) for a in args], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        raise KeynoteError('Keynote operation timed out. Inspect the review copy and any modal dialog; no restart or automatic retry was attempted.') from exc
    if p.returncode:
        raise KeynoteError(p.stderr.strip() or 'Keynote operation failed')
    return p.stdout.strip()


def probe_movie(path):
    """Inspect actual media metadata, independent of the supplied timing manifest."""
    code = '''import Foundation
import AVFoundation
let a=AVURLAsset(url:URL(fileURLWithPath:CommandLine.arguments[1]))
guard let t=a.tracks(withMediaType:.video).first else {fatalError("No video track")}
let r:[String:Any] = ["duration":a.duration.seconds,"width":t.naturalSize.width,"height":t.naturalSize.height,"fps":t.nominalFrameRate]
print(String(data:try JSONSerialization.data(withJSONObject:r),encoding:.utf8)!)
'''
    with tempfile.TemporaryDirectory(prefix='slide-studio-media-probe-') as temp:
        source = Path(temp) / 'probe.swift'
        source.write_text(code)
        p = subprocess.run(['swift', str(source), str(path)], capture_output=True, text=True, timeout=60)
    if p.returncode:
        raise KeynoteError('Cannot inspect movie metadata: ' + p.stderr.strip())
    return json.loads(p.stdout)


OPEN_DOCUMENTS = '''function run() {
 const k=Application('Keynote'); if (!k.running()) return '[]';
 return JSON.stringify(k.documents().map(d=>{let path=null;try{const f=d.file();if(f)path=String(f);}catch(e){}return {name:d.name(),path:path,modified:d.modified()};}));
}'''
SNAPSHOT = '''function run(argv) {
 const k=Application('Keynote'), d=k.documents.byId(argv[0]);
 const items=(s,type)=>s[type]();
 const slides=d.slides().map((s,index)=>({number:index+1,
 notes:String(s.presenterNotes()),notesStyle:{font:s.presenterNotes.font(),size:s.presenterNotes.size(),color:s.presenterNotes.color()},
 transition:s.transitionProperties(),
 text:items(s,'textItems').map(t=>({properties:t.properties(),style:{font:t.objectText.font(),size:t.objectText.size(),color:t.objectText.color()}})),
 shapes:items(s,'shapes').map(t=>({properties:t.properties(),text:String(t.objectText())})),
 // Keynote 14.4 can reject image.properties() despite individual getters working.
 images:items(s,'images').map(t=>({fileName:t.fileName(),position:t.position(),width:t.width(),height:t.height(),
 opacity:t.opacity(),rotation:t.rotation(),locked:t.locked(),reflectionShowing:t.reflectionShowing(),reflectionValue:t.reflectionValue()})),
 movies:items(s,'movies').map(t=>{const p=t.properties();delete p.fileName;return p;})}));
 return JSON.stringify({width:d.width(),height:d.height(),slides:slides});
}'''


def apply_replacements(source, output, rows):
    if platform.system() != 'Darwin':
        raise KeynoteError('--apply requires macOS and Keynote; omit it to inspect the plan')
    if not shutil.which('osascript') or not shutil.which('swift'):
        raise KeynoteError('Native replacement requires osascript and Swift')
    source, output = Path(source).resolve(), Path(output).resolve()
    documents = json.loads(run_osa(OPEN_DOCUMENTS, language='JavaScript'))
    if any(d['path'] and Path(d['path']).resolve() == source and d['modified'] for d in documents):
        raise KeynoteError('The source has unsaved native edits. Save them before copying; no changes made.')
    if any(d['name'] == output.name for d in documents):
        raise KeynoteError('Another open document has the output window name. Choose a unique review-copy filename.')
    for suffix in ('.media-review.json', '.native-before.json', '.native-after.json'):
        if output.with_suffix(suffix).exists():
            raise FileExistsError('Review sidecar already exists; choose a new output basename')
    probes = {}
    for row in rows:
        probe = probe_movie(row['movie'])
        if not math.isfinite(probe['duration']) or abs(probe['duration'] - row['duration']) > .05:
            raise ValueError(f"Slide {row['slide']}: supplied duration differs from the actual movie")
        if sha256(row['movie']) != row['sha256']:
            raise KeynoteError('Movie changed after planning; rerun with the final encoded source')
        probes[row['slide']] = probe
    source_before = prepare_copy(source, output)
    report_path = output.with_suffix('.media-review.json')
    report = {'source': str(source), 'review_copy': str(output), 'source_before': source_before,
              'status': 'incomplete', 'replacements': []}
    def record():
        report_path.write_text(json.dumps(report, indent=2) + '\n')
    record()
    try:
        doc_id = run_osa(f'''tell application "Keynote"
set d to open POSIX file {_q(output)}
set nativeFile to file of d
set nativePath to POSIX path of nativeFile
if nativePath is not {_q(output)} then error "Wrong native document"
return id of d
end tell''')
        before = json.loads(run_osa(SNAPSHOT, language='JavaScript', args=[doc_id]))
        output.with_suffix('.native-before.json').write_text(json.dumps(before, indent=2) + '\n')
        for row in rows:
            n = row['slide']
            if n > len(before['slides']) or len(before['slides'][n-1]['movies']) != 1:
                raise ValueError(f'Slide {n}: expected exactly one existing movie; no deletion/recreation is attempted')
            if before['slides'][n-1]['transition'].get('automaticTransition'):
                raise ValueError(f'Slide {n}: automatic slide advance must be resolved before using this manual-advance recipe')
        for row in rows:
            if sha256(row['movie']) != row['sha256']:
                raise KeynoteError('Movie changed during replacement; stop and inspect the review copy')
            flags = run_osa(args=[output, row['slide'], row['movie'], stamp(row['duration']),
                                  stamp(row['poster']), row['poster']/row['duration']], timeout=65)
            proof = None
            for _ in range(100):
                try:
                    proof = embedded_match(output, row['movie'])
                except (zipfile.BadZipFile, FileNotFoundError):
                    pass
                if proof:
                    break
                time.sleep(.2)
            if not proof:
                raise KeynoteError('Saved review copy does not contain the exact encoded movie bytes')
            report['replacements'].append({**row, 'metadata': probes[row['slide']], 'native_flags': flags, 'embedded': proof})
            record()
        after = json.loads(run_osa(SNAPSHOT, language='JavaScript', args=[doc_id]))
        output.with_suffix('.native-after.json').write_text(json.dumps(after, indent=2) + '\n')
        if before != after:
            raise KeynoteError('Native text, notes, geometry, style or transitions changed; inspect snapshots before publishing')
        if deck_fingerprint(source) != source_before:
            raise KeynoteError('Source changed while the review copy was being edited. Keep the new source; reconcile before delivery.')
        run_osa(f'''tell application "Keynote"
set d to document id {_q(doc_id)}
set nativeFile to file of d
set nativePath to POSIX path of nativeFile
if nativePath is not {_q(output)} then error "Wrong document on close"
if modified of d then error "Review copy still has unsaved changes"
close d saving no
end tell''')
        report.update(status='verified-review-copy', native_content_unchanged=True,
                      source_unchanged=True, closed_after_save=True,
                      remaining_review=['Inspect native posters and layered slide previews',
                                        'Play through beyond movie duration to verify pacing and manual advance'])
        record()
        return report
    except Exception as exc:
        report.update(status='needs-review', error=str(exc))
        record()
        raise


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--deck', required=True, type=Path, help='Latest saved source .key; never overwritten')
    p.add_argument('--output', type=Path, help='New review .key path; existing paths are refused')
    p.add_argument('--map', type=Path, help='JSON list of {slide,movie,duration,poster}; movie paths relative to JSON')
    p.add_argument('--slide', type=int)
    p.add_argument('--movie', type=Path)
    p.add_argument('--duration', type=float, help='Full encoded duration in seconds')
    p.add_argument('--poster', type=float, default=0, help='Poster time in seconds, default 0')
    p.add_argument('--apply', action='store_true', help='Create and edit a review copy; default only prints a plan')
    a = p.parse_args(argv)
    try:
        source = a.deck.expanduser().resolve()
        if not source.exists() or source.suffix.lower() != '.key':
            raise ValueError('Supply an existing .key document')
        if any(c in str(source) for c in '\n\r\t'):
            raise ValueError('Deck paths with control characters are not supported')
        if a.map:
            if any(v is not None for v in (a.slide, a.movie, a.duration)):
                raise ValueError('Use either --map or the single-movie options')
            rows = normalize_replacements(json.loads(a.map.read_text()), a.map.resolve().parent)
        else:
            rows = normalize_replacements([{'slide': a.slide, 'movie': str(a.movie) if a.movie else None,
                                            'duration': a.duration, 'poster': a.poster}], Path.cwd())
        output = (a.output.expanduser().resolve() if a.output else
                  source.with_name(f'{source.stem}-media-review-{uuid.uuid4().hex[:8]}.key'))
        if output == source or output.exists() or output.suffix.lower() != '.key':
            raise ValueError('Choose a new .key output path distinct from the source')
        if any(c in str(output) for c in '\n\r\t'):
            raise ValueError('Output paths with control characters are not supported')
        if a.apply:
            report = apply_replacements(source, output, rows)
        else:
            report = {'mode': 'plan-only', 'source': str(source), 'review_copy': str(output), 'replacements': rows,
                      'next': 'Inspect this mapping, then add --apply; the source deck is never overwritten.'}
        print(json.dumps(report, indent=2))
    except (ValueError, OSError, KeynoteError, subprocess.TimeoutExpired) as exc:
        p.exit(1, f'{exc}\n')


if __name__ == '__main__':
    main()
