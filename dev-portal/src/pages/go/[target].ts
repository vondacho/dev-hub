import type { APIRoute } from 'astro';
import {
  apiPortalUrl,
  archAppmapUrl,
  archC4Url,
  archEventcatalogUrl,
  archPortalUrl,
} from '../../lib/links';

/*
 * Redirects to the neighbouring hubs.
 *
 * This exists because the Starlight docs are prerendered (`prerender: true` in
 * astro.config.mjs) — every page under /doc/* is emitted as static HTML at build
 * time. Calling apiPortalUrl() from one of those pages would therefore resolve
 * on the *build* machine and bake its answer into the image, leaving
 * API_PORTAL_URL in the chart silently doing nothing.
 *
 * So a prerendered page links here with a relative URL like /go/api, and this
 * route — server-rendered, like everything outside /doc/* — reads the
 * environment at request time and forwards. Changing an address then takes
 * effect on a restart, with no rebuild.
 *
 * The portal's own pages do NOT go through here: they are server-rendered
 * already, so /catalog resolves the addresses directly and links straight out,
 * which saves the visitor a round trip.
 *
 * 302, not 301: these targets are configuration and move between environments,
 * and a browser that cached a permanent redirect would keep following the old
 * one long after the value changed.
 */
const targets: Record<string, () => string> = {
  api: apiPortalUrl,
  arch: archPortalUrl,
  c4: archC4Url,
  events: archEventcatalogUrl,
  components: archAppmapUrl,
};

export const GET: APIRoute = ({ params }) => {
  const resolve = params.target ? targets[params.target] : undefined;

  if (!resolve) {
    return new Response(null, { status: 404, statusText: 'Not found' });
  }

  return new Response(null, {
    status: 302,
    headers: {
      location: resolve(),
      'cache-control': 'no-store',
    },
  });
};
