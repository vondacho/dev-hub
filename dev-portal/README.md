# dev-portal

The web frontend of **dev-hub**, the hub where effective software development
takes place.

Effective software development is connected, contract-first, semi-automated and
agile. It embodies both a UX-first and a test-first attitude, and a
patterns-oriented design. It runs on techniques and rituals that connect the
specialists — end-users, UX designers, domain experts, developers, architects,
quality engineers, product owners, operations engineers — rather than sequencing
them. AI comes last, as a booster and an enabler of automation.

Astro 7, server-rendered (`output: 'server'` + `@astrojs/node` standalone),
Tailwind 4 for the portal's own pages and Starlight for `/doc/*`. The layout,
theme tokens and component structure are deliberately the same as api-hub's
`api-portal` and arch-hub's `arch-portal`, so the three hubs read as one family.

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # → dist/
npm start          # serve the build
```

## Pages

| Route | What it is |
|-------|------------|
| `/` | Home. Testimonials, then the four areas: Documentation, Catalog, MCP, Academy. |
| `/catalog` | The eight subcatalogs: API, C4, Events, Components, Practices, Code design, Testing tools, Stacks. |
| `/catalog/stacks` | The six stacks: iOS, Android, Angular, Spring Boot, Quarkus, EAP. |
| `/catalog/stacks/[slug]` | One stack, answering the same four questions each time. |
| `/academy` | Seven learning paths. Curriculum published, lessons not written. |
| `/doc/*` | Starlight. Overview, Attitudes, Practices, Testing tools, MCP, Code design. |
| `/go/[target]` | Request-time redirect to a neighbouring hub. See below. |
| `/healthz` | `{"status":"UP"}` — probe target for a Helm chart. |

All three panel grids render the same `SectionPanels` component, which takes its
panels as a prop. `Hero` is props-driven for the same reason.

Each panel carries a `status`:

- `live` — the link goes somewhere real
- `soon` — the page exists, the thing it describes does not
- `planned` — a placeholder

## Where the content lives

Panel copy is defined once, in `src/lib/`, because the panel and the page behind
it must not drift:

| File | Feeds |
|------|-------|
| `src/lib/catalog.ts` | `/catalog` |
| `src/lib/stacks.ts` | `/catalog/stacks` and every stack page |
| `src/lib/academy.ts` | `/academy` |
| `src/lib/links.ts` | Every address that is configuration rather than a route |

The home page's four areas are the exception: they are declared inline in
`src/pages/index.astro`, since nothing else reads them.

## Four catalogs link out

API, C4, Events and Components are not rendered here. api-hub already owns the
API catalogue end to end, and arch-hub owns the C4, event and component
catalogues — building a second view over the same sources would only produce a
staler one.

Addresses are read at request time, so changing one takes a restart rather than a
rebuild:

| Variable | Default |
|----------|---------|
| `API_PORTAL_URL` | `http://api-portal.localhost` |
| `ARCH_PORTAL_URL` | `http://arch-portal.localhost` |
| `ARCH_C4_URL` | `http://arch-c4.localhost` |
| `ARCH_EVENTCATALOG_URL` | `http://arch-eventcatalog.localhost` |
| `ARCH_APPMAP_URL` | `http://arch-appmap.localhost` |

```bash
API_PORTAL_URL=https://apis.example.com npm start
```

The defaults are the Traefik ingress hosts each component's `values-local.yaml`
enables on a local cluster.

### Why `/go/`

`/doc/*` is prerendered (Starlight needs it for Pagefind), so a documentation
page that called `apiPortalUrl()` directly would resolve it on the *build*
machine and bake the answer into the image. Prerendered pages therefore link to
`/go/api`, `/go/c4`, `/go/events`, `/go/components` or `/go/arch`, which are
server-rendered and forward with a 302 read from the environment.

The portal's own pages skip the hop: they are server-rendered already, so
`/catalog` links straight out.

## What is real, and what is not

**Real:** the documentation under `/doc/*`, the catalog structure, and the four
external catalogues it links to.

**Not real, and said so on the page:**

- The five **MCP** servers. `/doc/mcp/*` describes what each one would do and
  where its boundary sits — the part worth reviewing before any of it exists.
- The **Academy** lessons. The curriculum is settled; nothing is recorded.
- The six **stack** pages. Each states the intent for its stack, names its
  testing toolchain, and admits the gap in its "Where it stands" block.
- The worked examples behind **Testing tools**. The recommendations are settled
  and the mobile analysis is the point of the section; nothing is running in a
  repository here yet.

The Spring Boot and Quarkus stacks are the best supported, because
`arch-blueprint-java`, `arch-blueprint-kotlin` and `arch-blueprint-quarkus`
already carry the shape those pages describe.

## Deploying

The chart lives at `../helm/dev-portal/`, with a `deploy.sh` that builds the
image, installs the release into the `dev-hub` namespace, restarts the pods onto
the rebuilt image and runs `helm test`:

```bash
../helm/dev-portal/deploy.sh
```

See [`../helm/README.md`](../helm/README.md).

## Not included

Contact addresses in `SiteFooter.astro` are placeholders on the reserved
`example.org` domain. Replace them, or drop the column, before this goes
anywhere public.
