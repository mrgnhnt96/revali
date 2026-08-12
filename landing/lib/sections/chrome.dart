import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/icons.dart' as ico;

const _docs = 'https://docs.revali.dev';
const _repo = 'https://github.com/mrgnhnt96/revali';

/// The fixed decorative backdrop: glows, grid and grain.
///
/// Rendered once, `position: fixed`, behind everything. Purely presentational,
/// so it is hidden from assistive technology outright.
class Ambient extends StatelessComponent {
  const Ambient();

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'ambient',
      attributes: {'aria-hidden': 'true'},
      [
        div(classes: 'ambient__grid', []),
        div(classes: 'ambient__glow ambient__glow--amber', []),
        div(classes: 'ambient__glow ambient__glow--indigo', []),
        div(classes: 'ambient__grain', []),
      ],
    );
  }
}

class SiteHeader extends StatelessComponent {
  const SiteHeader();

  @override
  Component build(BuildContext context) {
    return header(
      classes: 'hdr',
      attributes: {'data-header': ''},
      [
        div(classes: 'shell hdr__inner', [
          a(classes: 'hdr__brand', href: '/', [
            img(src: '/images/logo.svg', alt: ''),
            span([Component.text('Revali')]),
          ]),
          nav(classes: 'hdr__nav', [
            a(classes: 'hdr__link hdr__link--hide-sm', href: '#how', [
              Component.text('How it works'),
            ]),
            a(classes: 'hdr__link hdr__link--hide-sm', href: '#features', [
              Component.text('Features'),
            ]),
            a(classes: 'hdr__link hdr__link--hide-sm', href: '$_docs/constructs', [
              Component.text('Constructs'),
            ]),
            a(classes: 'hdr__link', href: _docs, [Component.text('Docs')]),
            a(
              classes: 'btn btn--ghost',
              href: _repo,
              attributes: {'target': '_blank', 'rel': 'noopener', 'aria-label': 'GitHub'},
              [ico.github],
            ),
            a(classes: 'btn btn--primary', href: '#start', [Component.text('Get started')]),
          ]),
        ]),
      ],
    );
  }
}

class SiteFooter extends StatelessComponent {
  const SiteFooter();

  @override
  Component build(BuildContext context) {
    return footer(classes: 'ftr', [
      div(classes: 'shell ftr__inner', [
        div(classes: 'ftr__brand', [
          img(src: '/images/logo.svg', alt: ''),
          span([Component.text('Revali — MIT licensed')]),
        ]),
        nav(classes: 'ftr__links', [
          a(href: _docs, [Component.text('Documentation')]),
          a(href: '$_docs/revali/getting-started/installation', [
            Component.text('Getting started'),
          ]),
          a(href: '$_docs/constructs', [Component.text('Constructs')]),
          a(href: '$_docs/create-constructs', [Component.text('Build a construct')]),
          a(
            href: 'https://pub.dev/packages/revali',
            attributes: {'target': '_blank', 'rel': 'noopener'},
            [Component.text('pub.dev')],
          ),
          a(
            href: _repo,
            attributes: {'target': '_blank', 'rel': 'noopener'},
            [Component.text('GitHub')],
          ),
        ]),
      ]),
    ]);
  }
}
