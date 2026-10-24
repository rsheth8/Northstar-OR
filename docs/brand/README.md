# Northstar OR identity

A shooting North Star passes over a rural clinic and one evergreen. Its continuous, tapered wake contains a single medical pulse. A cutout plus identifies the clinic; the curved ground joins the setting into one silhouette. The mark expresses support reaching a rural care team across distance.

The gold star leads, the blue wake supplies motion, and the simple landscape supplies context. Flat shapes, open space, and the outlined Inter Display wordmark keep the identity consistent across the app and presentation.

![Final Northstar OR logo](NorthstarOR-final.png)

## Ready-to-use files

| File | Use |
| --- | --- |
| `mark-color-dark.svg` / `.png` | Transparent full-color emblem on midnight navy |
| `lockup-horizontal-dark.svg` / `@2x.png` | Full-color logo with the name, for dark surfaces |
| `lockup-stacked-dark.svg` | Vertical full-color logo with the name |
| `mark-navy.svg` / `.png`, `lockup-horizontal-light.svg` / `@2x.png`, `lockup-stacked-light.svg` | Single-color artwork for white and light surfaces |
| `mark-white.svg` / `.png`, `lockup-horizontal-white.svg` | Single-color artwork for dark surfaces |
| `mark-compact.svg`, `mark-compact-white.svg`, `mark-compact-navy.svg` | Connected star and pulse for small placements |
| `NorthstarOR-AppIcon-1024.svg` / `.png` | Production app icon: square, opaque, 1024 × 1024 |
| `NorthstarOR-final.svg` / `.png` | Finished presentation artwork with a navy background |
| `NorthstarOR-logo-board.svg` / `.png` | Color, single-color, and actual-size proof |

The SVGs are editable vector masters. All wordmarks contain outlined lettering, so no font installation is needed. The plus is genuinely transparent in the standalone emblems.

## Use consistently

- Use the full emblem at 64 px high or larger, and the horizontal logo at 320 px wide or larger. For smaller placements, use the compact connected star/pulse, at least 28 px high.
- The app icon retains the full scene. Its 58 px and 40 px representations are shown on the proof board; the small in-app header uses the compact mark.
- Leave at least half the star's width as clear space around an emblem. Leave half the wordmark's capital height around a lockup.
- Keep the supplied proportions, star/trail connection, and word spacing. Use the supplied single-color artwork for light backgrounds.
- Keep the app icon square and opaque. iPadOS applies the corner mask; the rounded icon on the proof board is a preview.
- The archived Blender emblem is the earlier exploration from PR #5. Current production artwork is the flat shooting-star identity in this directory.

| Role | Color |
| --- | --- |
| Midnight navy | `#0B1220` |
| Aurora green | `#3DDC97` |
| Warm white | `#E8F1F8` |
| Ice blue | `#7FC4E8` |
| North Star gold | `#F9D98A` |

## App integration and regeneration

`AppIcon.appiconset` uses the opaque 1024 px PNG. `BrandMark.imageset` uses the compact star/pulse at 3× for the existing 28 pt header. The SwiftUI layout and shared theme are unchanged.

On macOS, with Swift command-line tools and Pillow installed:

```sh
python3 docs/brand/source/build_brand.py
```

`source/build_brand.py` holds the shared geometry and layout. `source/wordmark.svg` preserves the existing Inter Display outlines. `source/render.swift` exports the SVGs through AppKit. The script regenerates the masters, presentation/proof PNGs, and app catalog assets without network access.

Credits: original shooting-star composition and vector production by OpenAI Codex, informed by the team's rural-clinic emblem and OpenAI image-generation concept exploration. Inter Display is used under the SIL Open Font License. AppKit/Swift and Pillow are export tools only.
