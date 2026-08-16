/**
 * The subcatalogs, defined once.
 *
 * A "catalog" here is anything a developer looks *up* rather than reads through:
 * a contract, a diagram, a message schema, a running component, a named practice,
 * a pattern, a stack blueprint. The Catalog page is the index over all seven.
 *
 * Three kinds of destination, and the distinction matters more than it looks:
 *
 *   external — the catalogue already exists in a neighbouring hub. API lives in
 *              api-hub; C4, Events and Components live in arch-hub. Rebuilding
 *              any of them here would only produce a staler second view over the
 *              same source, so the panel links out. Addresses come from
 *              src/lib/links.ts and are resolved per request.
 *   docs     — the catalogue is prose, so it is a Starlight section under /doc/*.
 *   internal — the catalogue is rendered by this portal (Stacks, which needs a
 *              page per stack).
 *
 * `status` is what is actually reachable behind the link, not how finished the
 * subject is. See SectionPanels for the three values.
 */

import { apiPortalUrl, archAppmapUrl, archC4Url, archEventcatalogUrl } from './links';

/*
 * Spelled out rather than imported from SectionPanels.astro: a `.ts` module that
 * imports a type from a `.astro` one type-checks only through Astro's generated
 * shims, and this file has no other reason to know a component exists. The union
 * is structurally identical, so the panels still assign cleanly.
 */
type PanelStatus = 'live' | 'soon' | 'planned';

export interface Subcatalog {
	/** Stable identity; also the URL segment for internal ones. */
	slug: string;
	title: string;
	/** The one question this catalogue answers that the others cannot. */
	question: string;
	/** Panel blurb. */
	description: string;
	/** A single SVG path `d`, stroked. Multiple subpaths are fine. */
	icon: string;
	/** Where the panel goes. A function when the address is configuration. */
	href: string | (() => string);
	/** Panel call to action. */
	cta: string;
	status: PanelStatus;
	/** True for a link that leaves the portal, so it is marked and opens safely. */
	external?: boolean;
}

export const subcatalogs: readonly Subcatalog[] = [
	{
		slug: 'api',
		title: 'API',
		question: 'What is exposed, under what contract, and how good is it?',
		description:
			'Every registered contract with its scorecard and revision history. Contract-first has to be checkable to mean anything, and this is where it is checked.',
		icon: 'M10.5 13.5a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1.7 1.7m-1.3 3a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1.7-1.7',
		href: apiPortalUrl,
		cta: 'Open the API catalogue',
		status: 'live',
		external: true,
	},
	{
		slug: 'c4',
		title: 'C4',
		question: 'How is the software structured, at four zoom levels?',
		description:
			'Context, container and component diagrams generated from one model, so the four zoom levels cannot contradict each other — or the code they describe.',
		icon: 'M4 4h7v7H4V4Zm9 0h7v7h-7V4ZM4 13h7v7H4v-7Zm9 0h7v7h-7v-7Z',
		href: archC4Url,
		cta: 'Open the C4 model',
		status: 'live',
		external: true,
	},
	{
		slug: 'events',
		title: 'Events',
		question: 'What crosses the boundaries, and who is listening?',
		description:
			'The messages that cross service boundaries — who publishes what, who consumes it, and which schema version is in flight right now.',
		icon: 'M13 3 4.5 13.5H11L10 21l8.5-10.5H12L13 3Z',
		href: archEventcatalogUrl,
		cta: 'Open the event catalogue',
		status: 'live',
		external: true,
	},
	{
		slug: 'components',
		title: 'Components',
		question: 'What is deployed, and how did a use case actually run?',
		description:
			'Every deployed component, and for each one the call sequence of a main use case as it really executed — recorded from a run, not drawn from memory.',
		icon: 'M4 4h6v6H4V4Zm10 10h6v6h-6v-6ZM7 10v4.5a2 2 0 0 0 2 2h5',
		href: archAppmapUrl,
		cta: 'Open the component catalogue',
		status: 'live',
		external: true,
	},
	{
		slug: 'practices',
		title: 'Practices',
		question: 'Which rituals connect the specialists, and how are they run?',
		description:
			'The eight practices that keep a team connected: BDD, example mapping, three amigos, event storming, ATDD, API-first, contract-first and all-in-one testing.',
		icon: 'M8 7.5a3 3 0 1 1 0-.1ZM3 20v-1a4 4 0 0 1 4-4h2a4 4 0 0 1 4 4v1m3-13.5a3 3 0 1 1 0-.1ZM14 20v-1a4 4 0 0 1 4-4h.5a3 3 0 0 1 3 3v2',
		href: '/doc/practices/',
		cta: 'Read the practices',
		status: 'live',
	},
	{
		slug: 'code-design',
		title: 'Code design',
		question: 'What shape should this code take, and why that one?',
		description:
			'The pattern vocabulary a design conversation runs on: GoF, architecture, integration and use case patterns — each with the forces that make it the right answer.',
		icon: 'M9 5 4 12l5 7m6-14 5 7-5 7M13.5 4 10.5 20',
		href: '/doc/code-design/',
		cta: 'Read the patterns',
		status: 'live',
	},
	{
		slug: 'testing-tools',
		title: 'Testing tools',
		question: 'What actually enforces contract-first, API-first and ATDD?',
		description:
			'The tools that turn three practices into something a build can fail on: Microcks for contract-driven API mocking and conformance, Cucumber for executable specifications, Playwright for the browser.',
		icon: 'M9 3h6M10 3v6.2L4.9 17.9A2 2 0 0 0 6.6 21h10.8a2 2 0 0 0 1.7-3.1L14 9.2V3M7.6 14h8.8',
		href: '/doc/testing-tools/',
		cta: 'Read the tooling',
		status: 'live',
	},
	{
		slug: 'stacks',
		title: 'Stacks',
		question: 'How does all of this land on the technology we actually use?',
		description:
			'The same practices and patterns expressed per stack — iOS, Android, Angular, Spring Boot, Quarkus and EAP — because advice that never names a framework is advice nobody can follow on Monday.',
		icon: 'm12 3 9 4.5-9 4.5-9-4.5L12 3Zm9 9-9 4.5L3 12m18 4.5L12 21l-9-4.5',
		href: '/catalog/stacks',
		cta: 'Browse the stacks',
		status: 'live',
	},
] as const;
