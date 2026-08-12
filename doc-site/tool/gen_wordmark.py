#!/usr/bin/env python3
"""Regenerates the SVG sources that contain lettering, setting it in Nunito.

The wordmark used to be eight hand-drawn stroke paths. They carried two different
x-heights (the `e`/`a` bowls topped out 8px below the `v`/`i`) and an `a` whose stem
overshot its bowl at both ends, which read as a `d`. This sets the same lettering in
a real typeface instead.

Every glyph is emitted as an outlined `<path>`, never a `<text>` element, so the
SVGs render identically on a machine with no fonts installed -- which also removes
the social card's old dependency on Helvetica being present for the tagline.

Writes (all committed, do not hand-edit the lettering in them):
    web/images/social-card.svg    og:image / twitter:card
    web/images/full_logo.svg      horizontal lockup, dark wordmark
    web/images/full_logo_dark.svg the same lockup, white wordmark

Everything that is not lettering -- the mark, the gradients, the background motif,
the layout constants -- lives in this file as the template. Edit it here.

After running this, run gen_logo_assets.sh to re-raster og.png and sync the landing
site's copies of the shared assets.

Requires: fonttools (pip install fonttools)
"""
import os
import sys

try:
    from fontTools.misc.transform import Transform
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont
except ImportError:
    sys.exit("missing required package: fonttools (pip install fonttools)")

FONT = os.path.join(os.path.dirname(__file__), "fonts", "Nunito[wght].ttf")

INK = "#1f2937"
WHITE = "#ffffff"
INDIGO = "#4e5fc6"
AMBER = "#d97706"

WORD_WEIGHT = 700  # Bold for the wordmark
TAG_WEIGHT = 600   # SemiBold for the tagline, so it sits under the wordmark


class Face:
    """One weight instance of the variable font, drawn as outlines."""

    def __init__(self, path, weight):
        font = TTFont(path)
        if "fvar" in font:
            font = instantiateVariableFont(font, {"wght": weight}, inplace=True)
        self.glyphs = font.getGlyphSet()
        self.cmap = font.getBestCmap()
        self.hmtx = font["hmtx"]
        self.cap_height = font["OS/2"].sCapHeight

    def run(self, text, cap, x=0.0, tracking=0.0):
        """Outline `text` at the given cap height. Baseline is y=0, y grows down.

        Returns (path data, the x the next run should start at).
        """
        scale = cap / self.cap_height
        pen = SVGPathPen(self.glyphs, ntos=lambda v: f"{v:.2f}")
        for ch in text:
            name = self.cmap[ord(ch)]
            # y is negated: font space is y-up, SVG is y-down
            self.glyphs[name].draw(TransformPen(pen, Transform(scale, 0, 0, -scale, x, 0)))
            x += self.hmtx[name][0] * scale + tracking * cap
        return pen.getCommands(), x

    def left_bearing(self, ch, cap):
        """Where the first glyph's ink starts, so a block can be optically aligned."""
        bounds = BoundsPen(self.glyphs)
        self.glyphs[self.cmap[ord(ch)]].draw(bounds)
        return (bounds.bounds[0] if bounds.bounds else 0) * (cap / self.cap_height)

    def ink_bounds(self, text, cap, tracking=0.0):
        """Ink box of `text` as (x0, y0, x1, y1), baseline at y=0, y growing down.

        Ascenders reach higher than the cap height and the `i` dot higher still, so
        a lockup has to be sized off this rather than off the cap height, or the
        tall letters get clipped by the viewBox.
        """
        scale = cap / self.cap_height
        x = 0.0
        box = None
        for ch in text:
            name = self.cmap[ord(ch)]
            pen = BoundsPen(self.glyphs)
            self.glyphs[name].draw(pen)
            if pen.bounds:
                gx0, gy0, gx1, gy1 = pen.bounds
                # y flips with the same negation `run` applies
                cur = (x + gx0 * scale, -gy1 * scale, x + gx1 * scale, -gy0 * scale)
                box = cur if box is None else (
                    min(box[0], cur[0]), min(box[1], cur[1]),
                    max(box[2], cur[2]), max(box[3], cur[3]),
                )
            x += self.hmtx[name][0] * scale + tracking * cap
        return box


# --- the mark -----------------------------------------------------------------
# Three wing feathers and a stroked R. Shared by both outputs; unchanged.

WING_PATHS = """    <path d="M 110 82  A 64 64 0 0 1 30 14  A 200 200 0 0 0 110 82 Z"/>
    <path d="M 108 112 A 64 64 0 0 1 10 54  A 200 200 0 0 0 108 112 Z"/>
    <path d="M 108 142 A 64 64 0 0 1 16 110 A 200 200 0 0 0 108 142 Z"/>"""

LETTER_PATHS = """    <path d="M 100 198 V 66 H 140 A 38 38 0 0 1 140 142 H 100"/>
    <path d="M 126 144 L 184 198"/>"""

WING_GRADIENT = """    <linearGradient id="{id}" x1="20" y1="10" x2="120" y2="170" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#fbbf24"/>
      <stop offset="0.5" stop-color="#f59e0b"/>
      <stop offset="1" stop-color="#d97706"/>
    </linearGradient>"""

LETTER_GRADIENT = """    <linearGradient id="{id}" x1="100" y1="50" x2="190" y2="210" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#7a8df0"/>
      <stop offset="1" stop-color="#4e5fc6"/>
    </linearGradient>"""


# --- social card --------------------------------------------------------------

CARD_W, CARD_H = 1600, 675
CARD_LEFT = 490.0        # shared left edge for the wordmark and both tagline lines
CARD_WORD_CAP = 104.0
CARD_WORD_BASELINE = 272.5
CARD_TAG_CAP = 55.0
CARD_TAG_TRACKING = -0.005

TAGLINE = [
    (427.0, [("Build ", INK), ("APIs", INDIGO), (" Faster", INK)]),
    (523.0, [("Code Less, Deliver ", INK), ("More", AMBER)]),
]


def social_card(word, tag):
    d, _ = word.run("Revali", CARD_WORD_CAP)
    dx = CARD_LEFT - word.left_bearing("R", CARD_WORD_CAP)

    lines = []
    tdx = CARD_LEFT - tag.left_bearing("B", CARD_TAG_CAP)
    for baseline, runs in TAGLINE:
        x = 0.0
        parts = [f'  <g transform="translate({tdx:.2f} {baseline})">']
        for text, color in runs:
            run_d, x = tag.run(text, CARD_TAG_CAP, x=x, tracking=CARD_TAG_TRACKING)
            parts.append(f'    <path d="{run_d}" fill="{color}"/>')
        parts.append("  </g>")
        lines.append("\n".join(parts))
    tagline = "\n".join(lines)

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CARD_W} {CARD_H}" width="{CARD_W}" height="{CARD_H}">
  <!-- GENERATED by tool/gen_wordmark.py; edit that, not this file -->
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1600" y2="675" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#ffffff"/>
      <stop offset="0.55" stop-color="#f4f6fe"/>
      <stop offset="1" stop-color="#e6eafb"/>
    </linearGradient>
{WING_GRADIENT.format(id="wing")}
{LETTER_GRADIENT.format(id="letter")}
    <g id="wing-shape">
{WING_PATHS}
    </g>
    <g id="letter-shape" fill="none" stroke-width="32" stroke-linecap="round" stroke-linejoin="round">
{LETTER_PATHS}
    </g>
  </defs>

  <rect width="{CARD_W}" height="{CARD_H}" fill="url(#bg)"/>

  <!-- background motif: the wing, oversized, bleeding off the right edge -->
  <g transform="translate(1180 -120) scale(4.2) rotate(-8 60 90)" opacity="0.09">
    <use href="#wing-shape" fill="#4e5fc6"/>
  </g>

  <!-- primary mark, height 320 -->
  <g transform="translate(104 169.6) scale(1.6)">
    <use href="#wing-shape" fill="url(#wing)"/>
    <use href="#letter-shape" stroke="url(#letter)"/>
  </g>

  <!-- wordmark, Nunito Bold outlined, cap height {CARD_WORD_CAP:.0f} -->
  <g transform="translate({dx:.2f} {CARD_WORD_BASELINE})" fill="{INK}">
    <path d="{d}"/>
  </g>

  <!-- tagline, Nunito SemiBold outlined, cap height {CARD_TAG_CAP:.0f} -->
{tagline}
</svg>
"""


# --- horizontal lockup --------------------------------------------------------

# The mark's ink box in its own coordinate space, measured off a render of the paths
# rather than guessed: the wing arcs and the R's 32px round-capped stroke both push
# the ink well outside the path coordinates.
MARK_INK = (9.5, 14.0, 200.0, 214.0)

LOCK_MARK_HEIGHT = 140.0  # the mark's ink height sets the scale of the whole lockup
LOCK_WORD_CAP = 80.0      # 1.75x smaller than the mark, so it reads as a badge
LOCK_GAP = 40.0           # mark ink right edge to wordmark ink left edge
LOCK_PAD = 4.0


def lockup(word, color, gradient_prefix):
    """The mark and the wordmark side by side, with the viewBox fitted to the ink."""
    d, _ = word.run("Revali", LOCK_WORD_CAP)
    wx0, wy0, wx1, wy1 = word.ink_bounds("Revali", LOCK_WORD_CAP)

    scale = LOCK_MARK_HEIGHT / (MARK_INK[3] - MARK_INK[1])
    mark_w = (MARK_INK[2] - MARK_INK[0]) * scale

    # Lay out in a scratch space, then shift everything so the ink starts at the pad.
    # The mark's ink sits at y=0..LOCK_MARK_HEIGHT; the wordmark's cap block is
    # centred on it, which is what the hand-drawn lockup did by eye.
    mark_dx = -MARK_INK[0] * scale
    mark_dy = -MARK_INK[1] * scale
    baseline = LOCK_MARK_HEIGHT / 2 + LOCK_WORD_CAP / 2
    word_dx = mark_w + LOCK_GAP - wx0

    top = min(0.0, baseline + wy0)
    bottom = max(LOCK_MARK_HEIGHT, baseline + wy1)
    shift_y = LOCK_PAD - top

    width = round(word_dx + wx1 + LOCK_PAD * 2)
    height = round(bottom - top + LOCK_PAD * 2)

    wing_id, letter_id = f"{gradient_prefix}-wing", f"{gradient_prefix}-letter"
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-label="Revali">
  <!-- GENERATED by tool/gen_wordmark.py; edit that, not this file -->
  <title>Revali</title>
  <defs>
{WING_GRADIENT.format(id=wing_id)}
{LETTER_GRADIENT.format(id=letter_id)}
  </defs>

  <!-- mark, ink height {LOCK_MARK_HEIGHT:.0f} -->
  <g transform="translate({LOCK_PAD + mark_dx:.2f} {shift_y + mark_dy:.2f}) scale({scale:.4f})">
    <g fill="url(#{wing_id})">
{WING_PATHS}
    </g>
    <g fill="none" stroke="url(#{letter_id})" stroke-width="32" stroke-linecap="round" stroke-linejoin="round">
{LETTER_PATHS}
    </g>
  </g>

  <!-- wordmark, Nunito Bold outlined, cap height {LOCK_WORD_CAP:.0f} -->
  <g transform="translate({LOCK_PAD + word_dx:.2f} {shift_y + baseline:.2f})" fill="{color}">
    <path d="{d}"/>
  </g>
</svg>
"""


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    images = os.path.join(root, "web", "images")

    word = Face(FONT, WORD_WEIGHT)
    tag = Face(FONT, TAG_WEIGHT)

    outputs = {
        "social-card.svg": social_card(word, tag),
        "full_logo.svg": lockup(word, INK, "revali"),
        "full_logo_dark.svg": lockup(word, WHITE, "revali"),
    }
    for name, content in outputs.items():
        path = os.path.join(images, name)
        with open(path, "w") as fh:
            fh.write(content)
        print(f"web/images/{name}")


if __name__ == "__main__":
    main()
