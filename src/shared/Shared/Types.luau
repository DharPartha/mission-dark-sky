--!strict
-- Types: shared type definitions for config, fixture state, and scoring.

export type Need = "Required" | "Useful" | "Unneeded"
export type Aim = "Down" | "Angled" | "Out" | "Up"
export type Schedule = "AllNight" | "Motion" | "Curfew"
export type Verb = "QUESTION" | "SHIELD" | "AIM" | "DIM" | "TIME" | "WARM"
export type QuestPhase = "Intro" | "Investigate" | "Confront" | "Restored" | "MoonTip" | "Complete"

export type FixtureState = {
	on: boolean,
	brightness: number,
	shielded: boolean,
	aim: Aim,
	colorTempK: number,
	schedule: Schedule,
}

export type FixtureDefinition = {
	id: string,
	nameKey: string,
	need: Need,
	kind: string,
	position: Vector3,
	facingDegrees: number,
	recommendedBrightness: number,
	minBrightness: number,
	allowedVerbs: { string },
	allowedSchedules: { string },
	questionNoticeKey: string,
	evidenceOnQuestion: string?,
	weight: number,
	initial: FixtureState,
}

export type ZoneDefinition = {
	id: string,
	nameKey: string,
	restoreThreshold: number,
	fixtures: { FixtureDefinition },
}

-- Lux Lens readings for one fixture. All 0-1 except colorTempK. Game estimates.
export type FixtureReadings = {
	brightness: number,
	glare: number,
	uplight: number,
	blueLight: number,
	overLight: number,
	harm: number,
}

export type ZoneSummary = {
	score: number,
	glare: number,
	uplight: number,
	blueLight: number,
	safePathLit: boolean,
}

export type GlareZone = {
	fixtureId: string,
	x: number,
	z: number,
	radius: number,
	glare: number,
}

-- Result of applying a verb. state is the new state when ok, the unchanged state otherwise.
export type ActionResult = {
	ok: boolean,
	state: FixtureState,
	noticeKey: string,
	noticeArg: (string | number)?,
	evidenceKey: string?,
}

return {}
