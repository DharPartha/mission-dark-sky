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
    eventDemand: number,
    ambientContribution: number,
    environmentalReduction: number,
}

return {}
