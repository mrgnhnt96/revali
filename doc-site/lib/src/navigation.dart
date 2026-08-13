/// The single source of truth for the docs site's information architecture.
///
/// Consumed by:
/// - `main.server.dart`, for the header section tabs, breadcrumbs and
///   previous/next links.
/// - `components/docs_sidebar.dart`, for the sidebar of the active section.
/// - `components/cards.dart`, for the landing page's section cards.
/// - `tool/build_search_index.dart`, to label search results by section and to
///   assert that every page under `content/` is reachable from the sidebar.
///
/// Keep each section ordered as a reading path: someone who starts at the top
/// and works down should never hit a page that depends on one below it. That
/// ordering is also what makes the prev/next links at the foot of each page
/// meaningful.
///
/// Regroup here rather than moving markdown files — a page's URL comes from its
/// path under `content/`, so moving one breaks every inbound link for the sake
/// of a sidebar heading. Sidebar labels are allowed to be shorter than the
/// page's own title; the title is what search results and the `<h1>` show.
library;

/// Anything that can appear in the sidebar: a link, or a group of them.
sealed class NavEntry {
  const NavEntry();

  /// The group heading, or the link text.
  String get title;
}

/// A single page entry.
final class NavItem extends NavEntry {
  const NavItem(this.title, this.href, {this.summary, this.badge});

  /// Link text. Kept short — the sidebar column is about 17rem.
  @override
  final String title;

  /// Root-absolute route, e.g. `/revali/cli/dev`.
  final String href;

  /// One-line description shown on the landing page's cards.
  ///
  /// Falls back to the page's own front matter `description` when null.
  final String? summary;

  /// Optional short label rendered next to the link, e.g. `new`.
  final String? badge;
}

/// A collapsible group of entries in the sidebar.
///
/// Groups nest one level inside a section (e.g. Constructs → Revali Server →
/// Getting Started); anything deeper was flattened during the migration,
/// because a third `<details>` level indents the actual links off the edge of a
/// 17rem column.
final class NavGroup extends NavEntry {
  const NavGroup(this.title, {required this.entries, this.icon, this.summary});

  @override
  final String title;

  /// Inline SVG markup rendered before [title]. See [NavIcons].
  ///
  /// Only top-level groups carry one; nested groups are indented instead, so an
  /// icon there reads as clutter.
  final String? icon;

  /// One-line description of what the group covers.
  final String? summary;

  final List<NavEntry> entries;
}

/// One tab in the header, with its own sidebar.
///
/// Three sections rather than one combined sidebar because these are three
/// different jobs — using Revali, using a construct, and writing a construct —
/// and a reader is only ever doing one of them. This is also what the
/// Docusaurus site did, with three `docSidebar` navbar items.
final class NavSection {
  const NavSection({
    required this.id,
    required this.title,
    required this.href,
    required this.icon,
    required this.summary,
    required this.entries,
  });

  /// Stable identifier, also the first URL segment (`revali`, `constructs`,
  /// `create-constructs`). [sectionFor] matches on it.
  final String id;

  /// Tab label in the header.
  final String title;

  /// Where the tab points — always the section's own overview page.
  final String href;

  /// Inline SVG markup for the landing page card. See [NavIcons].
  final String icon;

  /// One line, shown on the landing page card and as the tab's title text.
  final String summary;

  final List<NavEntry> entries;
}

/// The three top-level sections, in the order they appear in the header.
const List<NavSection> sections = [_revali, _constructs, _createConstructs];

const _revali = NavSection(
  id: 'revali',
  title: 'Revali',
  href: '/revali',
  icon: NavIcons.rocket,
  summary: 'Install the framework, configure your app, and run the CLI.',
  entries: [
    NavItem(
      'Overview',
      '/revali',
      summary: 'What Revali is, and how annotations become a running server.',
    ),
    NavGroup(
      'Getting Started',
      icon: NavIcons.rocket,
      summary: 'From an empty directory to a server answering requests.',
      entries: [
        NavItem(
          'Installation',
          '/revali/getting-started/installation',
          summary: 'Install the Revali CLI and add it to a Dart project.',
        ),
        NavItem(
          'Create Your First Endpoint',
          '/revali/getting-started/create-your-first-endpoint',
          summary: 'Write a controller and get a route out of it.',
        ),
        NavItem(
          'Run the Server',
          '/revali/getting-started/run-the-server',
          summary: '`revali dev`, and what it does on the way up.',
        ),
        NavItem(
          'Debug the Server',
          '/revali/getting-started/debug-server',
          summary: 'Attach a debugger and set breakpoints in your handlers.',
        ),
        NavItem(
          'Hot Reload',
          '/revali/getting-started/hot-reload',
          summary: 'Edit a handler and see it live without a restart.',
        ),
      ],
    ),
    NavItem(
      'Testing',
      '/revali/testing',
      summary: 'Drive your server in-process with `revali_test`.',
    ),
    NavGroup(
      'App Configuration',
      icon: NavIcons.sliders,
      summary: 'The `AppConfig` your server boots from.',
      entries: [
        NavItem(
          'Overview',
          '/revali/app-configuration',
          summary: 'Everything an app can declare, in one place.',
        ),
        NavItem(
          'Create an App',
          '/revali/app-configuration/create-an-app',
          summary: 'Declare the `@App()` that owns host, port and prefix.',
        ),
        NavItem(
          'Configure Dependencies',
          '/revali/app-configuration/configure-dependencies',
          summary: 'Register services once and inject them anywhere.',
        ),
        NavItem(
          'Request-Scoped Dependencies',
          '/revali/app-configuration/request-scoped-dependencies',
          summary: 'One instance per request, disposed when it ends.',
        ),
        NavItem(
          'Flavors',
          '/revali/app-configuration/flavors',
          summary: 'One codebase, several environments.',
        ),
        NavItem(
          'Default Responses',
          '/revali/app-configuration/default-responses',
          summary: 'Set the body Revali returns for 404s and 500s.',
        ),
        NavItem(
          'Environment Variables',
          '/revali/app-configuration/env-vars',
          summary: 'Read configuration from the environment, type-safely.',
        ),
        NavItem(
          'HTTPS in Development',
          '/revali/app-configuration/https',
          summary: 'Serve TLS locally without a proxy in front.',
        ),
        NavItem(
          'Graceful Shutdown',
          '/revali/app-configuration/graceful-shutdown',
          summary: 'Finish in-flight requests before the process exits.',
        ),
      ],
    ),
    NavGroup(
      'CLI',
      icon: NavIcons.terminal,
      summary: 'The commands, and the `revali.yaml` they read.',
      entries: [
        NavItem(
          'revali dev',
          '/revali/cli/dev',
          summary: 'Run the server with code generation and hot reload.',
        ),
        NavItem(
          'revali build',
          '/revali/cli/build',
          summary: 'Produce the compiled server for deployment.',
        ),
        NavItem(
          'revali routes',
          '/revali/cli/routes',
          summary: 'Print every route the generator found.',
        ),
        NavItem(
          'revali doctor',
          '/revali/cli/doctor',
          summary: 'Check the project for the things that usually go wrong.',
        ),
        NavItem(
          'revali ai',
          '/revali/cli/ai',
          summary: 'Install a Revali reference file for your AI coding assistant.',
        ),
        // `revali.yaml` is what every command above reads, so it belongs beside
        // them rather than in App Configuration, which is about `AppConfig`.
        NavItem(
          'revali.yaml',
          '/revali/revali-configuration',
          summary: 'Enable, disable and configure constructs.',
        ),
      ],
    ),
    NavGroup(
      'Tutorials',
      icon: NavIcons.book,
      summary: 'Longer walkthroughs that put the pieces together.',
      entries: [
        NavItem(
          'Middleware',
          '/revali/tutorials/middleware',
          summary: 'Run code before and after every request.',
        ),
        NavItem(
          'Error Handling',
          '/revali/tutorials/error-handling',
          summary: 'Turn thrown exceptions into the responses you meant.',
        ),
        NavItem(
          'Authentication',
          '/revali/tutorials/authentication',
          summary: 'Guard endpoints and identify the caller.',
        ),
        NavItem(
          'Database Integration',
          '/revali/tutorials/database-integration',
          summary: 'Wire a database in through dependency injection.',
        ),
      ],
    ),
  ],
);

const _constructs = NavSection(
  id: 'constructs',
  title: 'Constructs',
  href: '/constructs',
  icon: NavIcons.blocks,
  summary: 'The packages that generate your server, client, docs and Dockerfile.',
  entries: [
    NavItem(
      'Overview',
      '/constructs',
      summary: 'What a construct is, and which ones ship with Revali.',
    ),
    NavGroup(
      'Revali Server',
      icon: NavIcons.server,
      summary: 'The construct that turns annotated classes into an HTTP server.',
      entries: [
        NavItem('Overview', '/constructs/revali_server'),
        NavGroup(
          'Getting Started',
          entries: [
            NavItem('Installation', '/constructs/revali_server/getting-started/installation'),
            NavItem('CLI', '/constructs/revali_server/getting-started/cli'),
            NavItem(
              'Create Your First Endpoint',
              '/constructs/revali_server/getting-started/create-your-first-endpoint',
            ),
            NavItem('Run the Server', '/constructs/revali_server/getting-started/run-the-server'),
          ],
        ),
        NavGroup(
          'Core',
          entries: [
            NavItem('Controllers', '/constructs/revali_server/core/controllers'),
            NavItem('HTTP Methods', '/constructs/revali_server/core/methods'),
            NavItem('Binding', '/constructs/revali_server/core/binding'),
            NavItem('Implied Binding', '/constructs/revali_server/core/implied_binding'),
            NavItem('Pipes', '/constructs/revali_server/core/pipes'),
          ],
        ),
        NavGroup(
          'Request',
          entries: [
            NavItem('Overview', '/constructs/revali_server/request'),
            NavItem('Body', '/constructs/revali_server/request/body'),
            NavItem('Headers', '/constructs/revali_server/request/headers'),
            NavItem('Client IP', '/constructs/revali_server/request/client-ip'),
            NavItem('Redirect', '/constructs/revali_server/request/redirect'),
            NavItem('HEAD Requests', '/constructs/revali_server/request/head-requests'),
            NavItem('OPTIONS Requests', '/constructs/revali_server/request/options-requests'),
          ],
        ),
        NavGroup(
          'Response',
          entries: [
            NavItem('Overview', '/constructs/revali_server/response'),
            NavItem('Body', '/constructs/revali_server/response/body'),
            NavItem('Headers', '/constructs/revali_server/response/headers'),
            NavItem('Status Code', '/constructs/revali_server/response/status-code'),
            NavItem('Cookies', '/constructs/revali_server/response/cookies'),
            NavItem('Public Files', '/constructs/revali_server/response/public'),
            NavItem('Server-Sent Events', '/constructs/revali_server/response/server-sent-events'),
            NavItem('WebSockets', '/constructs/revali_server/response/websockets'),
          ],
        ),
        NavGroup(
          'Context',
          entries: [
            NavItem('Overview', '/constructs/revali_server/context'),
            NavItem('Data Sharing', '/constructs/revali_server/context/data-sharing'),
            NavItem('Meta', '/constructs/revali_server/context/meta'),
            NavItem('Reflect', '/constructs/revali_server/context/reflect'),
          ],
        ),
        // The Docusaurus tree had these seven under a further "Advanced"
        // category. Flattened: they are the components most readers come here
        // for, and a third nesting level pushed the links off the column.
        NavGroup(
          'Lifecycle Components',
          entries: [
            NavItem('Overview', '/constructs/revali_server/lifecycle-components'),
            NavItem('Components', '/constructs/revali_server/lifecycle-components/components'),
            NavItem('Observer', '/constructs/revali_server/lifecycle-components/observer'),
            NavItem(
              'Request Wrapper',
              '/constructs/revali_server/lifecycle-components/advanced/wrapper',
            ),
            NavItem(
              'Middleware',
              '/constructs/revali_server/lifecycle-components/advanced/middleware',
            ),
            NavItem('Guards', '/constructs/revali_server/lifecycle-components/advanced/guards'),
            NavItem(
              'Interceptors',
              '/constructs/revali_server/lifecycle-components/advanced/interceptors',
            ),
            NavItem(
              'Combine Components',
              '/constructs/revali_server/lifecycle-components/advanced/combine-components',
            ),
            NavItem(
              'Exception Catchers',
              '/constructs/revali_server/lifecycle-components/advanced/exception-catchers',
            ),
            NavItem(
              'Response Handler',
              '/constructs/revali_server/lifecycle-components/advanced/response-handler',
            ),
          ],
        ),
        NavGroup(
          'Access Control',
          entries: [
            NavItem('Allow Origins', '/constructs/revali_server/access-control/allow-origins'),
            NavItem('Expect Headers', '/constructs/revali_server/access-control/expect-headers'),
            NavItem('Prevent Headers', '/constructs/revali_server/access-control/prevent-headers'),
            NavItem(
              'Pre-flight Requests',
              '/constructs/revali_server/access-control/pre-flight-requests',
            ),
          ],
        ),
        NavItem('Tid Bits', '/constructs/revali_server/tidbits'),
      ],
    ),
    NavGroup(
      'Revali Client',
      icon: NavIcons.plug,
      summary: 'A type-safe Dart client generated from the same annotations.',
      entries: [
        NavItem('Overview', '/constructs/revali_client'),
        NavGroup(
          'Getting Started',
          entries: [
            NavItem('Installation', '/constructs/revali_client/getting-started/installation'),
            NavItem('Configure', '/constructs/revali_client/getting-started/configure'),
            NavItem('Storage', '/constructs/revali_client/getting-started/storage'),
            NavItem('Interceptors', '/constructs/revali_client/getting-started/http-interceptors'),
            NavItem('Return Types', '/constructs/revali_client/getting-started/return-types'),
          ],
        ),
        NavItem('Generated Code', '/constructs/revali_client/generated-code'),
        NavItem('get_it Integration', '/constructs/revali_client/integrations/get_it'),
      ],
    ),
    NavGroup(
      'Revali Swagger',
      icon: NavIcons.fileText,
      summary: 'An OpenAPI document, inferred from your types.',
      entries: [
        NavItem('Overview', '/constructs/revali_swagger'),
        NavItem('Installation', '/constructs/revali_swagger/getting-started/installation'),
        NavItem('Configuration', '/constructs/revali_swagger/getting-started/configuration'),
        NavItem('Annotations', '/constructs/revali_swagger/annotations'),
        NavItem('Type Inference', '/constructs/revali_swagger/type-inference'),
      ],
    ),
    NavGroup(
      'Revali Docker',
      icon: NavIcons.container,
      summary: 'A Dockerfile for your server, and somewhere to run it.',
      entries: [
        NavItem('Overview', '/constructs/revali_docker'),
        NavItem('Installation', '/constructs/revali_docker/installation'),
        NavItem('Deploying', '/constructs/revali_docker/deploy'),
        NavItem('Fly.io', '/constructs/revali_docker/deploy/fly-io'),
      ],
    ),
  ],
);

const _createConstructs = NavSection(
  id: 'create-constructs',
  title: 'Create Constructs',
  href: '/create-constructs',
  icon: NavIcons.wrench,
  summary: 'Write your own code generator against the Revali pipeline.',
  entries: [
    NavItem(
      'Overview',
      '/create-constructs',
      summary: 'What a construct can generate, and when to write one.',
    ),
    NavGroup(
      'Getting Started',
      icon: NavIcons.rocket,
      summary: 'A construct package that Revali will actually run.',
      entries: [
        NavItem('Create Construct Package', '/create-constructs/getting-started/create-package'),
        NavItem('Install Dependencies', '/create-constructs/getting-started/install-dependencies'),
        NavItem('Create Entrypoint', '/create-constructs/getting-started/create-entrypoint'),
        NavItem('Construct Config', '/create-constructs/getting-started/construct-config'),
        NavItem('Add as Dependency', '/create-constructs/getting-started/add-as-dependency'),
        NavItem('Run New Construct', '/create-constructs/getting-started/run-new-construct'),
      ],
    ),
    NavGroup(
      'Core',
      icon: NavIcons.blocks,
      summary: 'The lifecycle a construct hooks into, and what it can emit.',
      entries: [
        NavItem('Construct Lifecycle', '/create-constructs/core/construct-lifecycle'),
        NavItem('Build Construct', '/create-constructs/core/build-construct'),
        NavItem('Generic Construct', '/create-constructs/core/generic-construct'),
      ],
    ),
    NavItem(
      'Tips and Tricks',
      '/create-constructs/tips-and-tricks',
      summary: 'Debugging a construct, and the shortcuts worth knowing.',
    ),
  ],
);

/// Pages that intentionally live outside the sidebar.
///
/// `tool/build_search_index.dart` checks every content page against [sections]
/// and this set, so a new page that nobody linked fails the build rather than
/// quietly becoming unreachable.
const Set<String> unlistedRoutes = <String>{'/'};

/// Every navigable page across every section, flattened into reading order.
List<NavItem> get flatNavigation => [for (final section in sections) ...itemsOf(section.entries)];

/// Depth-first flatten of [entries] into the order they are read in.
List<NavItem> itemsOf(List<NavEntry> entries) => [
  for (final entry in entries)
    ...switch (entry) {
      NavItem() => [entry],
      NavGroup(:final entries) => itemsOf(entries),
    },
];

/// The section that owns [href].
///
/// Matched on the first path segment rather than by searching [sections], so
/// that a page reached from search still shows its section's sidebar even if
/// something goes unlisted.
NavSection? sectionFor(String href) {
  final segment = href.split('/').where((part) => part.isNotEmpty).firstOrNull;
  if (segment == null) return null;
  for (final section in sections) {
    if (section.id == segment) return section;
  }
  return null;
}

/// The innermost group containing [href], or null for a section-level page.
///
/// Used for the breadcrumb, which shows `Section / Group`.
NavGroup? groupFor(String href) {
  NavGroup? search(List<NavEntry> entries, NavGroup? enclosing) {
    for (final entry in entries) {
      switch (entry) {
        case NavItem() when entry.href == href:
          return enclosing;
        case NavItem():
          continue;
        case NavGroup():
          final found = search(entry.entries, entry);
          if (found != null) return found;
      }
    }
    return null;
  }

  for (final section in sections) {
    final found = search(section.entries, null);
    if (found != null) return found;
  }
  return null;
}

/// The nav entry for [href], or null when the page is unlisted.
NavItem? itemFor(String href) {
  for (final item in flatNavigation) {
    if (item.href == href) return item;
  }
  return null;
}

/// The previous and next pages in reading order, for the page footer.
///
/// Deliberately walks across section boundaries: the sections are themselves
/// ordered as a reading path, so the last Revali page leads into Constructs.
({NavItem? previous, NavItem? next}) neighborsOf(String href) {
  final flat = flatNavigation;
  final index = flat.indexWhere((item) => item.href == href);
  if (index < 0) return (previous: null, next: null);
  return (
    previous: index > 0 ? flat[index - 1] : null,
    next: index < flat.length - 1 ? flat[index + 1] : null,
  );
}

/// Inline SVG icons for [NavSection]s and top-level [NavGroup]s.
///
/// Lucide-style 24x24 strokes, so they inherit `currentColor` and line weight
/// from the surrounding text rather than needing their own colors.
abstract final class NavIcons {
  static const String _open =
      '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';

  static const rocket =
      '$_open<path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/>'
      '<path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/>'
      '<path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/></svg>';

  static const sliders =
      '$_open<line x1="4" x2="4" y1="21" y2="14"/><line x1="4" x2="4" y1="10" y2="3"/>'
      '<line x1="12" x2="12" y1="21" y2="12"/><line x1="12" x2="12" y1="8" y2="3"/>'
      '<line x1="20" x2="20" y1="21" y2="16"/><line x1="20" x2="20" y1="12" y2="3"/>'
      '<line x1="2" x2="6" y1="14" y2="14"/><line x1="10" x2="14" y1="8" y2="8"/>'
      '<line x1="18" x2="22" y1="16" y2="16"/></svg>';

  static const terminal =
      '$_open<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/></svg>';

  static const book =
      '$_open<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H19a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6.5a1 1 0 0 1 0-5H20"/></svg>';

  static const blocks =
      '$_open<rect width="7" height="7" x="14" y="3" rx="1"/>'
      '<path d="M10 21V8a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-5a1 1 0 0 0-1-1H3"/></svg>';

  static const server =
      '$_open<rect width="20" height="8" x="2" y="2" rx="2"/><rect width="20" height="8" x="2" y="14" rx="2"/>'
      '<line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/></svg>';

  static const plug =
      '$_open<path d="M12 22v-5"/><path d="M9 8V2"/><path d="M15 8V2"/>'
      '<path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8Z"/></svg>';

  static const fileText =
      '$_open<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>'
      '<path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/></svg>';

  static const container =
      '$_open<path d="M22 7.7c0-.6-.4-1.2-.8-1.5l-6.3-3.9a1.72 1.72 0 0 0-1.7 0l-10.3 6c-.5.2-.9.8-.9 1.4v6.6c0 .5.4 1.2.8 1.5l6.3 3.9a1.72 1.72 0 0 0 1.7 0l10.3-6c.5-.3.9-1 .9-1.5Z"/>'
      '<path d="M10 21.9V14L2.1 9.1"/><path d="m10 14 11.9-6.9"/><path d="M14 19.8v-8.1"/><path d="M18 17.5V9.4"/></svg>';

  static const wrench =
      '$_open<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>';
}
