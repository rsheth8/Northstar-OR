"""Measure intended opaque sRGB pairs directly from Swift source; not a UI audit."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[3]
source = (root / 'NorthstarOR/DesignSystem/NorthstarWorkspacePalette.swift').read_text()
colors = {name: int(value, 16) for name, value in re.findall(
    r'static let (\w+) = Color\(hex: 0x([0-9A-F]+)\)', source)}

def luminance(value):
    rgb = [(value >> shift & 255) / 255 for shift in (16, 8, 0)]
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(a * b for a, b in zip(linear, (.2126, .7152, .0722)))

pairs = []
for bg in ('canvas', 'surface', 'surfaceSubtle', 'selection', 'secondaryPressed'):
    pairs += [(fg, bg, 4.5) for fg in ('text', 'textSecondary')]
    pairs += [(fg, bg, 3) for fg in ('boundary', 'focus', 'selectionIndicator')]
for fg in ('success', 'attention', 'failure', 'information'):
    pairs += [(fg, bg, 4.5) for bg in ('canvas', 'surface', fg + 'Surface')]
    pairs += [('text', fg + 'Surface', 4.5)]
pairs += [(fg, 'header', 4.5) for fg in ('onHeader', 'onHeaderSecondary')]
pairs += [('onAction', bg, 4.5) for bg in ('action', 'actionPressed')]
pairs += [('disabledText', 'disabledSurface', 4.5)]
print('| Foreground | Background | Ratio | Target |')
print('| --- | --- | --- | --- |')
failed = []
for fg, bg, target in pairs:
    a, b = sorted((luminance(colors[fg]), luminance(colors[bg])))
    ratio = (b + .05) / (a + .05)
    print(f'| {fg} | {bg} | {ratio:.2f}:1 | {target}:1 |')
    if ratio < target:
        failed.append((fg, bg, ratio))
if failed:
    raise SystemExit(f'Below target: {failed}')
