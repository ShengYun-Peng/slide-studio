"""Small, dependency-free raster primitives; native text is never rasterized.

PNG panels avoid unsupported Keynote AppleScript fill/stroke properties. Their
source geometry remains in the slide manifest, so changing theme is repeatable.
"""
from __future__ import annotations
import math
from pathlib import Path
import struct
import zlib


def rgba(value: str | None, default=(0, 0, 0, 0)):
    if value is None or value == 'none':
        return default
    h = value.lstrip('#')
    if len(h) not in (6, 8):
        raise ValueError(f'Expected #RRGGBB or #RRGGBBAA, got {value!r}')
    return tuple(int(h[i:i+2], 16) for i in range(0, len(h), 2)) + (() if len(h) == 8 else (255,))


def png(path, width, height, rows):
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data) & 0xffffffff)
    raw = b''.join(b'\0' + row for row in rows)
    data = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('!2I5B', width, height, 8, 6, 0, 0, 0))
    data += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    Path(path).write_bytes(data)


def solid(path, color, width=16, height=9):
    """Use the canvas aspect ratio: Keynote image resizing preserves it."""
    divisor = math.gcd(int(width),int(height))
    width,height=int(width)//divisor,int(height)//divisor
    png(path, width, height, [bytes(rgba(color)) * width] * height)


def render(path, item, scale=2):
    """Render a panel, ellipse, or straight arrow; return placement including pad.

    x/y/w/h describe the panel, ellipse, or the start and signed vector of a line.
    Positive w with h=0 produces a horizontal arrow. Stroke is centered on lines
    and drawn inside panels. Rounded panels use corner_radius in slide points.
    """
    kind = item['type']
    x, y, w, h = (float(item.get(k, 0)) for k in ('x', 'y', 'w', 'h'))
    sw = max(0.0, float(item.get('stroke_width', 0)))
    fill = rgba(item.get('fill'))
    stroke = rgba(item.get('stroke'))
    arrow = kind == 'line' and item.get('arrow_end', False)
    head = max(16, sw * 3.2) if arrow else 0
    pad = math.ceil(max(sw, head) + 2) if kind == 'line' else 0
    ox, oy = min(0, w) - pad, min(0, h) - pad
    rw, rh = max(1, math.ceil(abs(w) + pad*2)), max(1, math.ceil(abs(h) + pad*2))
    pw, ph = rw * scale, rh * scale
    r = min(max(0, float(item.get('corner_radius', 0))), abs(w)/2, abs(h)/2)
    length = math.hypot(w, h)

    def inside_round(px, py, inset):
        if w <= inset*2 or h <= inset*2:
            return False
        radius = max(0, r - inset)
        cx = max(inset+radius, min(w-inset-radius, px))
        cy = max(inset+radius, min(h-inset-radius, py))
        return inset <= px <= w-inset and inset <= py <= h-inset and (px-cx)**2+(py-cy)**2 <= radius**2 + 1e-8

    rows = []
    for iy in range(ph):
        py = (iy+.5)/scale + oy
        row = bytearray()
        for ix in range(pw):
            px = (ix+.5)/scale + ox
            col = (0,0,0,0)
            if kind == 'rect':
                if inside_round(px,py,0):
                    col = stroke if sw and not inside_round(px,py,sw) else fill
            elif kind == 'ellipse':
                if w > 0 and h > 0 and ((px-w/2)/(w/2))**2+((py-h/2)/(h/2))**2 <= 1:
                    inner = w>2*sw and h>2*sw and ((px-w/2)/(w/2-sw))**2+((py-h/2)/(h/2-sw))**2 <= 1
                    col = stroke if sw and not inner else fill
            elif kind == 'line' and length:
                along, across = (px*w+py*h)/length, abs(-px*h+py*w)/length
                if 0 <= along <= length-(head*.5 if arrow else 0) and across <= max(1,sw)/2:
                    col = stroke
                if arrow and length-head <= along <= length and across <= (length-along)*.48:
                    col = stroke
            row.extend(col)
        rows.append(bytes(row))
    png(path,pw,ph,rows)
    return {'path':str(Path(path).resolve()), 'x':x+ox,'y':y+oy,'w':rw,'h':rh}
