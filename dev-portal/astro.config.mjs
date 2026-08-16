// @ts-check
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  // Server-rendered, matching api-portal and arch-portal. Nothing here reads a
  // backend yet, but the Catalog panels front the neighbouring hubs (api-hub's
  // registry, arch-hub's arch-c4, arch-eventcatalog and arch-appmap) and their
  // addresses are configuration — they have to be resolved per request rather
  // than baked into the image at build time.
  output: 'server',
  adapter: node({ mode: 'standalone' }),
  // Tailwind 4 is a Vite plugin, not an Astro integration. src/styles/global.css
  // is imported only by the portal's own Layout, so Tailwind's preflight never
  // reaches the Starlight pages under /doc/* — the two themes stay separate and
  // no Starlight/Tailwind compatibility shim is needed.
  vite: { plugins: [tailwindcss()] },
  integrations: [
    starlight({
      title: 'Documentation',
      // Documentation is prose: it has no reason to be rendered per request,
      // and Pagefind builds its index from the emitted HTML — Starlight
      // refuses to enable search when prerendering is off. Only the Starlight
      // routes are affected; everything else stays on-demand.
      prerender: true,
      // Content lives under src/content/docs/doc/, so Starlight owns /doc/*
      // and leaves the site root to the portal's own home page.
      //
      // Three sections, and each one is the target of a panel elsewhere in the
      // portal: Practices is where the Catalog's Practices panel lands, MCP is
      // where the home page's MCP panel lands, and Code design is where the
      // Catalog's Code design panel lands. Renaming a section here means
      // changing the href in src/lib/catalog.ts or src/pages/index.astro too.
      sidebar: [
        { label: 'Overview', link: '/doc/' },
        {
          label: 'Attitudes',
          items: [
            { label: 'Overview', link: '/doc/attitudes/' },
            { label: 'Test-first', link: '/doc/attitudes/test-first/' },
            { label: 'User-first', link: '/doc/attitudes/user-first/' },
          ],
        },
        {
          label: 'Practices',
          items: [
            { label: 'Overview', link: '/doc/practices/' },
            { label: 'BDD', link: '/doc/practices/bdd/' },
            { label: 'Example mapping', link: '/doc/practices/example-mapping/' },
            { label: 'Three amigos', link: '/doc/practices/three-amigos/' },
            { label: 'Event storming', link: '/doc/practices/event-storming/' },
            { label: 'ATDD', link: '/doc/practices/atdd/' },
            { label: 'API-first', link: '/doc/practices/api-first/' },
            { label: 'Contract-first', link: '/doc/practices/contract-first/' },
            { label: 'All-in-one testing', link: '/doc/practices/all-in-one-testing/' },
          ],
        },
        {
          label: 'Testing tools',
          items: [
            { label: 'Overview', link: '/doc/testing-tools/' },
            { label: 'Microcks', link: '/doc/testing-tools/microcks/' },
            { label: 'Cucumber', link: '/doc/testing-tools/cucumber/' },
            { label: 'Playwright', link: '/doc/testing-tools/playwright/' },
            { label: 'Mobile testing tools', link: '/doc/testing-tools/mobile/' },
          ],
        },
        {
          label: 'MCP',
          items: [
            { label: 'Overview', link: '/doc/mcp/' },
            { label: 'Code patterns', link: '/doc/mcp/code-patterns/' },
            { label: 'Code scaffolding', link: '/doc/mcp/code-scaffolding/' },
            { label: 'LikeC4 scaffolding', link: '/doc/mcp/likec4-scaffolding/' },
            { label: 'LikeC4 retro-engineering', link: '/doc/mcp/likec4-retro-engineering/' },
            { label: 'Assisted API-design', link: '/doc/mcp/assisted-api-design/' },
          ],
        },
        {
          label: 'Code design',
          items: [
            { label: 'Overview', link: '/doc/code-design/' },
            { label: 'GoF patterns', link: '/doc/code-design/gof-patterns/' },
            { label: 'Architecture patterns', link: '/doc/code-design/architecture-patterns/' },
            { label: 'Integration patterns', link: '/doc/code-design/integration-patterns/' },
            { label: 'Use case patterns', link: '/doc/code-design/usecase-patterns/' },
          ],
        },
      ],
    }),
  ],
});
