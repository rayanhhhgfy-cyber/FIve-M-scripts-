Config = Config or {}

Config.Stretcher = {
    model = `prop_amb_stretcher`,
    pushSpeed = 1.0,
    maxPatientDist = 3.0,
    ambulanceModels = {
        `ambulance`, `ambulance2`, `firetruk`,
    },
    loadOffset = vec3(0.0, -2.5, 0.0),
}
