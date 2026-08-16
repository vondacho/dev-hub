/**
 * The stacks, defined once.
 *
 * Both /catalog/stacks (the panel grid) and /catalog/stacks/[slug] (the stack
 * pages) read this, so a panel and the page behind it cannot drift apart.
 *
 * A stack page is where the portal stops being general. Everything else here —
 * the practices, the patterns, the contracts — is written to be true regardless
 * of technology, which is exactly what makes it easy to nod at and hard to act
 * on. The stack pages owe the reader the other half: what contract-first means
 * when the contract is an OpenAPI document served by a Spring controller, what
 * test-first means when the test is an XCTest on a SwiftUI view.
 *
 * `covers` is that translation, one card per concern. It is deliberately the
 * same four concerns on every stack — contract, tests, patterns, delivery — so
 * two stacks can be compared rather than merely both described.
 */

/** Structurally identical to SectionPanels' own union — see the note in catalog.ts. */
type PanelStatus = 'live' | 'soon' | 'planned';

export interface Concern {
	title: string;
	body: string;
}

/**
 * One row of the stack's testing toolchain.
 *
 * Named per stack rather than described once in the docs, because "use a
 * contract-driven mock" is advice nobody can act on and "point the app at
 * Microcks, stub locally with MockWebServer" is. The reasoning behind each
 * choice lives in /doc/testing-tools/; this is the answer, not the argument.
 */
export interface Tool {
	/** The job it does, phrased identically across stacks so they compare. */
	role: string;
	/** What to use. */
	name: string;
}

export interface Stack {
	/** URL segment under /catalog/stacks, and the panel's identity. */
	slug: string;
	title: string;
	/** Language and runtime, shown as the page kicker. */
	kicker: string;
	/** The one question this stack page answers. */
	question: string;
	/** Panel blurb. */
	description: string;
	/** A single SVG path `d`, stroked. */
	icon: string;
	/** The four concerns, translated into this stack's terms. */
	covers: readonly Concern[];
	/** The testing toolchain, in the same row order on every stack. */
	tools: readonly Tool[];
	/** A starter repository, when one exists. */
	blueprint?: { label: string; note: string };
	/** The honest state of this page's content. */
	state: string;
	status: PanelStatus;
}

export const stacks: readonly Stack[] = [
	{
		slug: 'ios',
		title: 'iOS',
		kicker: 'Swift · SwiftUI · Xcode',
		question: 'How does effective development look on a platform that ships through review?',
		description:
			'Swift and SwiftUI, where the release cadence is set by someone else — so the feedback you get before submitting is the only feedback that is cheap.',
		icon: 'M8 3h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm2.5 15h3',
		covers: [
			{
				title: 'The contract',
				body: 'The app is a consumer, never a publisher: its backend contracts come from the API catalogue, and the client is generated from them rather than hand-rolled around a URLSession. A contract change should break the build, not a screen in production.',
			},
			{
				title: 'The tests',
				body: 'Acceptance scenarios drive XCUITest against a stubbed contract; the domain sits in a plain Swift module with no UIKit or SwiftUI import, so its tests run in a second. Snapshot tests cover what a view looks like, not what it decides.',
			},
			{
				title: 'The patterns',
				body: 'Composition over inheritance, unidirectional state, and a strict boundary between view and model. Value types by default — the pattern that pays most on this stack is the one that removes a class of concurrency bug rather than the one that adds a layer.',
			},
			{
				title: 'The delivery',
				body: 'Trunk-based, with the store release decoupled from the merge by a feature flag. Review latency is a fact of the platform, so everything upstream of submission has to be fast enough to absorb it.',
			},
		],
		tools: [
			{ role: 'Acceptance, at the domain port', name: 'Quick + Nimble' },
			{ role: 'Consumer contract', name: 'PactSwift' },
			{ role: 'Provider mock in development', name: 'Microcks' },
			{ role: 'Local HTTP stubbing', name: 'URLProtocol stub' },
			{ role: 'UI tests', name: 'XCUITest' },
			{ role: 'End-to-end journeys', name: 'Maestro' },
			{ role: 'Visual regression', name: 'swift-snapshot-testing' },
		],
		state: 'Outline only. The guidance above is agreed; the worked examples and the starter project are not written yet.',
		status: 'soon',
	},
	{
		slug: 'android',
		title: 'Android',
		kicker: 'Kotlin · Jetpack Compose · Gradle',
		question: 'How does effective development look across a device population you do not control?',
		description:
			'Kotlin and Compose, where the same build has to behave on hardware and OS versions spanning most of a decade.',
		icon: 'M7 8h10v10a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V8Zm0 0a5 5 0 0 1 10 0M9.5 4.5 8.5 3m6 1.5L15.5 3',
		covers: [
			{
				title: 'The contract',
				body: 'Generated clients from the registered OpenAPI documents, with the serialization boundary tested against real payloads. Backwards compatibility is not optional here: an old version of the app stays installed for years after you stop shipping it.',
			},
			{
				title: 'The tests',
				body: 'Domain logic in a pure Kotlin module — JVM tests, no Robolectric, no emulator. Compose UI tests for the screens, and instrumented tests kept to the few things that genuinely need a device.',
			},
			{
				title: 'The patterns',
				body: 'Unidirectional data flow with immutable state, coroutines and flows at the seams, dependency inversion at the platform boundary so the domain never imports `android.*`.',
			},
			{
				title: 'The delivery',
				body: 'Staged rollout with a crash-rate gate that can halt it. R8 configuration, baseline profiles and a size budget checked in the pipeline — on this stack, performance is a contract with the low end of the device population.',
			},
		],
		tools: [
			{ role: 'Acceptance, at the domain port', name: 'Cucumber-JVM, on the pure Kotlin module' },
			{ role: 'Consumer contract', name: 'pact-jvm' },
			{ role: 'Provider mock in development', name: 'Microcks' },
			{ role: 'Local HTTP stubbing', name: 'MockWebServer' },
			{ role: 'UI tests', name: 'Compose UI test + Kaspresso' },
			{ role: 'End-to-end journeys', name: 'Maestro' },
			{ role: 'Visual regression', name: 'Paparazzi' },
		],
		state: 'Outline only. The guidance above is agreed; the worked examples and the starter project are not written yet.',
		status: 'soon',
	},
	{
		slug: 'angular',
		title: 'Angular',
		kicker: 'TypeScript · Angular · RxJS',
		question: 'How does user-first become a working practice rather than a slogan?',
		description:
			'The stack where the user-first half of effective development is concrete: the design system is a contract, the API contract is consumed, and the journey is the acceptance test.',
		icon: 'm12 3 8.5 3-1.3 11L12 21l-7.2-4L3.5 6 12 3Zm-3 12 3-8 3 8m-4.8-2.6h3.6',
		covers: [
			{
				title: 'The contract',
				body: 'Typed clients generated from the registered API contracts, so a breaking change lands as a TypeScript error at build time instead of an undefined at runtime. No hand-written interface duplicating a schema that already exists.',
			},
			{
				title: 'The tests',
				body: 'Acceptance scenarios run in Playwright against a contract-mocked backend, so the journey is tested without the deployment. Components are built and tested in Storybook against their declared states before they are wired into a page, and tested through the DOM the user actually sees; services tested as plain classes.',
			},
			{
				title: 'The patterns',
				body: 'Standalone components, signals for state, and a clear split between presentational and container components. Smart use of the type system is the pattern vocabulary here — the model that makes an invalid screen state unrepresentable.',
			},
			{
				title: 'The delivery',
				body: 'Bundle budgets enforced in CI, accessibility checks in the acceptance suite rather than in a spreadsheet, design tokens generated from Figma rather than retyped, and preview deployments per pull request so a UX designer can review the running thing.',
			},
		],
		tools: [
			{ role: 'Acceptance, at the journey level', name: 'Playwright' },
			{ role: 'Consumer contract', name: 'pact-js' },
			{ role: 'Provider mock in development', name: 'Microcks' },
			{ role: 'Local HTTP stubbing', name: 'Angular HttpTestingController' },
			{ role: 'Component tests', name: 'Testing Library, through the DOM' },
			{ role: 'Component workbench', name: 'Storybook — stories as fixtures' },
			{ role: 'Accessibility', name: 'axe, per story and inside the Playwright run' },
			{ role: 'Visual regression', name: 'Storybook stories, compared per commit' },
		],
		state: 'Outline only. The guidance above is agreed; the worked examples and the starter project are not written yet.',
		status: 'soon',
	},
	{
		slug: 'spring-boot',
		title: 'Spring Boot',
		kicker: 'Java · Kotlin · Spring Boot',
		question: 'How is a hexagonal service built when the framework wants to be everywhere?',
		description:
			'The most common backend stack, and the one where framework annotations most easily leak into a domain that should not know the framework exists.',
		icon: 'M12 3.5c4 2.5 5.5 6 4.5 9.5-.8 2.8-3 4.5-5 5-1.2-2.5-1-5 .5-7m-4 3.5c-1 1.6-1 3.4 0 5',
		covers: [
			{
				title: 'The contract',
				body: 'The OpenAPI document is written first and registered before the controller exists; server stubs are generated from it. A specification derived from a running controller documents whatever the controller happens to do, including the parts nobody meant to promise.',
			},
			{
				title: 'The tests',
				body: 'Acceptance tests through the port with the adapters stubbed, then a thin ring of @SpringBootTest slices for the wiring itself. Testcontainers for the datastore, consumer-driven contract tests for the calls that leave the service.',
			},
			{
				title: 'The patterns',
				body: 'Ports and adapters with the domain in a module that has no Spring dependency at all — enforced by an ArchUnit rule, not by good intentions. Use case classes as the application boundary; the controller only translates.',
			},
			{
				title: 'The delivery',
				body: 'Build once, promote the same artefact, configure per environment. Health, readiness and metrics endpoints wired from the start, and observability treated as part of the definition of done.',
			},
		],
		tools: [
			{ role: 'Acceptance, at the use case port', name: 'Cucumber-JVM' },
			{ role: 'Contract conformance', name: 'Microcks, against the deployed provider' },
			{ role: 'Consumer contract', name: 'pact-jvm' },
			{ role: 'Provider mock in development', name: 'Microcks' },
			{ role: 'Integration dependencies', name: 'Testcontainers' },
			{ role: 'Architecture rules', name: 'ArchUnit' },
			{ role: 'Test quality', name: 'PIT mutation testing' },
		],
		blueprint: {
			label: 'arch-blueprint-java · arch-blueprint-kotlin',
			note: 'Two sibling repositories in the same workspace already carry this shape, one per language.',
		},
		state: 'The best-supported stack here — the blueprint repositories exist. What is missing is this page walking through them.',
		status: 'soon',
	},
	{
		slug: 'quarkus',
		title: 'Quarkus',
		kicker: 'Java · Quarkus · GraalVM',
		question: 'What changes when build-time and native compilation are part of the design?',
		description:
			'Supersonic Java, where decisions get made at build time rather than at startup — which is a real constraint on how you are allowed to design.',
		icon: 'M12 3 20 7.5v9L12 21l-8-4.5v-9L12 3Zm0 5.5 3.5 2v4L12 16.5 8.5 14.5v-4L12 8.5Z',
		covers: [
			{
				title: 'The contract',
				body: 'Same rule as Spring Boot: contract first, stubs generated, revision registered before the implementation. The difference is that reflection-based tricks around the boundary have to be declared for native builds, which is a useful pressure towards explicitness.',
			},
			{
				title: 'The tests',
				body: '@QuarkusTest for the wiring, Dev Services for the dependencies, and a native-image test run in the pipeline — because a service that passes on the JVM and fails as a native binary has not been tested.',
			},
			{
				title: 'The patterns',
				body: 'Hexagonal again, with the domain free of CDI. Build-time initialisation rewards a design where the dependency graph is knowable statically — the same property that makes the code easy to reason about.',
			},
			{
				title: 'The delivery',
				body: 'Native binaries where startup latency is the point, JVM images where it is not. That is a per-service decision with a real cost on both sides, so it gets recorded as a decision.',
			},
		],
		tools: [
			{ role: 'Acceptance, at the use case port', name: 'Cucumber-JVM' },
			{ role: 'Contract conformance', name: 'Microcks, against the deployed provider' },
			{ role: 'Consumer contract', name: 'pact-jvm' },
			{ role: 'Provider mock in development', name: 'Microcks, as a dev service' },
			{ role: 'Integration dependencies', name: 'Quarkus Dev Services' },
			{ role: 'Architecture rules', name: 'ArchUnit' },
			{ role: 'Native build', name: '@QuarkusIntegrationTest, in the pipeline' },
		],
		blueprint: {
			label: 'arch-blueprint-quarkus',
			note: 'A sibling repository in the same workspace already carries this shape.',
		},
		state: 'Outline only. The blueprint repository exists; this page does not walk through it yet.',
		status: 'soon',
	},
	{
		slug: 'eap',
		title: 'EAP',
		kicker: 'Java · Jakarta EE · JBoss EAP',
		question: 'How do these practices apply to a system that was not built with them?',
		description:
			'Jakarta EE on JBoss EAP — the stack that carries the systems already in production, where every improvement has to be made without stopping the world.',
		icon: 'M4 6h16v5H4V6Zm0 7h16v5H4v-5Zm3.5-4.5h.01M7.5 15.5h.01',
		covers: [
			{
				title: 'The contract',
				body: 'The boundary is usually already there and undocumented. The first move is to write the contract for what the system actually exposes today, register it, and only then start changing it — you cannot design forward from a promise nobody has read.',
			},
			{
				title: 'The tests',
				body: 'Characterisation tests before any refactoring: pin the current behaviour, including the parts that look wrong, then change with a net underneath. Arquillian where the container is genuinely needed, plain JUnit everywhere it is not.',
			},
			{
				title: 'The patterns',
				body: 'Strangler fig at the system scale, anti-corruption layer at every seam with the new code, and seams introduced deliberately so that a testable design becomes reachable from an untestable one.',
			},
			{
				title: 'The delivery',
				body: 'Automate the deployment before improving the code. A release that cannot be repeated is a release nobody dares to make often, and everything else here depends on being able to ship a small change.',
			},
		],
		tools: [
			{ role: 'Characterisation, before any change', name: 'JUnit, pinning current behaviour' },
			{ role: 'Acceptance, once a seam exists', name: 'Cucumber-JVM' },
			{ role: 'Contract conformance', name: 'Microcks, against what the system exposes today' },
			{ role: 'Consumer contract', name: 'pact-jvm, once consumers are known' },
			{ role: 'Container-dependent tests', name: 'Arquillian, only where the container is needed' },
			{ role: 'Integration dependencies', name: 'Testcontainers' },
			{ role: 'Coverage of the untested', name: 'JaCoCo, to find the unpinned parts' },
		],
		state: 'Outline only, and the least developed of the six. Legacy modernisation is the case where generic advice helps least, so this page owes the most worked detail.',
		status: 'soon',
	},
] as const;

/** The stack for a URL segment, or undefined. */
export function findStack(slug: string): Stack | undefined {
	return stacks.find((stack) => stack.slug === slug);
}
