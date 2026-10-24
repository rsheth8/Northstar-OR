"""Export Northstar OR's institutional identity. Run from the repository root.

Requires macOS Swift/AppKit and Pillow. Wordmark lettering is already outlined.
"""
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from PIL import Image

BRAND = Path(__file__).resolve().parent.parent
REPO = BRAND.parent.parent
NAVY, WHITE, MUTED, ICE = "#0B1220", "#E8F1F8", "#9BB0C4", "#7FC4E8"

# The tapered trail, pulse, and North Star overlap to form one silhouette.
TAIL = "M112 211 C143 176 180 157 214 144 L218 154 C181 165 146 184 112 211Z"
PULSE = "M216 149 L226 158 L239 123 L252 166 L265 134"
WAKE = "M263 129 C312 113 351 100 395 75 L407 89 C362 110 313 129 267 139Z"
STAR = "M403 12 C410 64 416 73 457 82 C416 91 410 101 403 139 C396 101 389 91 349 82 C389 73 396 64 403 12Z"


def placed(body, x, y, scale):
    return f'<g transform="translate({x} {y}) scale({scale})">{body}</g>'


def symbol(color=ICE):
    body = (
        f'<path id="tapered-trail" d="{TAIL}" fill="{color}"/>'
        f'<path id="medical-pulse" d="{PULSE}" fill="none" stroke="{color}" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>'
        f'<path id="connected-wake" d="{WAKE}" fill="{color}"/>'
        f'<path id="north-star" d="{STAR}" fill="{color}"/>'
    )
    return placed(body, -88, 0, 1)


def lettering(ink=WHITE, suffix=MUTED):
    root = ET.parse(BRAND / "source/wordmark.svg").getroot()
    return "\n".join(
        f'<path d="{p.attrib["d"]}" transform="{p.attrib["transform"]}" '
        f'fill="{ink if p.attrib["id"] == "northstar" else suffix}"/>'
        for p in root if p.tag.endswith("path")
    )


def svg(w, h, body, title="Northstar OR"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img">\n'
        f'<title>{title}</title>\n{body}\n</svg>\n'
    )


def horizontal(mono=None):
    return svg(900, 220, placed(symbol(mono or ICE), 0, 20, .625)
               + placed(lettering(mono or WHITE, mono or MUTED), 280, 67, 1.1045))


def stacked(mono=None):
    return svg(640, 420, placed(symbol(mono or ICE), 90, 20, 1.2)
               + placed(lettering(mono or WHITE, mono or MUTED), 30, 320, 580 / 536))


def app_icon():
    return f'<rect width="1024" height="1024" fill="{NAVY}"/>' + placed(symbol(), 56, 230, 2.375)


def board():
    clean = lambda body: re.sub(r' id="[^"]+"', '', body)
    label = lambda x, y, text, color=MUTED: (
        f'<text x="{x}" y="{y}" fill="{color}" font-family="Helvetica, sans-serif" font-size="16">{text}</text>'
    )
    icon = clean(app_icon())
    body = (
        f'<rect width="1400" height="960" fill="{NAVY}"/>'
        '<rect y="624" width="1400" height="336" fill="#F4F7FB"/>'
        + label(64, 60, "NORTHSTAR OR  /  INSTITUTIONAL IDENTITY")
        + placed(clean(symbol()), 64, 224, .625)
        + placed(lettering(), 344, 271, 1.1045)
        + '<defs><clipPath id="mask"><rect x="1060" y="166" width="240" height="240" rx="54"/></clipPath></defs>'
        + '<g clip-path="url(#mask)">' + placed(icon, 1060, 166, 240 / 1024) + '</g>'
        + '<rect x="1060" y="166" width="240" height="240" rx="54" fill="none" stroke="#283547"/>'
        + label(1060, 448, "App icon")
        + placed(icon, 1060, 500, 58 / 1024)
        + placed(icon, 1160, 518, 40 / 1024)
        + label(1060, 590, "58 px") + label(1160, 590, "40 px")
        + label(64, 684, "SINGLE COLOR  /  LIGHT SURFACES", "#52647B")
        + placed(clean(symbol(NAVY)), 64, 732, .625)
        + placed(lettering(NAVY, NAVY), 344, 779, 1.1045)
        + placed(clean(symbol(NAVY)), 1070, 754, .5)
    )
    return svg(1400, 960, body, "Northstar OR — institutional identity and size proofs")


def main():
    files = {
        "mark-color-dark.svg": svg(384, 224, symbol()),
        "mark-color-light.svg": svg(384, 224, symbol(NAVY)),
        "mark-white.svg": svg(384, 224, symbol("#FFFFFF")),
        "mark-navy.svg": svg(384, 224, symbol(NAVY)),
        "mark-compact.svg": svg(384, 224, symbol()),
        "mark-compact-white.svg": svg(384, 224, symbol("#FFFFFF")),
        "mark-compact-navy.svg": svg(384, 224, symbol(NAVY)),
        "lockup-horizontal-dark.svg": horizontal(),
        "lockup-horizontal-light.svg": horizontal(NAVY),
        "lockup-horizontal-white.svg": horizontal("#FFFFFF"),
        "lockup-stacked-dark.svg": stacked(),
        "lockup-stacked-light.svg": stacked(NAVY),
        "NorthstarOR-AppIcon-1024.svg": svg(1024, 1024, app_icon()),
        "NorthstarOR-final.svg": svg(1280, 700,
            f'<rect width="1280" height="700" fill="{NAVY}"/>'
            + placed(symbol(), 138, 240, .8) + placed(lettering(), 494, 281, 1.2)),
        "NorthstarOR-logo-board.svg": board(),
    }
    for name, body in files.items():
        (BRAND / name).write_text(body)
    assets = REPO / "NorthstarOR/Resources/Assets.xcassets"
    exports = [
        ("NorthstarOR-final.svg", BRAND / "NorthstarOR-final.png", 1280, 700, False),
        ("NorthstarOR-logo-board.svg", BRAND / "NorthstarOR-logo-board.png", 1400, 960, False),
        ("NorthstarOR-AppIcon-1024.svg", BRAND / "NorthstarOR-AppIcon-1024.png", 1024, 1024, True),
        ("lockup-horizontal-dark.svg", BRAND / "lockup-horizontal-dark@2x.png", 1800, 440, False),
        ("lockup-horizontal-light.svg", BRAND / "lockup-horizontal-light@2x.png", 1800, 440, False),
        ("mark-color-dark.svg", BRAND / "mark-color-dark.png", 1152, 672, False),
        ("mark-white.svg", BRAND / "mark-white.png", 1152, 672, False),
        ("mark-navy.svg", BRAND / "mark-navy.png", 1152, 672, False),
        ("NorthstarOR-AppIcon-1024.svg", assets / "AppIcon.appiconset/AppIcon-1024.png", 1024, 1024, True),
        ("mark-compact.svg", assets / "BrandMark.imageset/mark-compact@3x.png", 576, 336, False),
    ]
    with tempfile.TemporaryDirectory(prefix="northstar-brand-") as tmp:
        renderer = Path(tmp) / "render"
        subprocess.run(["swiftc", str(BRAND / "source/render.swift"), "-o", str(renderer)], check=True)
        for source, target, w, h, opaque in exports:
            subprocess.run([str(renderer), str(BRAND / source), str(target), str(w), str(h)], check=True)
            if opaque:
                with Image.open(target) as image:
                    image.convert("RGB").save(target)
            print(f"Exported {target.relative_to(REPO)} ({w} × {h})")


if __name__ == "__main__":
    main()
