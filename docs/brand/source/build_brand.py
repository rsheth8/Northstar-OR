"""Generate the Northstar OR brand set (SVG + PNG) from one emblem definition.

Run from the repo root:  python3 docs/brand/source/build_brand.py
Needs Google Chrome (headless) for the PNG exports.
"""
import math, re, subprocess
from pathlib import Path

BRAND = Path(__file__).resolve().parent.parent
REPO = BRAND.parent.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Palette (matches NorthstarTheme.swift)
NAVY, NAVY_TOP, INK = "#0B1220", "#1B2C55", "#0E1A33"
GOLD, GOLD_DEEP, CORE = "#F9D98A", "#E0A526", "#FFF6DC"
AURORA, AURORA_SHADE = "#3DDC97", "#22B57A"
ICE, AMBER, CLINIC = "#7FC4E8", "#FFB020", "#E8F1F8"
SNOW_TOP, SNOW_BOTTOM, HILL = "#D6E3EF", "#9FB6CC", "#1A2A4A"

# ---------- geometry (512 x 512 scene) ----------
A, B = (150, 226), (372, 226)  # rainbow ends: pine tip -> clinic roof peak
APEX = 166                      # top of the rainbow
STAR_Y, STAR_TOP, STAR_SIDE, STAR_BOTTOM = 76, 54, 34, 34
GAP = 10                        # space between the R spike and the star
STAR_X = (A[0] + B[0]) / 2      # beat and star sit dead centre
HALF = 56                       # half-width of the beat
AMP = APEX - (STAR_Y + STAR_BOTTOM + GAP)
_dx, _dy = B[0] - STAR_X, A[1] - APEX
RADIUS = (_dx ** 2 + _dy ** 2) / (2 * _dy)  # circle through both ends and the apex

# Mirror-symmetric beat in units of HALF: a sharp straight-sided R spike
# with a smooth dip on each side.
R_WIDTH = 0.12
WAVES = [(0.15, -0.26, 0.045)]  # (centre, height, width) of the two dips


def _beat_raw(d):
    y = max(0.0, 1 - abs(d) / R_WIDTH)
    for c, h, w in WAVES:
        for cc in (c, -c):
            y += h * math.exp(-((d - cc) / w) ** 2 / 2)
    return y


def beat(d):
    return _beat_raw(d) / _beat_raw(0)  # normalise so the spike tip is exactly AMP


def baseline(x):
    """Circular rainbow arc through A, the apex and B."""
    return APEX + RADIUS - math.sqrt(RADIUS ** 2 - (x - STAR_X) ** 2)


def heartbeat_d():
    n = 1600
    xs = [A[0] + i * (B[0] - A[0]) / n for i in range(n + 1)]
    pts = [f"{x:.2f} {baseline(x) - AMP * beat((x - STAR_X) / HALF):.2f}" for x in xs]
    return "M" + " L".join(pts)


def star_d(cx, cy):
    """Four-point star with concave sides and a long north point."""
    t, sd, b = STAR_TOP, STAR_SIDE, STAR_BOTTOM
    p = lambda dx, dy: f"{cx + dx:.1f} {cy + dy:.1f}"
    return (f"M{p(0, -t)} C{p(3, -14)} {p(8, -5)} {p(sd, 0)} "
            f"C{p(8, 5)} {p(3, 10)} {p(0, b)} "
            f"C{p(-3, 10)} {p(-8, 5)} {p(-sd, 0)} "
            f"C{p(-8, -5)} {p(-3, -14)} {p(0, -t)}Z")


BACK_HILL = "M0 330 C120 290 200 308 280 320 C360 332 430 292 512 302 V512 H0Z"
SNOW = "M0 360 C110 338 190 350 262 354 C306 357 326 326 376 324 C430 322 470 338 512 346 V512 H0Z"
TRAIL = "M363 330 H381 C384 370 330 392 300 420 C270 448 290 486 330 520 H240 C210 486 214 444 256 412 C296 384 352 370 363 330Z"
SNOW_LINE = "M0 360 C110 338 190 350 262 354 C306 357 326 326 376 324 C430 322 470 338 512 346"
PINES = [(150, 358, 132), (102, 362, 108), (200, 364, 96)]  # x, base y, height


def pine_tiers(x, base, h):
    """Three stacked tiers; returns list of (apex_y, base_y, half_width)."""
    out = []
    for i, (top, bot, w) in enumerate(((0.0, 0.42, 0.20), (0.22, 0.70, 0.28), (0.46, 1.0, 0.36))):
        out.append((base - h * (1 - top), base - h * (1 - bot), h * w))
    return out


def pines_color(snow=True):
    s = []
    for x, base, h in PINES:  # listed back to front
        s.append(f'<rect x="{x-4}" y="{base-10}" width="8" height="12" rx="2" fill="{INK}"/>')
        for ay, by, w in pine_tiers(x, base, h):
            s.append(f'<path d="M{x} {ay} L{x-w:.1f} {by:.1f} L{x} {by:.1f}Z" fill="{AURORA}"/>')
            s.append(f'<path d="M{x} {ay} L{x+w:.1f} {by:.1f} L{x} {by:.1f}Z" fill="{AURORA_SHADE}"/>')
        if snow:
            ay, by, w = pine_tiers(x, base, h)[0]
            f = 0.38
            s.append(f'<path d="M{x} {ay} L{x - w*f:.1f} {ay + (by-ay)*f:.1f} L{x - w*f*0.35:.1f} {ay + (by-ay)*f*0.82:.1f} '
                     f'L{x} {ay + (by-ay)*f:.1f} L{x + w*f*0.4:.1f} {ay + (by-ay)*f*0.8:.1f} L{x + w*f:.1f} {ay + (by-ay)*f:.1f}Z" fill="{CLINIC}"/>')
    return "".join(s)


def pines_mono(c):
    s = []
    for x, base, h in PINES:
        for ay, by, w in pine_tiers(x, base, h):
            s.append(f'<path d="M{x} {ay} L{x-w:.1f} {by:.1f} L{x+w:.1f} {by:.1f}Z" fill="{c}"/>')
    return "".join(s)


CX, CB = 372, 330  # clinic centre x, ground y


def clinic_color():
    return (f'<rect x="{CX-50}" y="{CB-62}" width="100" height="64" fill="{CLINIC}"/>'
            f'<rect x="{CX+30}" y="{CB-62}" width="20" height="64" fill="#C9D7E6"/>'
            f'<path d="M{CX-62} {CB-58} L{CX} {CB-104} L{CX} {CB-58}Z" fill="{AURORA}"/>'
            f'<path d="M{CX+62} {CB-58} L{CX} {CB-104} L{CX} {CB-58}Z" fill="{AURORA_SHADE}"/>'
            f'<path d="M{CX-10} {CB+2} V{CB-24} a10 10 0 0 1 20 0 V{CB+2}Z" fill="{AMBER}"/>'
            f'<rect x="{CX-38}" y="{CB-46}" width="18" height="16" rx="2" fill="{AMBER}"/>'
            f'<rect x="{CX+20}" y="{CB-46}" width="18" height="16" rx="2" fill="{AMBER}"/>')


def clinic_mono(c):
    body = (f"M{CX-50} {CB-58} H{CX+50} V{CB} H{CX-50}Z "
            f"M{CX-10} {CB} V{CB-24} a10 10 0 0 1 20 0 V{CB}Z "
            f"M{CX-38} {CB-46} h18 v16 h-18Z M{CX+20} {CB-46} h18 v16 h-18Z")
    return (f'<path d="{body}" fill="{c}" fill-rule="evenodd"/>'
            f'<path d="M{CX-62} {CB-62} L{CX} {CB-106} L{CX+62} {CB-62}Z" fill="{c}"/>')


def heartbeat(color, glow=True, w=6):
    d = heartbeat_d()
    g = (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w*3}" stroke-linecap="round" '
         f'stroke-linejoin="round" opacity="0.2" filter="url(#soft)"/>') if glow else ""
    return (g + f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<circle cx="{A[0]}" cy="{A[1]}" r="{w+1}" fill="{color}"/><circle cx="{B[0]}" cy="{B[1]}" r="{w+1}" fill="{color}"/>')


DEFS = (f'<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="7"/></filter>'
        f'<filter id="haze" x="-30%" y="-80%" width="160%" height="260%"><feGaussianBlur stdDeviation="16"/></filter>'
        f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{NAVY_TOP}"/><stop offset="1" stop-color="{NAVY}"/></linearGradient>'
        f'<linearGradient id="snow" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{SNOW_TOP}"/><stop offset="1" stop-color="{SNOW_BOTTOM}"/></linearGradient>'
        f'<radialGradient id="starfill" cx="0.5" cy="0.62" r="0.6"><stop offset="0" stop-color="{CORE}"/><stop offset="1" stop-color="{GOLD}"/></radialGradient>'
        f'<radialGradient id="starglow"><stop offset="0" stop-color="{GOLD}" stop-opacity="0.45"/><stop offset="1" stop-color="{GOLD}" stop-opacity="0"/></radialGradient>')


def scene_color(clip_id):
    return (f'<g clip-path="url(#{clip_id})">'
            f'<rect width="512" height="512" fill="url(#sky)"/>'
            f'<path d="M-40 150 C80 110 160 150 260 120 S440 70 560 96 L560 130 C440 118 360 160 260 160 S80 160 -40 196Z" '
            f'fill="{AURORA}" opacity="0.16" filter="url(#haze)"/>'
            f'<path d="{BACK_HILL}" fill="{HILL}"/><path d="{SNOW}" fill="url(#snow)"/>'
            f'<path d="{TRAIL}" fill="#B3C5D7"/>'
            f'{pines_color()}{clinic_color()}'
            f'<circle cx="{STAR_X:.1f}" cy="{STAR_Y}" r="92" fill="url(#starglow)"/>'
            f'{heartbeat(ICE)}'
            f'<path d="{star_d(round(STAR_X, 1), STAR_Y)}" fill="url(#starfill)"/>'
            f'</g>')


def badge_color(ring=GOLD):
    return (f'<defs>{DEFS}<clipPath id="disc"><circle cx="256" cy="256" r="240"/></clipPath></defs>'
            f'{scene_color("disc")}'
            f'<circle cx="256" cy="256" r="236" fill="none" stroke="{ring}" stroke-width="9"/>'
            f'<circle cx="256" cy="256" r="222" fill="none" stroke="{ring}" stroke-width="2" opacity="0.35"/>')


def badge_mono(c):
    return (f'<defs><clipPath id="inner"><circle cx="256" cy="256" r="222"/></clipPath></defs>'
            f'<circle cx="256" cy="256" r="236" fill="none" stroke="{c}" stroke-width="12"/>'
            f'<g clip-path="url(#inner)"><path d="{SNOW_LINE}" fill="none" stroke="{c}" stroke-width="8"/></g>'
            f'{pines_mono(c)}{clinic_mono(c)}{heartbeat(c, glow=False, w=9)}'
            f'<path d="{star_d(round(STAR_X, 1), STAR_Y)}" fill="{c}"/>')


def app_icon():
    return (f'<defs>{DEFS}<clipPath id="sq"><rect width="512" height="512"/></clipPath></defs>'
            f'<g transform="translate(256 300) scale(1.2) translate(-256 -256)">{scene_color("sq")}</g>')


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>\n'


def placed(body, x, y, size):
    return f'<g transform="translate({x} {y}) scale({size/512:.5f})">{body}</g>'


def wordmark(old_file):
    """Reuse the outlined Inter Display wordmark from the previous lockups."""
    txt = (BRAND / old_file).read_text()
    paths = re.findall(r'<path transform="translate[^>]*/>', txt)
    return "".join(paths[-2:])


def write(name, content):
    (BRAND / name).write_text(content)
    print("wrote", name)


def png(svg_name, out, w, h, scale=1, opaque=False):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    f"--force-device-scale-factor={scale}", f"--window-size={w},{h}",
                    "--default-background-color=00000000", f"--screenshot={out}",
                    (BRAND / svg_name).as_uri()], check=True, capture_output=True)
    if opaque:  # App Store icons must not have an alpha channel
        tmp = str(out) + ".jpg"
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100", str(out), "--out", tmp], check=True, capture_output=True)
        subprocess.run(["sips", "-s", "format", "png", tmp, "--out", str(out)], check=True, capture_output=True)
        Path(tmp).unlink()
    print("png", out)


def main():
    words = {k: wordmark(f"lockup-{k}.svg") for k in
             ("horizontal-dark", "horizontal-light", "horizontal-white", "stacked-dark", "stacked-light")}

    write("mark-color-dark.svg", svg(512, 512, badge_color(GOLD)))
    write("mark-color-light.svg", svg(512, 512, badge_color(GOLD_DEEP)))
    write("mark-white.svg", svg(512, 512, badge_mono("#FFFFFF")))
    write("mark-navy.svg", svg(512, 512, badge_mono(INK)))
    write("NorthstarOR-AppIcon-1024.svg", svg(1024, 1024, placed(app_icon(), 0, 0, 1024)))

    write("lockup-horizontal-dark.svg", svg(834, 205, placed(badge_color(GOLD), 14, 12, 181) + words["horizontal-dark"]))
    write("lockup-horizontal-light.svg", svg(834, 205, placed(badge_color(GOLD_DEEP), 14, 12, 181) + words["horizontal-light"]))
    write("lockup-horizontal-white.svg", svg(834, 205, placed(badge_mono("#FFFFFF"), 14, 12, 181) + words["horizontal-white"]))
    write("lockup-stacked-dark.svg", svg(458, 350, placed(badge_color(GOLD), 115, 14, 228) + words["stacked-dark"]))
    write("lockup-stacked-light.svg", svg(458, 350, placed(badge_color(GOLD_DEEP), 115, 14, 228) + words["stacked-light"]))

    png("lockup-horizontal-dark.svg", BRAND / "lockup-horizontal-dark@2x.png", 834, 205, 2)
    assets = REPO / "NorthstarOR/Resources/Assets.xcassets"
    png("mark-color-dark.svg", assets / "BrandMark.imageset/mark-color-dark@2x.png", 512, 512, 1)
    png("NorthstarOR-AppIcon-1024.svg", assets / "AppIcon.appiconset/AppIcon-1024.png", 1024, 1024, 1, opaque=True)
    png("source/board.html", BRAND / "NorthstarOR-logo-board.png", 1400, 1020, 1)


if __name__ == "__main__":
    main()
