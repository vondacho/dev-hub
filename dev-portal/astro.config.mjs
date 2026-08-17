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
      customCss: ['./src/styles/docs.css'],
      sidebar: [
        { label: 'Overview', link: '/doc/' },
        { label: 'The Process', link: '/doc/process/' },
        {
          label: 'Attitudes',
          items: [
            { label: 'Overview', link: '/doc/attitudes/' },
            { label: 'Test-first', link: '/doc/attitudes/test-first/' },
            { label: 'User-first', link: '/doc/attitudes/user-first/' },
            { label: 'Contract-first', link: '/doc/attitudes/contract-first/' },
            { label: 'API-first', link: '/doc/attitudes/api-first/' },
          ],
        },
        {
          label: 'Practices',
          items: [
            { label: 'Overview', link: '/doc/practices/' },
            { label: 'DDD', link: '/doc/practices/ddd/' },
            { label: 'Event storming', link: '/doc/practices/event-storming/' },
            { label: 'Story mapping', link: '/doc/practices/story-mapping/' },
            { label: 'BDD', link: '/doc/practices/bdd/' },
            { label: 'Three amigos', link: '/doc/practices/three-amigos/' },
            { label: 'Example mapping', link: '/doc/practices/example-mapping/' },
            { label: 'Digital artefacts', link: '/doc/practices/digital-artefacts/' },
            { label: 'Ticketing', link: '/doc/practices/story-tickets/' },
            { label: 'Grooming', link: '/doc/practices/grooming/' },
            { label: 'ATDD', link: '/doc/practices/atdd/' },
            { label: 'API-first', link: '/doc/practices/api-first/' },
            { label: 'Contract-first', link: '/doc/practices/contract-first/' },
            { label: 'All-in-one testing', link: '/doc/practices/all-in-one-testing/' },
          ],
        },
        {
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
            { label: 'Mobile', link: '/doc/testing-tools/mobile/' },
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
            { label: 'Tactical DDD patterns', link: '/doc/code-design/tactical-ddd-patterns/' },
            { label: 'Use case patterns', link: '/doc/code-design/usecase-patterns/' },
            { label: 'Integration patterns', link: '/doc/code-design/integration-patterns/' },
          ],
        },
      ],
    }),
  ],
});
