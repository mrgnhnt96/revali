/// The page's icon set.
///
/// Hand-rolled rather than pulled from a library: the page needs about twenty
/// glyphs, and an icon dependency would either ship a font or force a runtime
/// component for shapes that never change. Each is a 24x24 stroked path in the
/// Lucide idiom, so they sit together as one family.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Wraps [paths] in a stroked 24x24 `<svg>`.
///
/// `aria-hidden` on every icon: each one on this page sits beside a text label
/// that already says the same thing, and announcing both is noise. If an icon
/// is ever used *alone* as a control, it needs a label on the control itself.
Component _icon(String paths, {String? fill}) {
  return svg(
    attributes: {
      'viewBox': '0 0 24 24',
      'fill': fill ?? 'none',
      'stroke': fill == null ? 'currentColor' : 'none',
      'stroke-width': '1.75',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
      'aria-hidden': 'true',
    },
    [RawText(paths)],
  );
}

// --- Brand ----------------------------------------------------------------

final github = _icon(
  '<path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 '
  '6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 '
  '2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 '
  '5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"/>',
);

final pubdev = _icon(
  '<path d="m12 2 9 5v10l-9 5-9-5V7z"/><path d="M12 12v10"/>'
  '<path d="m3 7 9 5 9-5"/>',
);

// --- Pipeline outputs -----------------------------------------------------

final server = _icon(
  '<rect x="2" y="3" width="20" height="7" rx="2"/>'
  '<rect x="2" y="14" width="20" height="7" rx="2"/>'
  '<path d="M6 6.5h.01M6 17.5h.01"/>',
);

final client = _icon('<rect x="5" y="2" width="14" height="20" rx="2.5"/><path d="M11 18.5h2"/>');

final spec = _icon(
  '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>'
  '<path d="M14 2v6h6"/><path d="M9 13h6M9 17h4"/>',
);

final docker = _icon(
  '<path d="M21 11c-1.5-1-3.5-.5-4 .5"/>'
  '<rect x="3" y="11" width="3" height="3"/><rect x="7" y="11" width="3" height="3"/>'
  '<rect x="11" y="11" width="3" height="3"/><rect x="7" y="7" width="3" height="3"/>'
  '<rect x="11" y="7" width="3" height="3"/>'
  '<path d="M2 16c3 2 8 2.5 12 1 3-1 5-3 5.5-5"/>',
);

// --- Features -------------------------------------------------------------

final bolt = _icon('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>');

final shield = _icon(
  '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/>',
);

final blocks = _icon(
  '<rect x="3" y="3" width="7" height="7" rx="1.5"/>'
  '<rect x="14" y="3" width="7" height="7" rx="1.5"/>'
  '<rect x="3" y="14" width="7" height="7" rx="1.5"/>'
  '<rect x="14" y="14" width="7" height="7" rx="1.5"/>',
);

final plug = _icon(
  '<path d="M9 2v6M15 2v6"/>'
  '<path d="M6 8h12v3a6 6 0 0 1-6 6 6 6 0 0 1-6-6z"/><path d="M12 17v5"/>',
);

final radio = _icon(
  '<circle cx="12" cy="12" r="2"/>'
  '<path d="M7.5 7.5a6.4 6.4 0 0 0 0 9M16.5 16.5a6.4 6.4 0 0 0 0-9"/>'
  '<path d="M4.5 4.5a10.6 10.6 0 0 0 0 15M19.5 19.5a10.6 10.6 0 0 0 0-15"/>',
);

final terminal = _icon('<path d="m4 17 6-5-6-5"/><path d="M12 19h8"/>');

final refresh = _icon('<path d="M21 12a9 9 0 1 1-2.64-6.36"/><path d="M21 3v6h-6"/>');

final layers = _icon(
  '<path d="m12 2 9 5-9 5-9-5z"/><path d="m3 12 9 5 9-5"/><path d="m3 17 9 5 9-5"/>',
);

final stethoscope = _icon(
  '<path d="M5 2v6a4 4 0 0 0 8 0V2"/><path d="M9 12v3a5 5 0 0 0 10 0v-2"/>'
  '<circle cx="19" cy="10" r="2"/>',
);

final bug = _icon(
  '<rect x="8" y="6" width="8" height="14" rx="4"/>'
  '<path d="M8 12H3M21 12h-5M8 17l-4 2M20 19l-4-2M8 8 4 6M20 6l-4 2"/>'
  '<path d="m9 6 1-3M15 6l-1-3"/>',
);

final route = _icon(
  '<circle cx="6" cy="19" r="3"/><circle cx="18" cy="5" r="3"/>'
  '<path d="M9 19h6a4 4 0 0 0 0-8H9a4 4 0 0 1 0-8h3"/>',
);

final wand = _icon(
  '<path d="m3 21 12-12"/><path d="m15 9 3-3"/>'
  '<path d="M18 3v4M20 5h-4M5 13v3M6.5 14.5h-3M18 15v3M19.5 16.5h-3"/>',
);

// --- Utility --------------------------------------------------------------

final check = _icon('<path d="m4 12 5 5L20 6"/>');

final arrow = _icon('<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>');

final copy = _icon(
  '<rect x="9" y="9" width="12" height="12" rx="2"/>'
  '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
);

final book = _icon(
  '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>'
  '<path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2"/>',
);

final lock = _icon(
  '<rect x="4" y="10" width="16" height="11" rx="2"/>'
  '<path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
);

final swap = _icon(
  '<path d="m17 2 4 4-4 4"/><path d="M3 6h18"/>'
  '<path d="m7 22-4-4 4-4"/><path d="M21 18H3"/>',
);
