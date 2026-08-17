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
  // The stacks used to be portal pages under /catalog/stacks. They are now a
  // Starlight section, so the Catalog panel points into /doc/* like Practices,
  // Code design and Testing tools already do, and src/lib/stacks.ts is gone —
  // the content has exactly one home again.
  //
  // 301 rather than the 302 used by /go/*: those targets are configuration and
  // move between environments, while these two routes have moved permanently.
  redirects: {
    '/catalog/stacks': '/doc/stacks/',
    '/catalog/stacks/[slug]': '/doc/stacks/[slug]/',
  },
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
      // Starlight's own theme plus one file of additions. It is not the portal's
      // global.css: that one imports Tailwind, whose preflight would reset the
      // base styles Starlight relies on.
      customCss: ['./src/styles/docs.css'],
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
        // The synthesis page: it introduces the two questions every activity
        // answers and connects the artefacts from inception to the cluster, so
        // it sits directly under the Overview rather than inside a section.
        { label: 'The process', link: '/doc/process/' },
        {
          label: 'Attitudes',
          items: [
            { label: 'Overview', link: '/doc/attitudes/' },
            { label: 'Test-first', link: '/doc/attitudes/test-first/' },
            { label: 'User-first', link: '/doc/attitudes/user-first/' },
          ],
        },
        {
          // Ordered as a feature passes through them, matching the table on
          // /doc/practices/ — the two orders used to disagree, and three new
          // pages had nowhere coherent to be inserted.
          label: 'Practices',
          items: [
            { label: 'Overview', link: '/doc/practices/' },
            { label: 'Event storming', link: '/doc/practices/event-storming/' },
            // Straight after event storming: that workshop finds the seams,
            // this is what naming them and keeping the language intact is
            // called. Its tactical half is a pattern catalogue and lives under
            // Code design, not here.
            { label: 'Domain-Driven Design', link: '/doc/practices/ddd/' },
            { label: 'Story mapping', link: '/doc/practices/story-mapping/' },
            { label: 'Three amigos', link: '/doc/practices/three-amigos/' },
            { label: 'Example mapping', link: '/doc/practices/example-mapping/' },
            // Between the two mapping workshops and ticket emission on purpose:
            // the file exists before a ticket is generated from it, and both
            // workshops feed it.
            { label: 'Digital artefacts', link: '/doc/practices/digital-artefacts/' },
            { label: 'From examples to tickets', link: '/doc/practices/story-tickets/' },
            { label: 'Grooming and estimation', link: '/doc/practices/grooming/' },
            { label: 'BDD', link: '/doc/practices/bdd/' },
            { label: 'ATDD', link: '/doc/practices/atdd/' },
            { label: 'API-first', link: '/doc/practices/api-first/' },
            { label: 'Contract-first', link: '/doc/practices/contract-first/' },
            { label: 'All-in-one testing', link: '/doc/practices/all-in-one-testing/' },
          ],
        },
        {
          // Where the general advice has to name a framework. Migrated from
          // /catalog/stacks; the old routes redirect here.
          label: 'Stacks',
          items: [
            { label: 'Overview', link: '/doc/stacks/' },
            { label: 'iOS', link: '/doc/stacks/ios/' },
            { label: 'Android', link: '/doc/stacks/android/' },
            { label: 'Angular', link: '/doc/stacks/angular/' },
            { label: 'Spring Boot', link: '/doc/stacks/spring-boot/' },
            { label: 'Quarkus', link: '/doc/stacks/quarkus/' },
            { label: 'EAP', link: '/doc/stacks/eap/' },
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
            // The tactical half of the DDD practice. It is a pattern catalogue
            // consumed while the code is written, so it belongs beside the
            // other four rather than under Practices with its strategic half.
            { label: 'Tactical DDD patterns', link: '/doc/code-design/tactical-ddd-patterns/' },
            { label: 'Architecture patterns', link: '/doc/code-design/architecture-patterns/' },
            { label: 'Integration patterns', link: '/doc/code-design/integration-patterns/' },
            { label: 'Use case patterns', link: '/doc/code-design/usecase-patterns/' },
          ],
        },
      ],
    }),
  ],
});
