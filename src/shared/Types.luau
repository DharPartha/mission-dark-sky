export type SensorState = {
	people: number,
	vehicles: number,
	ambientLight: number,
	timeOfDay: number,
	weather: string,
	eventActive: boolean,
	environmentalSensitivity: number,
}

export type LightingDecision = {
	targetLevel: number,
	safetyRequirement: number,
	activityDemand: number,
	vehicleDemand: number,
	eventDemand: number,
	visibilityAdjustment: number,
	ambientContribution: number,
	environmentalReduction: number,
}

export type ImpactMetrics = {
	estimatedEnergy: number,
	estimatedCost: number,
	fixedEnergy: number,
	timedEnergy: number,
	adaptiveChangePercent: number,
	safetyActivityStatus: string,
	environmentStatus: string,
}

export type ScenarioDefinition = {
	id: string,
	displayName: string,
	description: string,
	sensorState: SensorState,
}

export type SimulationSnapshot = {
	scenarioId: string,
	scenarioName: string,
	sensors: SensorState,
	decision: LightingDecision,
	currentLighting: number,
	metrics: ImpactMetrics,
}

export type FixtureState = {
	id: string,
	enabled: boolean,
	currentLevel: number,
	targetLevel: number,
}

export type FixtureDefinition = {
	id: string,
	-- XZ offset from lot center; Y is ignored (pole height comes from Config).
	offset: Vector3,
}

export type ZoneDefinition = {
	id: string,
	displayName: string,
	fixtures: { FixtureDefinition },
}

return {}
