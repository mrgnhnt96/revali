#!/usr/bin/env bash
#
# Regenerates every raster logo asset from the SVG sources in web/images.
#
# Sources of truth (edit these, never the rasters):
#   web/images/logo.svg         the mark, 256x256, transparent
#
# The two SVGs that carry lettering are themselves generated -- the wordmark is set in
# Nunito and emitted as outlined paths, so edit tool/gen_wordmark.py and re-run it
# before running this script:
#   web/images/full_logo.svg    horizontal lockup, mark + wordmark  (full_logo_dark.svg
#                               is the same file with the wordmark recoloured to #ffffff)
#   web/images/social-card.svg  og:image / twitter:card
#
# Outputs, all of which are committed:
#   web/images/logo.png   web/images/og.png   web/favicon.ico   web/favicon.png
#
# favicon.png as well as favicon.ico because jaspr_content's PageLayoutBase
# hardcodes `type="image/png"` on the icon link it emits, and content/_data/site.yaml
# points at the PNG accordingly.
#
# Requires: rsvg-convert (brew install librsvg), magick (brew install imagemagick)
set -euo pipefail

cd "$(dirname "$0")/.."

for bin in rsvg-convert magick; do
    command -v "$bin" >/dev/null || { echo "missing required tool: $bin" >&2; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "web/images/logo.png (774x774)"
rsvg-convert -w 774 -h 774 web/images/logo.svg -o web/images/logo.png

echo "web/favicon.png (256x256)"
rsvg-convert -w 256 -h 256 web/images/logo.svg -o web/favicon.png

echo "web/favicon.ico (16/32/48)"
# Trim to the artwork and re-pad to a square before downscaling, so the small sizes
# spend their few pixels on the mark rather than on transparent margin.
rsvg-convert -w 512 -h 512 web/images/logo.svg -o "$tmp/mark.png"
magick "$tmp/mark.png" -trim +repage -bordercolor none -border 14 "$tmp/trim.png"
side=$(magick identify -format '%[fx:max(w,h)]' "$tmp/trim.png")
magick "$tmp/trim.png" -background none -gravity center -extent "${side}x${side}" "$tmp/sq.png"
magick "$tmp/sq.png" \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 16x16 \) \
    -delete 0 web/favicon.ico

# Named og.png rather than social-card.png because that is what
# content/_data/site.yaml's `image:` points at, and it is the only consumer.
echo "web/images/og.png (1600x675)"
rsvg-convert -w 1600 -h 675 web/images/social-card.svg -o web/images/og.png
magick web/images/og.png -strip web/images/og.png

echo "done"
