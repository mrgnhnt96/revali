/// Routes that used to be pages, and where their content lives now.
///
/// GitHub Pages cannot send a real 301, so `tool/build_redirects.dart` writes a
/// stub `index.html` at each old route after `jaspr build`: a meta refresh, a
/// `rel=canonical` naming the target, and `noindex`. That keeps links from
/// search results, blog posts and older `revali create` templates working after
/// a page is merged away.
///
/// Add an entry whenever a page is deleted or merged. `test/redirects_test.dart`
/// checks that no key is still a live page, that every target is one, and that
/// every `#anchor` exists in the built HTML.
library;

const Map<String, String> redirects = {
  // Getting Started, consolidated into one path.
  '/revali/getting-started/hot-reload': '/revali/getting-started/run-the-server#hot-reload',
  '/revali/getting-started/debug-server': '/revali/getting-started/run-the-server#debugging',
  '/constructs/revali_server/getting-started/installation': '/revali/getting-started/installation',
  '/constructs/revali_server/getting-started/create-your-first-endpoint':
      '/revali/getting-started/create-your-first-endpoint',
  '/constructs/revali_server/getting-started/run-the-server':
      '/revali/getting-started/run-the-server',
  '/constructs/revali_server/getting-started/cli': '/revali/cli/create',

  // Revali Server reference.
  '/constructs/revali_server/core/implied_binding':
      '/constructs/revali_server/core/binding#implied-binding',
  '/constructs/revali_server/request/headers': '/constructs/revali_server/request#headers',
  '/constructs/revali_server/response/body': '/constructs/revali_server/response',
  '/constructs/revali_server/lifecycle-components/advanced/combine-components':
      '/constructs/revali_server/lifecycle-components#classic-components',
  '/constructs/revali_server/access-control/pre-flight-requests':
      '/constructs/revali_server/access-control/allow-origins#preflight-requests',
  '/constructs/revali_server/tidbits':
      '/constructs/revali_server/lifecycle-components#registering-components',

  // App configuration and tutorials.
  '/revali/app-configuration/overview': '/revali/app-configuration',
  '/revali/app-configuration/flavors': '/revali/app-configuration/create-an-app#flavors',
  '/revali/app-configuration/request-scoped-dependencies':
      '/revali/app-configuration/configure-dependencies#request-scoped-dependencies',
  '/revali/app-configuration/error-responses':
      '/revali/app-configuration/default-responses#httperror',
  '/revali/tutorials/authentication': '/revali/tutorials/middleware',

  // Revali Client.
  '/constructs/revali_client/getting-started/installation':
      '/constructs/revali_client#installation',
  '/constructs/revali_client/getting-started/configure': '/constructs/revali_client#configuration',
  '/constructs/revali_client/getting-started/storage': '/constructs/revali_client/storage',
  '/constructs/revali_client/getting-started/http-interceptors':
      '/constructs/revali_client/resilience#interceptors',
  '/constructs/revali_client/getting-started/return-types':
      '/constructs/revali_client/generated-code#return-types',

  // Revali Swagger and Revali Docker.
  '/constructs/revali_swagger/getting-started/installation':
      '/constructs/revali_swagger#installation',
  '/constructs/revali_swagger/getting-started/configuration':
      '/constructs/revali_swagger#configuration',
  '/constructs/revali_docker/installation': '/constructs/revali_docker#installation',
  '/constructs/revali_docker/deploy': '/constructs/revali_docker#deploying',

  // Create Constructs.
  '/create-constructs/getting-started/create-package': '/create-constructs/getting-started',
  '/create-constructs/getting-started/install-dependencies': '/create-constructs/getting-started',
  '/create-constructs/getting-started/create-entrypoint': '/create-constructs/getting-started',
  '/create-constructs/getting-started/construct-config': '/create-constructs/getting-started',
  '/create-constructs/getting-started/add-as-dependency': '/create-constructs/getting-started',
  '/create-constructs/getting-started/run-new-construct': '/create-constructs/getting-started',
  '/create-constructs/core/generic-construct':
      '/create-constructs/core/build-construct#generic-vs-build-constructs',
};
