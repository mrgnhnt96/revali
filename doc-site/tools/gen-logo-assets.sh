#!/usr/bin/env bash
#
# Regenerates every raster logo asset from the SVG sources in static/img.
#
# Sources of truth (edit these, never the rasters):
#   logo.svg         the mark, 256x256, transparent
#   full_logo.svg    horizontal lockup, mark + wordmark  (full_logo_dark.svg is the same
#                    file with the wordmark recoloured to #ffffff)
#   social-card.svg  og:image / twitter:card
#
# Requires: rsvg-convert (brew install librsvg), magick (brew install imagemagick)
set -euo pipefail

cd "$(dirname "$0")/../static/img"

for bin in rsvg-convert magick; do
    command -v "$bin" >/dev/null || { echo "missing required tool: $bin" >&2; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "logo.png (774x774)"
rsvg-convert -w 774 -h 774 logo.svg -o logo.png

echo "favicon.ico (16/32/48)"
# Trim to the artwork and re-pad to a square before downscaling, so the small sizes
# spend their few pixels on the mark rather than on transparent margin.
rsvg-convert -w 512 -h 512 logo.svg -o "$tmp/mark.png"
magick "$tmp/mark.png" -trim +repage -bordercolor none -border 14 "$tmp/trim.png"
side=$(magick identify -format '%[fx:max(w,h)]' "$tmp/trim.png")
magick "$tmp/trim.png" -background none -gravity center -extent "${side}x${side}" "$tmp/sq.png"
magick "$tmp/sq.png" \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 16x16 \) \
    -delete 0 favicon.ico

echo "social-card.png (1600x675)"
rsvg-convert -w 1600 -h 675 social-card.svg -o social-card.png
magick social-card.png -strip social-card.png

echo "done"
