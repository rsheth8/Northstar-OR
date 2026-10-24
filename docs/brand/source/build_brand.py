"""Build the final Northstar OR identity from editable vector geometry.

Run from the repo root: python3 docs/brand/source/build_brand.py
Exports use macOS AppKit/Swift and Pillow; no network access or font install.
The source/wordmark.svg contains the existing outlined Inter Display lettering.
"""

from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from PIL import Image

BRAND = Path(__file__).resolve().parent.parent
REPO = BRAND.parent.parent
NAVY, WHITE, GREEN, ICE, GOLD = "#0B1220", "#E8F1F8", "#3DDC97", "#7FC4E8", "#F9D98A"

# Full emblem: 512 × 448. Geometry has deliberate space between the five forms.
TREE = "M130 230 L158 276 H146 L174 320 H156 L188 366 H141 V398 H119 V366 H72 L104 320 H86 L114 276 H102Z"
LAND_CLINIC = (
    "M40 399 C105 370 150 401 215 390 C250 384 278 374 300 370 "
    "V309 H279 L355 251 L431 309 H410 V374 "
    "C437 380 457 389 472 399 C404 384 364 382 314 391 "
    "C244 407 196 418 127 409 C93 404 67 400 40 399Z"
)
# A true transparent cutout, not a background-colored patch.
PLUS = "M347 320 H363 V334 H377 V350 H363 V364 H347 V350 H333 V334 H347Z"
TAIL = "M112 211 C143 176 180 157 214 144 L218 154 C181 165 146 184 112 211Z"
PULSE = "M216 149 L226 158 L239 123 L252 166 L265 134"
# The wake broadens into the star, which overlaps its end: no detached line cap.
WAKE = "M263 129 C312 113 351 100 395 75 L407 89 C362 110 313 129 267 139Z"
STAR = (
    "M403 12 C410 64 416 73 457 82 C416 91 410 101 403 139 "
    "C396 101 389 91 349 82 C389 73 396 64 403 12Z"
)


def symbol(mono=None, compact=False):
    """One geometry for all colors; the compact mark keeps star and pulse only."""
    out = []
    if not compact:
        out += [
            f'<path id="evergreen" d="{TREE}" fill="{mono or GREEN}"/>',
            f'<path id="clinic-and-land" d="{LAND_CLINIC} {PLUS}" fill="{mono or WHITE}" fill-rule="evenodd"/>',
        ]
    out += [
        f'<path id="tapered-trail" d="{TAIL}" fill="{mono or ICE}"/>',
        f'<path id="medical-pulse" d="{PULSE}" fill="none" stroke="{mono or ICE}" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>',
        f'<path id="connected-wake" d="{WAKE}" fill="{mono or ICE}"/>',
        f'<path id="north-star" d="{STAR}" fill="{mono or GOLD}"/>',
    ]
    return "\n".join(out)


def placed(body, x, y, scale):
    return f'<g transform="translate({x} {y}) scale({scale})">{body}</g>'


def lettering(ink=WHITE, accent=GREEN):
    root = ET.parse(BRAND / "source/wordmark.svg").getroot()
    result = []
    for item in root:
        if not item.tag.endswith("path"):
            continue
        result.append(
            f'<path d="{item.attrib["d"]}" transform="{item.attrib["transform"]}" '
            f'fill="{ink if item.attrib["id"] == "northstar" else accent}"/>'
        )
    return "\n".join(result)


def svg(w, h, body, title="Northstar OR"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img">\n'
        f'<title>{title}</title>\n{body}\n</svg>\n'
    )


def horizontal(mono=None):
    return svg(900, 252,
               placed(symbol(mono), 0, 0, 0.5) +
               placed(lettering(mono or WHITE, mono or GREEN), 286, 90, 1.1045))


def stacked(mono=None):
    return svg(640, 600,
               placed(symbol(mono), 64, 18, 1) +
               placed(lettering(mono or WHITE, mono or GREEN), 30, 470, 580 / 536))


def usage_board(full):
    # Distinct layer names are useful in masters; this proof repeats the shapes.
    clean = lambda body: re.sub(r' id="[^"]+"', '', body)
    label = lambda x, y, text, color="#9BB0C4": (
        f'<text x="{x}" y="{y}" fill="{color}" font-family="Helvetica, sans-serif" font-size="18">{text}</text>'
    )
    icon = f'<rect width="1024" height="1024" fill="{NAVY}"/>' + placed(clean(full), 26, 90, 1.9)
    body = (
        f'<rect width="1400" height="1080" fill="{NAVY}"/>'
        '<rect y="744" width="1400" height="336" fill="#F4F7FB"/>'
        + label(64, 58, "NORTHSTAR OR  /  FINAL IDENTITY")
        + placed(clean(full), 90, 100, 1)
        + placed(lettering(), 64, 608, 1.1)
        + '<defs><clipPath id="app-mask"><rect x="860" y="118" width="300" height="300" rx="66"/></clipPath></defs>'
        + '<g clip-path="url(#app-mask)">' + placed(icon, 860, 118, 300 / 1024) + '</g>'
        + '<rect x="860" y="118" width="300" height="300" rx="66" fill="none" stroke="#24364E" stroke-width="1.5"/>'
        + label(860, 462, "App icon")
        + placed(icon, 860, 518, 58 / 1024)
        + placed(icon, 972, 536, 40 / 1024)
        + placed(clean(symbol(compact=True)), 1080 - 88 * .25, 520, .25)
        + label(860, 614, "58 px") + label(972, 614, "40 px") + label(1080, 614, "Compact mark")
        + label(64, 802, "SINGLE COLOR  /  LIGHT SURFACES", "#52647B")
        + placed(clean(symbol(NAVY)), 44, 838, .36)
        + placed(lettering(NAVY, NAVY), 258, 892, .8)
        + placed(clean(symbol(NAVY)), 940, 830, .38)
    )
    return svg(1400, 1080, body, "Northstar OR — final identity and size proof")


def main():
    full = symbol()
    files = {
        "mark-color-dark.svg": svg(512, 448, full),
        # The light-surface signature is deliberately a single navy silhouette.
        "mark-color-light.svg": svg(512, 448, symbol(NAVY)),
        "mark-white.svg": svg(512, 448, symbol("#FFFFFF")),
        "mark-navy.svg": svg(512, 448, symbol(NAVY)),
        "mark-compact.svg": svg(384, 224, placed(symbol(compact=True), -88, 0, 1)),
        "mark-compact-white.svg": svg(384, 224, placed(symbol("#FFFFFF", compact=True), -88, 0, 1)),
        "mark-compact-navy.svg": svg(384, 224, placed(symbol(NAVY, compact=True), -88, 0, 1)),
        "lockup-horizontal-dark.svg": horizontal(),
        "lockup-horizontal-light.svg": horizontal(NAVY),
        "lockup-horizontal-white.svg": horizontal("#FFFFFF"),
        "lockup-stacked-dark.svg": stacked(),
        "lockup-stacked-light.svg": stacked(NAVY),
        "NorthstarOR-AppIcon-1024.svg": svg(1024, 1024,
            f'<rect width="1024" height="1024" fill="{NAVY}"/>' + placed(full, 26, 90, 1.9)),
        "NorthstarOR-final.svg": svg(1280, 1000,
            f'<rect width="1280" height="1000" fill="{NAVY}"/>' +
            placed(full, 307.2, 98, 1.3) +
            placed(lettering(), 238, 720, 1.5)),
        "NorthstarOR-logo-board.svg": usage_board(full),
    }
    for name, contents in files.items():
        (BRAND / name).write_text(contents)

    assets = REPO / "NorthstarOR/Resources/Assets.xcassets"
    exports = [
        ("NorthstarOR-final.svg", BRAND / "NorthstarOR-final.png", 1280, 1000, False),
        ("NorthstarOR-logo-board.svg", BRAND / "NorthstarOR-logo-board.png", 1400, 1080, False),
        ("NorthstarOR-AppIcon-1024.svg", BRAND / "NorthstarOR-AppIcon-1024.png", 1024, 1024, True),
        ("lockup-horizontal-dark.svg", BRAND / "lockup-horizontal-dark@2x.png", 1800, 504, False),
        ("lockup-horizontal-light.svg", BRAND / "lockup-horizontal-light@2x.png", 1800, 504, False),
        ("mark-color-dark.svg", BRAND / "mark-color-dark.png", 1024, 896, False),
        ("mark-white.svg", BRAND / "mark-white.png", 1024, 896, False),
        ("mark-navy.svg", BRAND / "mark-navy.png", 1024, 896, False),
        ("NorthstarOR-AppIcon-1024.svg", assets / "AppIcon.appiconset/AppIcon-1024.png", 1024, 1024, True),
        # A compact star/pulse has room to remain clear in the 28 pt header.
        ("mark-compact.svg", assets / "BrandMark.imageset/mark-compact@3x.png", 576, 336, False),
    ]
    with tempfile.TemporaryDirectory(prefix="northstar-brand-") as tmp:
        renderer = Path(tmp) / "render"
        subprocess.run(["swiftc", str(BRAND / "source/render.swift"), "-o", str(renderer)], check=True)
        for source, target, w, h, opaque in exports:
            subprocess.run([str(renderer), str(BRAND / source), str(target), str(w), str(h)], check=True)
            if opaque:
                with Image.open(target) as img:
                    img.convert("RGB").save(target)
            print(f"Exported {target.relative_to(REPO)} ({w} × {h})")


if __name__ == "__main__":
    main()
