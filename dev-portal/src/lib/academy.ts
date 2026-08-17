/**
 * The Academy curriculum, defined once.
 *
 * Modelled on api-portal's and arch-portal's academies so the three hubs teach
 * in the same shape: a small set of learning paths, each with a level, a handful
 * of lessons, and a pointer to the documentation that already covers its ground.
 * Publishing the curriculum before the lessons exist is deliberate — the *shape*
 * of a curriculum is a commitment worth reviewing, and it gives a reader
 * something better than "coming soon".
 *
 * The order is the order of the argument this hub makes: you cannot be
 * test-first without a design that is testable, you cannot be contract-first
 * without knowing what a contract is for, and AI only accelerates a practice
 * that was already worth doing — which is why it comes last rather than first.
 *
 * Lessons marked `video` ship as a short narrative: a team with a problem, the
 * decision they took, what it bought and what it cost.
 */

export interface Lesson {
	title: string;
	/** A lesson that will ship with a storytelling video. */
	video?: boolean;
}

export interface LearningPath {
	/** Foundation, Core, Applied, Advanced — the order to take them in. */
	level: string;
	title: string;
	summary: string;
	lessons: readonly Lesson[];
	/** Documentation that covers this ground today, so the card is never a dead end. */
	readToday: { label: string; href: string };
}

export const paths: readonly LearningPath[] = [
	{
		level: 'Foundation',
		title: 'Connected development',
		summary:
			'Effective development starts as a communication problem. The rituals that put end-users, UX designers, domain experts, developers, architects, quality engineers, product owners and operations in the same conversation — before the code exists.',
		lessons: [
			{ title: 'The handover is where requirements go to die', video: true },
			{ title: 'Three amigos: the smallest conversation that prevents rework' },
			{ title: 'Example mapping: turning a story into rules, examples and open questions', video: true },
			{ title: 'Event storming: finding the domain with the people who live in it' },
			{ title: 'Ubiquitous language — when the same word means two things', video: true },
		],
		readToday: { label: 'Practices', href: '/doc/practices/' },
	},
	{
		level: 'Foundation',
		title: 'User-first',
		summary:
			'Starting from the person who has to use the thing. What the journey is, what it costs them when it is wrong, and why that belongs upstream of the architecture rather than downstream of it.',
		lessons: [
			{ title: 'The user journey as the first artefact', video: true },
			{ title: 'Designing the interaction before designing the system' },
			{ title: 'Accessibility as a design constraint, not a late audit' },
			{ title: 'What a UX designer needs from a developer, and vice versa', video: true },
			{ title: 'Design systems as a contract: Figma tokens, Storybook stories' },
		],
		readToday: { label: 'User-first', href: '/doc/attitudes/user-first/' },
	},
	{
		level: 'Core',
		title: 'Test-first',
		summary:
			'Writing the test first is not about testing. It is a design technique: the first caller of your code is the test, and if it is painful to write, that is the design telling you something.',
		lessons: [
			{ title: 'Red, green, refactor — and why the third step is the one people skip', video: true },
			{ title: 'BDD: specifying behaviour in the language of the business' },
			{ title: 'ATDD: the acceptance test as the definition of done' },
			{ title: 'All-in-one testing: one suite, many levels, no duplicated intent', video: true },
			{ title: 'Test doubles without lying: stubs, mocks, and what each one is for' },
			{ title: 'SRP and testability: why a painful test is a design report', video: true },
		],
		readToday: { label: 'Test-first', href: '/doc/attitudes/test-first/' },
	},
	{
		level: 'Core',
		title: 'Contract-first',
		summary:
			'Making the boundary between two parts explicit enough that either side can change without asking permission — and checkable enough that a breach is a build failure rather than a discovery in production.',
		lessons: [
			{ title: 'Where does the boundary go? Contract-first as a design method', video: true },
			{ title: 'API-first: the interface is the deliverable', video: true },
			{ title: 'What belongs in a contract, and what is an implementation detail' },
			{ title: 'Consumer-driven contracts and the tests that come with them' },
			{ title: 'Versioning and deprecation without breaking the people downstream', video: true },
		],
		// The attitude, matching its two sibling paths — Test-first and
		// User-first both open on the disposition rather than the ritual.
		readToday: { label: 'Contract-first', href: '/doc/attitudes/contract-first/' },
	},
	{
		level: 'Applied',
		title: 'Patterns-oriented design',
		summary:
			'The pattern catalogue taught the way it is actually used: as a shared vocabulary for a problem you already have, not a shelf to shop from. Including when not to reach for one.',
		lessons: [
			{ title: 'GoF, thirty years on: which ones still earn their keep', video: true },
			{ title: 'Tactical DDD: value objects, entities and aggregates, and what each one is for' },
			{ title: 'Strategic DDD: subdomains, bounded contexts and the context map', video: true },
			{ title: 'Architecture patterns: layers, hexagons, and what the boundary is for' },
			{ title: 'Integration patterns and the fallacies of distributed computing' },
			{ title: 'Use case patterns: the shape of an application boundary' },
			{ title: 'Anti-patterns — the ones that look like patterns until year two', video: true },
		],
		readToday: { label: 'Code design', href: '/doc/code-design/' },
	},
	{
		level: 'Applied',
		title: 'Software craftsmanship',
		summary:
			'Questioning a line of code: its relevance, its purpose, its location, its testability, its durability. At scale, the same questions are what keep a design extensible and free of accumulated debt.',
		lessons: [
			{ title: 'Five questions to ask of any line of code', video: true },
			{ title: 'Naming, and why it is a design activity' },
			{ title: 'Refactoring in small safe steps, continuously' },
			{ title: 'Technical debt: the metaphor, its limits, and how to make it visible', video: true },
			{ title: 'Code review as a teaching practice rather than a gate' },
		],
		readToday: { label: 'Code design', href: '/doc/code-design/' },
	},
	{
		level: 'Advanced',
		title: 'Semi-automation and AI',
		summary:
			'Where the machine takes over: scaffolding, generation, retro-engineering, assisted design. AI is a booster for a practice that was already sound — it multiplies whatever discipline it finds.',
		lessons: [
			{ title: 'What to automate, and what to keep as a human conversation', video: true },
			{ title: 'Code scaffolding from patterns instead of from a blank file' },
			{ title: 'Assisted API design: the model drafts, the contract decides' },
			{ title: 'Retro-engineering an architecture model from a codebase', video: true },
			{ title: 'Reviewing generated code without rubber-stamping it' },
		],
		readToday: { label: 'MCP', href: '/doc/mcp/' },
	},
] as const;

/** Lessons that will ship with a storytelling video, across every path. */
export const videoLessonCount = paths.reduce(
	(total, path) => total + path.lessons.filter((lesson) => lesson.video).length,
	0,
);

export const lessonCount = paths.reduce((total, path) => total + path.lessons.length, 0);
