import type * as Preset from '@docusaurus/preset-classic';
import type { Config } from '@docusaurus/types';
import { themes as prismThemes } from 'prism-react-renderer';

const config: Config = {
    title: 'Revali',
    tagline: 'A modern, fast, and powerful Dart API framework',
    favicon: 'img/favicon.ico',

    // Set the production url of your site here
    url: 'https://revali.dev',
    // Set the /<baseUrl>/ pathname under which your site is served
    // For GitHub pages deployment, it is often '/<projectName>/'
    baseUrl: '/',

    // GitHub pages deployment config.
    // If you aren't using GitHub pages, you don't need these.
    organizationName: 'Revali', // Usually your GitHub org/user name.
    projectName: 'revali', // Usually your repo name.

    onBrokenLinks: 'throw',
    onBrokenMarkdownLinks: 'warn',
    trailingSlash: false,

    // Even if you don't use internationalization, you can use this field to set
    // useful metadata like html lang. For example, if your site is Chinese, you
    // may want to replace "en" with "zh-Hans".
    i18n: {
        defaultLocale: 'en',
        locales: ['en'],
    },

    presets: [
        [
            'classic',
            {
                docs: {
                    routeBasePath: '/',
                    sidebarPath: './sidebars.ts',
                    // Please change this to your repo.
                    // Remove this to remove the "edit this page" links.
                    editUrl:
                        'https://github.com/mrgnhnt96/revali/tree/main/doc-site',
                },
                blog: false,
                theme: {
                    customCss: './src/css/custom.css',
                },
            } satisfies Preset.Options,
        ],
    ],

    markdown: {
        mermaid: true,
    },

    themes: ['@docusaurus/theme-mermaid'],

    themeConfig: {
        image: 'img/social-card.png',
        docs: {
            sidebar: {
                autoCollapseCategories: true
            }
        },
        mermaid: {
            theme: { light: 'neutral', dark: 'dark' },
        },
        algolia: {
            // The application ID provided by Algolia
            appId: 'FHFKC19XPI',

            // Public API key: it is safe to commit it
            apiKey: '7994a1474e5a79c99f471a0feb837498',

            indexName: 'revali',

            // Optional: see doc section below
            contextualSearch: true,

            // Optional: Specify domains where the navigation should occur through window.location instead on history.push. Useful when our Algolia config crawls multiple documentation sites and we want to navigate with window.location.href to them.
            externalUrlRegex: 'external\\.com|domain\\.com',

            // Optional: Replace parts of the item URLs from Algolia. Useful when using the same search index for multiple deployments using a different baseUrl. You can use regexp or string in the `from` param. For example: localhost:3000 vs myCompany.com/docs
            replaceSearchResultPathname: {
                from: '/docs/', // or as RegExp: /\/docs\//
                to: '/',
            },

            // Optional: Algolia search parameters
            searchParameters: {},

            // Optional: path for search page that enabled by default (`false` to disable it)
            searchPagePath: 'search',

            // Optional: whether the insights feature is enabled or not on Docsearch (`false` by default)
            insights: false,

            //... other Algolia params
        },

        navbar: {
            title: 'Revali',
            logo: {
                alt: 'My Site Logo',
                src: 'img/logo.svg',
            },
            items: [
                {
                    type: 'docSidebar',
                    sidebarId: 'revali',
                    position: 'left',
                    label: 'Docs',
                },
                {
                    type: 'docSidebar',
                    sidebarId: 'constructs',
                    position: 'left',
                    label: 'Constructs',
                },
                {
                    type: 'docSidebar',
                    sidebarId: 'createConstruct',
                    position: 'left',
                    label: 'Create Constructs',
                },
                {
                    href: 'https://github.com/mrgnhnt96/revali',
                    label: 'GitHub',
                    position: 'right',
                },
            ],
        },
        footer: {
            style: 'dark',
            links: [
                {
                    title: 'Docs',
                    items: [
                        {
                            label: 'Revali',
                            to: '/revali',
                        },
                        {
                            label: 'Constructs',
                            to: '/constructs',
                        },
                        {
                            label: 'Create Constructs',
                            to: '/create-constructs',
                        },
                    ],
                },
                // {
                //     title: 'Community',
                //     items: [
                //         {
                //             label: 'Stack Overflow',
                //             href: 'https://stackoverflow.com/questions/tagged/docusaurus',
                //         },
                //         {
                //             label: 'Discord',
                //             href: 'https://discordapp.com/invite/docusaurus',
                //         },
                //         {
                //             label: 'Twitter',
                //             href: 'https://twitter.com/docusaurus',
                //         },
                //     ],
                // },
                {
                    title: 'More',
                    items: [
                        {
                            label: 'GitHub',
                            href: 'https://github.com/mrgnhnt96/revali',
                        },
                    ],
                },
            ],
            copyright: `Copyright © ${new Date().getFullYear()} Revali`,
        },
        prism: {
            theme: prismThemes.github,
            darkTheme: prismThemes.dracula,
            additionalLanguages: ['bash', 'dart', 'docker', 'yaml'],
        },
    } satisfies Preset.ThemeConfig,
};

export default config;
