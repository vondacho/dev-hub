/**
 * Addresses of the neighbouring hubs.
 *
 * Read at call time rather than at module load, matching arch-portal's copy of
 * this file: a chart injects the value as an env var, so it only exists in the
 * running container, while `import.meta.env` covers the dev server reading a
 * .env file.
 *
 * The defaults are the Traefik ingress hosts each component's
 * `values-local.yaml` enables on a local cluster.
 *
 * These are **browser-facing links, not in-cluster calls**: the visitor's
 * browser resolves them, so an in-cluster address like http://arch-c4:8080
 * would be wrong even though this portal is server-rendered.
 *
 * None of them may be called from a prerendered page — see src/pages/go/.
 */

/** api-hub's portal: the API catalogue, its scorecards and its registry. */
export function apiPortalUrl(): string {
  return (
    process.env.API_PORTAL_URL ??
    import.meta.env.API_PORTAL_URL ??
    'http://api-portal.localhost'
  );
}

/** arch-hub's portal: the architecture landscapes this catalogue borrows from. */
export function archPortalUrl(): string {
  return (
    process.env.ARCH_PORTAL_URL ??
    import.meta.env.ARCH_PORTAL_URL ??
    'http://arch-portal.localhost'
  );
}

/** The C4 model site built by arch-hub's `arch-c4` module. */
export function archC4Url(): string {
  return (
    process.env.ARCH_C4_URL ?? import.meta.env.ARCH_C4_URL ?? 'http://arch-c4.localhost'
  );
}

/** The EventCatalog site built by arch-hub's `arch-eventcatalog` module. */
export function archEventcatalogUrl(): string {
  return (
    process.env.ARCH_EVENTCATALOG_URL ??
    import.meta.env.ARCH_EVENTCATALOG_URL ??
    'http://arch-eventcatalog.localhost'
  );
}

/** The AppMap traces published by arch-hub's `arch-appmap` module. */
export function archAppmapUrl(): string {
  return (
    process.env.ARCH_APPMAP_URL ??
    import.meta.env.ARCH_APPMAP_URL ??
    'http://arch-appmap.localhost'
  );
}
