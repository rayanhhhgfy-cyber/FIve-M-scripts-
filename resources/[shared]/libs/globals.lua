---@meta

---@class QBoxPlayer
---@field PlayerData QBoxPlayerData
---@field Functions QBoxPlayerFunctions

---@class QBoxPlayerData
---@field citizenid string
---@field source number
---@field charinfo QBoxCharInfo
---@field money QBoxMoney
---@field job QBoxJob
---@field gang QBoxGang
---@field metadata table
---@field position table

---@class QBoxCharInfo
---@field firstname string
---@field lastname string
---@field birthdate string
---@field nationality string
---@field gender number
---@field phone string
---@field cid string
---@field account number

---@class QBoxMoney
---@field cash number
---@field bank number
---@field crypto number

---@class QBoxJob
---@field name string
---@field label string
---@field payment number
---@field onduty boolean
---@field isboss boolean
---@field grade QBoxGrade

---@class QBoxGrade
---@field name string
---@field level number
---@field isboss boolean

---@class QBoxGang
---@field name string
---@field label string
---@field grade QBoxGrade

---@class QBoxPlayerFunctions
---@field GetData fun(key: string): any
---@field SetData fun(key: string, value: any): any
---@field GetMoney fun(type: string): number
---@field AddMoney fun(type: string, amount: number, reason: string)
---@field RemoveMoney fun(type: string, amount: number, reason: string)
---@field SetMoney fun(type: string, amount: number, reason: string)
---@field GetItemCount fun(item: string): number
---@field AddItem fun(item: string, amount: number, slot: any, info: table)
---@field RemoveItem fun(item: string, amount: number, slot: any)

---@class QBoxCore
---@field Functions QBoxCoreFunctions
---@field Events QBoxCoreEvents
---@field Commands QBoxCoreCommands
---@field Config QBoxCoreConfig
---@field Shared QBoxShared

---@class QBoxCoreFunctions
---@field GetPlayer fun(src: number): QBoxPlayer
---@field GetPlayerByCitizenId fun(citizenId: string): QBoxPlayer
---@field GetPlayerByPhone fun(phone: string): QBoxPlayer
---@field GetPlayers fun(): table
---@field GetCoords fun(entity: number): vector3
---@field GetIdentifier fun(src: number): string
---@field GetSource fun(identifier: string): number
---@field IsOptedin fun(src: number): boolean
---@field IsWhitelisted fun(src: number): boolean
---@field CreateCallback fun(name: string, callback: function)
---@field TriggerCallback fun(name: string, ...)

---@class QBoxCoreEvents
---@field OnServerEvent fun(event: string, ...): any

---@class QBoxCoreCommands
---@field Add fun(name: string, command: string): nil
---@field AddGroupCommand fun(name: string, command: string): nil

---@class QBoxCoreConfig
---@field GetConfig fun(key: string): any

---@class QBoxShared
---@field Items table
---@field Jobs table
---@field Gangs table
---@field Vehicles table
---@field ForceItems fun()
---@field ForceJob fun()
---@field ForceGangs fun()
---@field ForceVehicles fun()

---@class OxPlayer
---@field source number
---@field character table
---@field get fun(key: string): any
---@field set fun(key: string, value: any)
---@field getInventory fun(): table
---@field addItem fun(name: string, count: number)
---@field removeItem fun(name: string, count: number)
---@field canCarryItem fun(name: string, count: number): boolean

---@class MySQL
---@field query fun(query: string, params: table, cb: function): table
---@field prepared fun(query: string, params: table, cb: function): table
---@field fetch fun(query: string, params: table, cb: function): table
---@field insert fun(query: string, params: table, cb: function): table
---@field update fun(query: string, params: table, cb: function): table
---@field scalar fun(query: string, params: table, cb: function): any
---@field transaction fun(queries: table, cb: function): table

---@class ox_lib
---@field Notify fun(src: number | table, msg: string, type: string, duration?: number): void
---@field ProgressBar fun(data: table): boolean
---@field ProgressCircle fun(data: table): boolean
---@field SkillCheck fun(data: table, cb: function)
---@field ContextMenu fun(data: table): any
---@field InputDialog fun(data: table): any
---@field AlertDialog fun(data: table): any
---@field TextUI fun(msg: string, icon?: string)
---@field HideTextUI fun()
---@field ShowTextUI fun(msg: string, icon?: string)
---@field SetChatFocus fun(focus: boolean)
---@field IsActive fun(): boolean
---@field TimerBar fun(bars: table)
---@field TimerBars fun(bars: table)
---@field WaitFor fun(ms: number): any

---@class WrappersClass
---@field Notify fun(src: number | table, msg: string, type: string, duration?: number): void
---@field ProgressBar fun(data: table): boolean
---@field ProgressCircle fun(data: table): boolean
---@field SkillCheck fun(data: table, cb: function)
---@field ContextMenu fun(data: table): any
---@field InputDialog fun(data: table): any
---@field AlertDialog fun(data: table): any
---@field TextUI fun(msg: string, icon?: string)
---@field HideTextUI fun()
---@field ShowTextUI fun(msg: string, icon?: string)
---@field RegisterMenu fun(data: table)

---@class DiscordLogs
---@field LogCustom fun(data: table): void
---@field Log fun(name: string, message: string): void

-- Types commonly used by FiveM/other resources (stubs for tooling)
---@class vector3
---@field x number
---@field y number
---@field z number

---@alias void nil

---@alias interval number
---@alias timeout number

---@class QBCore
---@field Functions any
---@field PlayerData any
---@field Config any
---@field Shared any

---@type QBCore
QBox = nil

---@type QBCore
QBCore = nil

---@type WrappersClass
Wrappers = nil

---@type function
Locale = nil

---@type ox_lib
exports.ox_lib = nil

---@type DiscordLogs
exports.discord_logs = nil
exports['discord-logs'] = nil

---@type table<string, table>
Config = nil

---@type table<string, number|table>
RATE_LIMITS = nil

-- Blip natives
---@param blip number
function RemoveBlip(blip) end
---@param coords vector3
---@return number
function AddBlipForCoord(coords) end
---@param entity number
---@return number
function AddBlipForEntity(entity) end
---@param blip number
---@param sprite number
function SetBlipSprite(blip, sprite) end
---@param blip number
---@param colour number
function SetBlipColour(blip, colour) end
---@param blip number
---@param scale number
function SetBlipScale(blip, scale) end
---@param blip number
---@param range boolean
function SetBlipAsShortRange(blip, range) end
---@param blip number
function SetBlipRoute(blip, enabled) end
---@param blip number
function SetBlipRouteColour(blip, colour) end
---@param blip number
function SetBlipAlpha(blip, alpha) end
function SetBlipCategory(blip, category) end
function SetBlipDisplay(blip, display) end
function SetBlipPriority(blip, priority) end
function SetBlipAsFriendly(blip, friendly) end
function SetBlipAsMissionCreator(blip, mission) end
function ShowNumberOnBlip(blip, number) end
function HideNumberOnBlip(blip) end
function ShowHeightOnBlip(blip, toggle) end
function PulseBlip(blip) end
function IsBlipShortRange(blip) end
function GetBlipSprite(blip) end
function GetBlipColour(blip) end
function GetBlipCoords(blip) end
function GetBlipFromEntity(entity) end
function DoesBlipExist(blip) end
function SetBlipHiddenOnLegend(blip, hidden) end
function BeginTextCommandSetBlipName(textLabel) end
function AddTextComponentSubstringPlayerName(text) end
function EndTextCommandSetBlipName(blip) end
function SetBlipLabel(blip, label) end

-- Audio natives
function PlaySound(soundId, soundName, soundSet, p3, p4, p5) end
function PlaySoundFromCoord(soundName, coords, soundSet, p4, p5, p6) end
function PlaySoundFrontend(soundId, soundName, soundSet, p4) end
function PlayAmbientSpeech1(ped, speechName, voiceName, params) end
function PlayAmbientSpeechWithVoice(ped, speechName, voiceName, params, p5) end
function PlayPedRingtone(soundId, ped, ringtoneName, p3) end
function StopSound(soundId) end
function ReleaseSound(soundId) end
function StopPedRingtone(ped) end
function SetAudioFlag(flag, toggle) end
function SetVariableOnSound(soundId, varName, value) end
function SetSoundVolume(soundId, volume) end
function SetSynchronizedAudioVolume(audioVolume) end
function SetVehicleRadioEnabled(vehicle, toggle) end

-- Task natives
function TaskWarpPedIntoVehicle(ped, vehicle, seat) end
function TaskLeaveVehicle(ped, vehicle, flags) end
function TaskVehicleDriveWander(ped, vehicle, speed, drivingStyle) end
function TaskVehicleDriveToCoord(ped, vehicle, x, y, z, speed, p6, vehicleModel, drivingMode, p9, p10) end
function TaskVehicleFollow(ped, vehicle, targetVehicle, speed, drivingStyle, minDistance) end
function TaskVehicleTempAction(vehicle, action, time) end
function TaskGoToEntity(ped, target, duration, distance, speed, p6, p7) end
function TaskGoToCoordAnyMeans(ped, x, y, z, speed, p5, p6, p7, p8, p9, p10, p11) end
function TaskGoStraightToCoord(ped, x, y, z, speed, timeout, targetHeading, distanceToSlide) end
function TaskTurnPedToFaceEntity(ped, entity, duration) end
function TaskLookAtEntity(ped, entity, duration, unknown1, unknown2) end
function TaskStandStill(ped, time) end
function TaskWanderStandard(ped, p1, p2) end
function TaskWanderAround(ped, x, y, z, radius, p5, p6) end
function TaskSetBlockingOfNonTemporaryEvents(ped, toggle) end
function TaskPlayAnim(ped, animDict, animName, speed, speedMultiplier, duration, flags, playbackRate, lockX, lockY, lockZ) end
function TaskPlayAnimAdvanced(ped, animDict, animName, posX, posY, posZ, rotX, rotY, rotZ, speed, speedMultiplier, duration, flag, playbackRate, lockX, lockY, lockZ) end
function TaskStartScenarioInPlace(ped, scenarioName, unkDuration, playEnterAnim, p4) end
function TaskCombatPed(ped, targetPed, p2, p3) end
function TaskAimGunAtEntity(ped, entity, duration, p3) end
function TaskShootAtEntity(ped, entity, duration, firingPattern) end
function TaskClearLookAt(ped) end
function ClearPedTasks(ped) end
function ClearPedSecondaryTask(ped) end
function ClearPedTasksImmediately(ped) end
function IsPedActiveInScenario(ped) end
function GetIsTaskActive(ped, taskIndex) end

-- Camera natives
---@return number
function CreateCam(camName, p1) end
function CreateCamWithParams(camName, posX, posY, posZ, rotX, rotY, rotZ, fov, p8, p9) end
function CreateCamera(camName, p1) end
function CreateCameraWithParams(camName, posX, posY, posZ, rotX, rotY, rotZ, fov, p8, p9) end
function DestroyCam(cam, bScriptHostCam) end
function SetCamActive(cam, active) end
function SetCamCoord(cam, posX, posY, posZ) end
function SetCamRot(cam, rotX, rotY, rotZ, rotationOrder) end
function SetCamFov(cam, fov) end
function SetCamNearClip(cam, nearClip) end
function SetCamFarClip(cam, farClip) end
function SetCamFarDepth(cam, farDepth) end
function SetCamMotionBlurStrength(cam, strength) end
function SetCamSplineDuration(cam, timeDuration) end
function SetCamSplineSmoothingStyle(cam, smoothingStyle) end
function SetCamUseShallowDofMode(cam, toggle) end
function SetCamDofStrength(cam, dofStrength) end
function SetCamDofPlane(cam, dofPlane) end
function SetCamDofMaxNearInFocusDistance(cam, distance) end
function SetCamDofMaxNearInFocusDepthBlendAmount(cam, ratio) end
function PointCamAtCoord(cam, x, y, z) end
function PointCamAtEntity(cam, entity, p2, p3, p4, p5) end
function StopCamPointing(cam) end
function GetCamCoord(cam) end
function GetCamRot(cam, rotationOrder) end
function GetCamFov(cam) end
function GetCamNearClip(cam) end
function GetCamFarClip(cam) end
function GetCamFarDof(cam) end
function IsCamActive(cam) end
function IsCamRendering(cam) end
function IsCamInterpolating(cam) end
function IsCamSplineDurationMet(cam) end
function SetCamActiveWithInterp(camTo, camFrom, duration, easeLocation, easeRotation) end
function RenderScriptCams(render, ease, easeCamera, easeDuration, bScriptOnlyCamControl, p5) end
function ShakeCam(cam, shakeType, amplitude) end
function AnimatedShakeCam(cam, shakeType, amplitude) end
function IsCamShaking(cam) end
function StopCamShaking(cam, immediate) end

-- Vehicle natives
function GetRandomVehicleInSphere(x, y, z, radius, modelHash, flags) end
function GetClosestVehicle(x, y, z, radius, modelHash, flags) end
function IsVehicleModel(vehicle, modelHash) end
function GetVehiclePedIsIn(ped, lastVehicle) end
function IsPedInVehicle(ped, vehicle, atGetIn) end
function IsPedInAnyVehicle(ped, atGetIn) end
function IsVehicleSeatFree(vehicle, seatIndex) end
function GetPedInVehicleSeat(vehicle, seatIndex) end
function SetVehicleEngineOn(vehicle, value, immediately, otherwise) end
function SetVehicleEngineHealth(vehicle, health) end
function SetVehicleBodyHealth(vehicle, health) end
function SetVehiclePetrolTankHealth(vehicle, health) end
function SetVehicleFuelLevel(vehicle, fuelLevel) end
function GetVehicleFuelLevel(vehicle) end
function GetVehicleBodyHealth(vehicle) end
function GetVehicleEngineHealth(vehicle) end
function GetVehiclePetrolTankHealth(vehicle) end
function GetVehicleNumberPlateText(vehicle) end
function SetVehicleNumberPlateText(vehicle, plateText) end
function GetVehicleDoorLockStatus(vehicle) end
function SetVehicleDoorsLocked(vehicle, doorLockStatus) end
function SetVehicleDoorsLockedForAllPlayers(vehicle, toggle) end
function SetVehicleDoorsLockedForPlayer(vehicle, player, toggle) end
function SetVehicleDoorOpen(vehicle, doorIndex, loose, openInstantly) end
function SetVehicleDoorShut(vehicle, doorIndex, closeInstantly) end
function SetVehicleDoorBroken(vehicle, doorIndex, deleteDoor) end
function IsVehicleDoorDamaged(vehicle, doorIndex) end
function GetVehicleDoorAngleRatio(vehicle, doorIndex) end
function SetVehicleTyreBurst(vehicle, tireIndex, onRim, p3) end
function SetVehicleTyreFixed(vehicle, tireIndex) end
function IsVehicleTyreBurst(vehicle, tireIndex, completely) end
function SetVehicleWindowTint(vehicle, tint) end
function GetVehicleWindowTint(vehicle) end
function SmashVehicleWindow(vehicle, windowIndex) end
function RollUpWindow(vehicle, windowIndex) end
function RollDownWindow(vehicle, windowIndex) end
function RollDownWindows(vehicle) end
function RemoveVehicleWindow(vehicle, windowIndex) end
function FixVehicleWindow(vehicle, windowIndex) end
function IsVehicleWindowIntact(vehicle, windowIndex) end
function SetVehicleLivery(vehicle, livery) end
function GetVehicleLivery(vehicle) end
function SetVehicleColours(vehicle, colorPrimary, colorSecondary) end
function SetVehicleExtraColours(vehicle, pearlescentColor, wheelColor) end
function SetVehicleMod(vehicle, modType, modIndex, customTire) end
function GetVehicleMod(vehicle, modType) end
function GetVehicleModCount(vehicle, modType) end
function GetNumVehicleMods(vehicle, modType) end
function CreateVehicle(modelHash, x, y, z, heading, isNetwork, bScriptHostVehicle) end
function DeleteVehicle(vehicle) end
function SetVehicleOnGroundProperly(vehicle) end
function SetVehicleSiren(vehicle, toggle) end
function IsVehicleSirenOn(vehicle) end
function SetVehicleHasBeenOwnedByPlayer(vehicle, owned) end
function SetVehicleNeedsToBeHotwired(vehicle, toggle) end
function SetVehicleIsStolen(vehicle, stolen) end
function GetVehicleClass(vehicle) end
function GetVehicleClassEstimatedMaxSpeed(vehicleClass) end
function SetVehicleCustomPrimaryColour(vehicle, r, g, b) end
function SetVehicleCustomSecondaryColour(vehicle, r, g, b) end
function GetVehicleDashboardColour(vehicle) end
function GetVehicleExtraColours(vehicle, pearlescentColor, wheelColor) end
function GetVehicleCustomPrimaryColour(vehicle, r, g, b) end
function GetVehicleCustomSecondaryColour(vehicle, r, g, b) end
function IsVehicleExtraTurnedOn(vehicle, extraId) end
function SetVehicleExtra(vehicle, extraId, toggle) end
function DoesVehicleHaveDoor(vehicle, doorIndex) end
function SetVehicleNeonLightsColour(vehicle, r, g, b) end
function GetVehicleNeonLightsColour(vehicle) end
function SetVehicleNeonLightEnabled(vehicle, index, toggle) end
function IsVehicleNeonLightEnabled(vehicle, index) end
function IsThisModelACar(modelHash) end
function IsThisModelABike(modelHash) end
function IsThisModelABoat(modelHash) end
function IsThisModelAHeli(modelHash) end
function IsThisModelAPlane(modelHash) end
function IsThisModelABicycle(modelHash) end
function IsThisModelAQuadbike(modelHash) end
function IsThisModelAJetski(modelHash) end
function GetVehicleHandlingFloat(vehicle, field, name) end
function SetVehicleHandlingFloat(vehicle, field, name, value) end
function GetVehicleMaxSpeed(vehicle) end
function GetVehicleMaxBraking(vehicle) end
function GetVehicleMaxTraction(vehicle) end
function GetVehicleAcceleration(vehicle) end
function SetVehicleForwardSpeed(vehicle, speed) end
function SetVehicleBrakeLights(vehicle, toggle) end
function SetVehicleBrake(vehicle, toggle) end
function SetVehicleHandbrake(vehicle, toggle) end
function SetVehicleIndicatorLights(vehicle, turnSignal, toggle) end
function SetVehicleInteriorlight(vehicle, toggle) end
function SetVehicleSearchlight(vehicle, toggle, canBeUsedByPlayer) end
function SetVehicleSearchlightEnabled(vehicle, toggle) end
function GetVehicleDirtLevel(vehicle) end
function SetVehicleDirtLevel(vehicle, dirtLevel) end
function SetVehicleNumberPlateTextIndex(vehicle, plateIndex) end
function GetVehicleNumberPlateTextIndex(vehicle) end
function SetVehicleWheelType(vehicle, WheelType) end
function GetVehicleWheelType(vehicle) end
function GetVehicleWheelTypeName(vehicle) end
function SetVehicleModColor(vehicle, p1, r, g, b, p2) end
function GetVehicleModColor(vehicle, p1, r, g, b, p2) end
function GetNumVehicleWindows(vehicle) end
function IsVehicleAlarmSet(vehicle) end
function IsVehicleAlarmActivated(vehicle) end
function SetVehicleAlarm(vehicle, toggle) end
function StartVehicleAlarm(vehicle) end
function SetVehicleHasMutedSirens(vehicle, toggle) end
function SetVehicleActiveDuringPlayback(vehicle, toggle) end
function SetVehicleCanBeUsedByFleeingPeds(vehicle, toggle) end
function SetVehicleCanBreak(vehicle, toggle) end
function SetVehicleCanBeTargetted(vehicle, toggle) end
function SetVehicleCanBeDamaged(vehicle, toggle) end
function SetVehicleCanBeVisiblyDamaged(vehicle, toggle) end
function SetVehicleExplodesOnHighVelocityDamage(vehicle, toggle) end
function IsVehicleStopped(vehicle) end
function IsVehicleStoppedAtTrafficLights(vehicle) end
function SetVehicleLights(vehicle, p1) end
function GetVehicleLightsState(vehicle, lightsOn, highbeamsOn) end
function SetVehicleInteriorColour(vehicle, color) end
function GetVehicleInteriorColour(vehicle) end
function SetVehicleDashboardColour(vehicle, color) end
function GetVehicleInteriorColor(vehicle) end
function GetVehicleDashboardColor(vehicle) end
function GetVehicleColours(vehicle, colorPrimary, colorSecondary) end
function IsVehicleTyreBurst(vehicle, wheelID, completely) end
function SetVehicleTyreBurst(vehicle, wheelID, onRim, p3) end
function SetVehicleWheelHealth(vehicle, wheelIndex, health) end
function GetVehicleWheelHealth(vehicle, wheelIndex) end
function SetVehicleWheelIsBurst(vehicle, wheelID, burst) end
function IsVehicleWheelBurst(vehicle, wheelID) end
function GetVehiclePedIsTryingToEnter(ped) end
function GetVehiclePedIsEntering(ped) end
function SetVehicleReservePetrolTank(vehicle, toggle) end
function SetVehicleReservePetrolTankHealth(vehicle, health) end
function IsVehicleInGarageArea(vehicle, garagePosition, garageRadius) end
function IsVehicleInDriveway(vehicle, drivewayIndex) end
function GetEntityAttachedToCargoBob(entity) end
function SetVehicleRocketBoostActive(vehicle, toggle) end
function IsVehicleRocketBoostActive(vehicle) end
function SetVehicleRocketBoostCapacity(vehicle, capacity) end
function GetVehicleRocketBoostCapacity(vehicle) end
function SetVehicleRocketBoostPercentage(vehicle, percentage) end
function GetVehicleRocketBoostPercentage(vehicle) end
function SetVehicleParachuteActive(vehicle, active) end
function DoesVehicleHaveParachute(vehicle) end
function IsVehicleParachuteActive(vehicle) end
function SetVehicleDummyHandling(vehicle, toggle) end

-- Entity natives (general)
function SetEntityCoords(entity, x, y, z, xAxis, yAxis, zAxis, clearMission) end
function SetEntityHeading(entity, heading) end
function SetEntityVelocity(entity, x, y, z) end
function SetEntityCollision(entity, toggle, keepPhysics) end
function SetEntityAlpha(entity, alphaLevel, skin) end
function SetEntityVisible(entity, toggle, unk) end
function SetEntityInvincible(entity, toggle) end
function SetEntityAsMissionEntity(entity, p1, p2) end
function SetEntityAsNoLongerNeeded(entity) end
function SetEntityCanBeDamaged(entity, toggle) end
function SetEntityCanBeDamagedByRelationshipGroup(entity, toggle, relGroup) end
function SetEntityProofs(entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof) end
function SetEntityOnlyDamagedByPlayer(entity, toggle) end
function SetEntityOnlyDamagedByRelationshipGroup(entity, toggle, relGroup) end
function SetEntityHealth(entity, health) end
function SetEntityMaxHealth(entity, maxHealth) end
function SetEntityArmour(entity, armour) end
function SetEntityMotionBlur(entity, toggle) end
function SetEntityLodDist(entity, lodDist) end
function FreezeEntityPosition(entity, toggle) end
function GetEntityCoords(entity) end
function GetEntityHeading(entity) end
function GetEntityModel(entity) end
function GetEntityHealth(entity) end
function GetEntityMaxHealth(entity) end
function GetEntityArmour(entity) end
function GetEntityVelocity(entity) end
function GetEntityForwardVector(entity) end
function GetEntityForwardX(entity) end
function GetEntityForwardY(entity) end
function GetEntityMatrix(entity) end
function GetEntityRotation(entity, rotationOrder) end
function GetEntityRotationVelocity(entity) end
function GetEntityPopulationType(entity) end
function GetEntityType(entity) end
function GetEntityAlpha(entity) end
function GetEntityCollisionEnabled(entity) end
function DoesEntityExist(entity) end
function IsEntityDead(entity) end
function IsEntityAPed(entity) end
function IsEntityAVehicle(entity) end
function IsEntityAnObject(entity) end
function IsEntityAtCoord(entity, x, y, z, xRadius, yRadius, zRadius, p7, p8, p9) end
function IsEntityAttached(entity) end
function IsEntityAttachedToEntity(entity, entity2) end
function IsEntityTouchingEntity(entity, entity2) end
function IsEntityTouchingModel(entity, modelHash) end
function IsEntityInArea(entity, x1, y1, z1, x2, y2, z2, p7, p8, p9) end
function IsEntityInZone(entity, zone) end
function IsEntityInWater(entity) end
function IsEntityOnScreen(entity) end
function IsEntityUpright(entity, angle) end
function IsEntityUpsidedown(entity) end
function IsEntityPositionFrozen(entity) end
function IsEntityVisible(entity) end
function IsEntityVisibleToScript(entity) end
function IsEntityOccluded(entity) end
function AttachEntityToEntity(entity1, entity2, boneIndex, x, y, z, rotX, rotY, rotZ, p9, useSoftPinning, collision, isPed, vertexIndex, fixedRot) end
function DetachEntity(entity, p1, p2) end
function GetEntityBoneCount(entity) end
function GetEntityBoneIndexByName(entity, boneName) end
function GetEntityBoneRotation(entity, boneIndex) end
function CleanupPlayerSpawnPoint() end
function ClearEntityLastDamageEntity(entity) end
function CreateModelSwap(x, y, z, radius, fromModel, toModel, p6) end
function RemoveModelSwap(x, y, z, radius, fromModel, toModel, p6) end
function CreateModelHide(x, y, z, radius, model, p5) end
function RemoveModelHide(x, y, z, radius, model, p5) end
function NetworkGetEntityIsNetworked(entity) end
function NetworkHasControlOfEntity(entity) end
function NetworkRequestControlOfEntity(entity) end

-- Object natives
function CreateObject(modelHash, x, y, z, isNetwork, bScriptHostVehicle, dynamic, p7) end
function CreateObjectNoOffset(modelHash, x, y, z, isNetwork, bScriptHostVehicle, dynamic, p7) end
function DeleteObject(object) end
function GetObjectOffsetFromCoords(x, y, z, heading, xOffset, yOffset, zOffset) end
function SetObjectTargettable(object, targettable) end
function SetObjectPhysicsParams(object, mass, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) end
function PlaceObjectOnGroundProperly(object) end
function GetClosestObjectOfType(x, y, z, radius, modelHash, p5, p6, p7) end
function IsObjectAPortableLadder(object) end
function DoesObjectOfTypeExistAtCoords(x, y, z, radius, modelHash, p5) end

-- Ped natives
function CreatePed(pedType, modelHash, x, y, z, heading, isNetwork, bScriptHostPed) end
function CreateRandomPed(x, y, z, heading) end
function DeletePed(ped) end
function ClonePed(ped, isNetwork, bScriptHostPed, linkBlai) end
function SetPedDefaultOutfit(ped) end
function SetPedOutfitPreset(ped, preset, p2) end
function SetPedRandomComponentVariation(ped, p1) end
function SetPedRandomProps(ped) end
function SetPedComponentEnabled(ped, componentId, drawableId, textureId, paletteId) end
function GetPedDrawableVariation(ped, componentId) end
function GetPedTextureVariation(ped, componentId) end
function GetPedPaletteVariation(ped, componentId) end
function SetPedPropIndex(ped, propId, drawableId, textureId, attach) end
function SetPedPreloadPropData(ped, propId, drawableId, textureId) end
function GetPedPropIndex(ped, propId) end
function GetPedPropTextureIndex(ped, propId) end
function SetPedArmour(ped, armour) end
function GetPedArmour(ped) end
function SetPedMaxHealth(ped, maxHealth) end
function GetPedMaxHealth(ped) end
function SetPedAsCop(ped, toggle) end
function SetPedAsEnemy(ped, toggle) end
function SetPedCanSwitchWeapon(ped, toggle) end
function SetPedCanRagdoll(ped, toggle) end
function SetPedCanRagdollFromPlayerImpact(ped, toggle) end
function SetPedDropsWeaponsWhenDead(ped, toggle) end
function SetPedDiesInWater(ped, toggle) end
function SetPedDiesWhenInjured(ped, toggle) end
function SetPedFleeAttributes(ped, attribute, p2) end
function SetPedHearingRange(ped, range) end
function SetPedVisualFieldMaxAngle(ped, angle) end
function SetPedVisualFieldMinAngle(ped, angle) end
function SetPedVisualFieldMaxElevationAngle(ped, angle) end
function SetPedVisualFieldMinElevationAngle(ped, angle) end
function SetPedSeeingRange(ped, range) end
function SetPedAccuracy(ped, accuracy) end
function SetPedCombatAttributes(ped, attribute, toggle) end
function SetPedCombatMovement(ped, combatMovement) end
function SetPedCombatRange(ped, combatRange) end
function SetPedFiringPattern(ped, patternHash) end
function SetPedShootRate(ped, shootRate) end
function SetPedRelationshipGroupHash(ped, relGroup) end
function SetPedRelationshipGroupDefaultHash(ped, relGroup) end
function SetPedIntoVehicle(ped, vehicle, seat) end
function SetPedGravity(ped, gravity) end
function SetPedRagdollOnCollision(ped, toggle) end
function SetPedToRagdoll(ped, time1, time2, ragdollType, p4, p5, p6) end
function SetPedToRagdollWithFall(ped, time, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13) end
function SetPedToRagdollWithDelay(ped, time_ms, p2, p3, p4, p5, p6) end
function SetPedUsingActionMode(ped, toggle, p2, p3) end
function SetPedMoveRateOverride(ped, value) end
function ApplyDamageToPed(ped, damageAmount, p2, p3, weaponHash) end
function SetPedMinGroundTimeForStungun(ped, ms) end
function IsPedDeadOrDying(ped, p1) end
function IsPedInjured(ped) end
function IsPedHurt(ped) end
function IsPedFatallyInjured(ped) end
function IsPedAPlayer(ped) end
function IsPedHuman(ped) end
function IsPedMale(ped) end
function IsPedOnFoot(ped) end
function IsPedOnVehicle(ped) end
function IsPedOnMount(ped) end
function IsPedSittingInVehicle(ped, vehicle) end
function IsPedSittingInAnyVehicle(ped) end
function IsPedGettingIntoAVehicle(ped) end
function IsPedTryingToEnterALockedVehicle(ped) end
function IsPedInAnyHeli(ped) end
function IsPedInAnyPlane(ped) end
function IsPedInAnyBoat(ped) end
function IsPedInAnySub(ped) end
function IsPedInAnyTaxi(ped) end
function IsPedInAnyTrain(ped) end
function IsPedClimbing(ped) end
function IsPedVaulting(ped) end
function IsPedDiving(ped) end
function IsPedJumpingOutOfVehicle(ped) end
function IsPedShooting(ped) end
function IsPedReloading(ped) end
function IsPedArmed(ped, weaponType) end
function IsPedBeingArrested(ped) end
function IsPedBeingStunned(ped, p1) end
function IsPedFleeing(ped) end
function IsPedInCover(ped, p1) end
function IsPedInAnyPoliceVehicle(ped) end
function IsPedHeadTracking(ped) end
function IsPedPerformingMeleeAction(ped) end
function IsPedPlantingBomb(ped) end
function IsPedSwimming(ped) end
function IsPedWalking(ped) end
function IsPedRunning(ped) end
function IsPedSprinting(ped) end
function IsPedStopped(ped) end
function IsPedWearingHelmet(ped) end
function GetPedBoneCoords(ped, boneId, offsetX, offsetY, offsetZ) end
function GetPedBoneIndex(ped, boneId) end
function GetPedLastDamageBone(ped, outBone) end
function GetPedCauseOfDeath(ped) end
function GetPedTimeOfDeath(ped) end
function GetPedParachuteState(ped) end
function GetPedParachuteLandingType(ped) end
function GetPedStealthMovement(ped) end
function GetPedAlertness(ped) end
function GetPedDesiredHeading(ped) end
function GetPedAccuracy(ped) end
function GetPedType(ped) end
function GetPedRelationshipGroupHash(ped) end
function GetPedGroup(ped, groupHash) end
function GetPedNearbyVehicles(ped, sizeAndVehs) end
function GetPedNearbyPeds(ped, p1, p2) end
function GetPedInCover(ped) end
function CreateGroup(unused) end
function SetGroupFormation(groupId, formationType) end
function SetGroupSeparationRange(groupId, separationRange) end
function SetPedAsGroupMember(ped, groupId) end
function SetPedAsGroupLeader(ped, groupId) end
function RemoveGroup(groupId) end
function GetPedGroup(ped, groupId) end
function IsPedGroupMember(ped, groupId) end
function DoesGroupExist(groupId) end
function GetGroupSize(groupId, unknown, pedsInGroup, groupMembersCount) end

-- Weapon natives
function GetSelectedPedWeapon(ped, weaponHash) end
function SetCurrentPedWeapon(ped, weaponHash, equipment, p3, p4, p5) end
function GetCurrentPedWeapon(ped, weaponHash, p2) end
function GetPedWeaponTintIndex(ped, weaponHash) end
function SetPedWeaponTintIndex(ped, weaponHash, tintIndex) end
function GiveWeaponToPed(ped, weaponHash, ammoCount, isHidden, bForceInHand) end
function GiveWeaponComponentToPed(ped, weaponHash, componentHash) end
function RemoveWeaponFromPed(ped, weaponHash) end
function RemoveAllPedWeapons(ped, reset) end
function HasPedGotWeapon(ped, weaponHash, p2) end
function GetPedAmmoByType(ped, ammoType) end
function SetPedAmmoByType(ped, ammoType, ammo) end
function AddAmmoToPed(ped, weaponHash, ammo) end
function SetPedInfiniteAmmo(ped, toggle, weaponHash) end
function SetPedInfiniteAmmoClip(ped, toggle) end
function SetPedAmmo(ped, weaponHash, ammo) end
function GetWeaponTintCount(weaponHash) end
function GetWeaponComponentTintCount(weaponHash, componentHash) end
function GetWeaponDamageType(weaponHash) end
function GetWeaponClipSize(weaponHash) end
function GetWeaponTimeBetweenShots(weaponHash) end
function GetWeaponSpread(weaponHash) end
function GetWeaponSpraySpread(weaponHash) end
function GetWeaponRange(weaponHash) end
function GetWeaponAccuracy(weaponHash) end
function GetWeaponRumble(weaponHash, p1) end
function GetWeaponLaserSight(weaponHash) end
function GetWeaponFlashlight(weaponHash) end
function GetWeaponSuppressor(weaponHash) end
function GetWeaponGrip(weaponHash) end
function GetWeaponAnim(weaponHash, p1) end
function GetWeaponComponentHudStats(componentHash, outData) end
function GetWeaponHudStats(weaponHash, outData) end
function MakePedReload(ped) end

-- Network / Player natives
function NetworkIsPlayerActive(player) end
function NetworkIsPlayerConnected(player) end
function NetworkGetPlayerIndexFromPed(ped) end
function NetworkGetEntityOwner(entity) end
function NetworkGetNetworkIdFromEntity(entity) end
function NetworkGetEntityFromNetworkId(netId) end
function NetworkDoesNetworkIdExist(netId) end
function NetworkIsDoorNetworked(doorHandle) end
function NetworkRequestControlOfNetworkId(netId) end
function NetworkHasControlOfNetworkId(netId) end
function NetworkSetNetworkIdDynamic(netId, toggle) end
function NetworkSetEntityInvisibleToPlayer(entity, player, toggle) end
function NetworkSetEntityVisibleToPlayers(entity, toggle) end
function NetworkConcealEntity(entity, toggle) end
function NetworkConcealPlayer(toggle, p1) end
function NetworkSetLocalPlayerInvincibleTime(time) end
function NetworkFadeInEntity(entity, state, p2) end
function NetworkFadeOutEntity(entity, normal, slow) end
function GetPlayerPed(player) end
function GetPlayerServerId(player) end
function GetPlayerName(player) end
function GetPlayerFromServerId(serverId) end
function GetActivePlayers() end
function GetNumberOfPlayers() end
function SetPlayerControl(player, enabled, flags) end
function IsPlayerFreeAiming(player) end
function IsPlayerTargetingAnything(player) end
function IsPlayerScriptControlOn(player) end
function IsPlayerSwitchInProgress() end
function SetPlayerWantedLevel(player, wantedLevel, disableNoMission) end
function SetPlayerWantedLevelNow(player, p1) end
function SetPlayerWantedLevelNoDrop(player, wantedLevel, p2) end
function SetPlayerMayOnlyUseThisVehicle(player, vehicle) end
function SetPlayerMayNotEnterAnyVehicle(player) end
function SetPlayerInvincible(player, toggle) end
function SetPlayerCanUseCover(player, toggle) end
function SetPlayerLockon(player, toggle) end
function SetPlayerLockonRangeOverride(player, range) end
function SetPlayerTargetingMode(player, mode) end
function GetPlayerWantedLevel(player) end
function GetPlayerWantedCentrePosition(player) end
function IsPlayerWantedLevelGreater(player, wantedLevel) end
function ClearPlayerWantedLevel(player) end
function SetEveryoneIgnorePlayer(player, toggle) end
function SetPoliceIgnorePlayer(player, toggle) end
function SetDispatchCopsPlayer(player, toggle) end
function IsSpecialAbilityActive(player) end
function IsSpecialAbilityUnlocked(player) end
function SetSpecialAbility(player, toggle) end
function SpecialAbilityChargeSmall(player, p1, p2, p3) end
function SpecialAbilityChargeLarge(player, p1, p2, p3) end
function SpecialAbilityDeactivate(player) end
function SpecialAbilityChargeAbsolute(player, p1, p2) end
function ResetSpecialAbility(player) end
function GetPlayerReserveParachuteTintIndex(player, tintIndex) end
function SetPlayerReserveParachuteTintIndex(player, index) end
function SetPlayerReserveParachuteModelOverride(player, model) end
function GivePlayerRagdollControl(player, toggle) end
function SetPlayerStealthPerceptionModifier(player, modifier) end

-- Interiors / MLO natives
function GetInteriorAtCoords(x, y, z) end
function GetInteriorFromEntity(entity) end
function GetInteriorHeading(interior) end
function GetInteriorInfo(interior, pitch, yaw) end
function GetInteriorMapEntityTint(interior, element, tint) end
function GetKeyForEntityInRoom(entity) end
function GetOffsetFromInteriorInWorldCoords(interior, x, y, z) end
function GetRoomKeyForGameViewport(viewport) end
function ActivateInteriorEntitySet(interior, entitySetName) end
function DeactivateInteriorEntitySet(interior, entitySetName) end
function SetInteriorEntitySetColor(interior, entitySet, color) end
function RefreshInterior(interior) end
function IsInteriorEntitySetActive(interior, entitySetName) end
function PinInteriorInMemory(interior) end
function UnpinInterior(interior) end
function IsInteriorReady(interior) end
function IsValidInterior(interior) end
function ClearRoomForEntity(entity) end
function SetRoomForEntityByKey(entity, roomKey) end
function SetRoomForGameViewportByName(viewport, roomName) end
function GetRoomKeyForEntity(entity) end

-- Animation natives
function RequestAnimDict(animDict) end
function HasAnimDictLoaded(animDict) end
function HasAnimLoaded(animSet) end
function RemoveAnimDict(animDict) end
function RemoveAnimSet(animSet) end
function DoesAnimDictExist(animDict) end

-- Graphics / UI natives
function SetTextFont(fontType) end
function SetTextScale(scale, scale) end
function SetTextColour(r, g, b, alpha) end
function SetTextCentre(align) end
function SetTextEntry(textEntry) end
function AddTextComponentString(text) end
function DrawText(x, y) end
function DrawRect(x, y, width, height, r, g, b, alpha) end
function DrawSprite(textureDict, textureName, screenX, screenY, width, height, heading, r, g, b, alpha) end
function SetScriptGfxDrawOrder(drawOrder) end
function SetScriptGfxDrawBehindPausemenu(toggle) end
function SetDrawOrigin(x, y, z, p3) end
function ClearDrawOrigin() end
function DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, alpha) end
function DrawPoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, alpha) end
function DrawBox(x1, y1, z1, x2, y2, z2, r, g, b, alpha) end
function DrawMarker(type, x, y, z, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, r, g, b, alpha, bob, faceCam, p19, rotate, textureDict, textureName, drawOnEntity) end
function CreateCheckpoint(type, x1, y1, z1, x2, y2, z2, radius, r, g, b, alpha, reserved) end
function SetCheckpointRgba(checkpoint, r, g, b, alpha) end
function DeleteCheckpoint(checkpoint) end
function SetBlipHiddenOnLegend(blip, hidden) end
function SetBlipLabel(blip, label) end
function SetBlipLabelScale(blip, scale) end
function SetBlipAsFriendly(blip, toggle) end
function SetBlipAsMissionCreator(blip, toggle) end

-- Water natives
function GetWaterHeight(x, y, z, height) end
function TestVerticalProbeAgainstAllWater(x, y, z, p3, p4, height) end
function ModifyWater(x, y, radius, height) end
function SetDeepOceanScaler(intensity) end
function SetWavesIntensity(intensity) end

-- Fire natives
function StartEntityFire(entity) end
function StopEntityFire(entity) end
function IsEntityOnFire(entity) end
function GetEntityFire(entity) end
function AddExplosion(x, y, z, explosionType, damageScale, isAudible, isInvisible, cameraShake) end
function AddOwnedExplosion(ped, x, y, z, explosionType, damageScale, isAudible, isInvisible, cameraShake) end

-- Pathfinding / Navigation natives
function GetClosestMajorVehicleNode(x, y, z, nodePosition, nodeType, p5, p6) end
function GetClosestVehicleNode(x, y, z, nodePosition, nodeType, p5, p6) end
function GetClosestRoad(x, y, z, p3, p4, p5, p6, p7, p8) end
function GetNthClosestVehicleNode(x, y, z, nthClosest, nodePosition, unknown1, unknown2, unknown3) end
function GetNthClosestVehicleNodeId(x, y, z, nthClosest, unknown1, unknown2, unknown3) end
function GetRandomVehicleNode(x, y, z, radius, isSpawned, nodePosition, nodeId) end
function GetRandomVehicleNodeInSphere(x, y, z, radius, isSpawned, nodePosition, nodeId) end
function IsVehicleNodeIdValid(nodeId) end
function LoadAllPathNodes(load) end
function SetRoadsBackToOriginal(x, y, z, radius, p4) end
function SetRoadsInArea(x, y, z, radius, p4, toggle) end
function SetPedPathsInArea(x, y, z, radius, toggle) end
function GetVehicleNodePosition(nodeId, nodePosition) end
function CalculateTravelDistanceBetweenPoints(x1, y1, z1, x2, y2, z2) end
function GetLandingTargetForParachute(ped, targetPosition) end

-- Time / Weather natives
function SetTimecycleModifier(modifierName) end
function GetTimecycleModifierIndex() end
function SetTimecycleModifierStrength(strength) end
function SetTransitionTimecycleModifier(modifierName, transition) end
function ClearTimecycleModifier() end
function GetClockHours() end
function GetClockMinutes() end
function GetClockSeconds() end
function SetClockTime(hour, minute, second) end
function SetClockDate(day, month, year) end
function PauseClock(toggle) end
function GetPosixTime() end
function SetWeatherTypeNow(weatherType) end
function SetWeatherTypeNowPersist(weatherType) end
function SetWeatherTypeOverTime(weatherType, time) end
function SetWeatherTypePersist(weatherType) end
function ClearWeatherTypePersist() end
function GetPrevWeatherType(weatherType) end
function GetNextWeatherType(weatherType) end
function IsNextWeatherType(weatherType) end
function GetRainLevel() end
function GetSnowLevel() end
function GetWindSpeed() end
function SetWindSpeed(speed) end
function SetWindDirection(direction) end
function GetWindDirection() end
function SetGravityLevel(level) end

-- Audio natives
function PlayStreamFromPosition(soundDict, soundName, x, y, z, p5, p6) end
function PlayStreamFrontend(soundDict, soundName, p2, p3) end
function StopStream() end
function StopStreamFrontend() end
function HasStreamFinished() end
function LoadStream(streamName, soundSet) end
function LoadStreamWithStartOffset(streamName, startOffset, soundSet) end
function SetStreamVariable(variableName, value) end

-- Rope natives
function AddRope(x, y, z, rotX, rotY, rotZ, length, ropeType, maxLength, minLength, windingSpeed, p11, p12, p13, p14, breakable) end
function DeleteRope(rope) end
function DeleteChildRope(rope) end
function RopeLoadTextures() end
function RopeAreTexturesLoaded() end
function RopeForceLength(rope, length) end
function RopeResetLength(rope, length) end
function RopeSetUpdatePinverts(rope) end
function RopeSetUpdateOrder(rope, order) end
function ActivatePhysics(entity) end
function AttachEntitiesToRope(rope, entity1, entity2, x1, y1, z1, x2, y2, z2, length, p10, p11, p12) end
function AttachRopeToEntity(rope, entity, x, y, z, p5) end
function DetachRopeFromEntity(rope, entity) end
function GetRopeLength(rope) end
function GetRopeVertexCount(rope) end
function RopeConvertToSimple(rope) end
function SetDamping(entity, vertex, damping) end
function SetDisableBreaking(rope, enabled) end
function SetRopeClosestPoint(rope, x, y, z, p4) end

-- Stats / Globals natives
function StatGetInt(statHash, outValue, p2) end
function StatGetFloat(statHash, outValue, p2) end
function StatGetBool(statHash, outValue, p2) end
function StatSetInt(statHash, value, save) end
function StatSetFloat(statHash, value, save) end
function StatSetBool(statHash, value, save) end
function SetProfileSetting(profileSetting, value) end
function GetProfileSetting(profileSetting) end

-- Mobile / Phone natives
function CellCamActivate(p0, p1) end
function CellCamIsCharVisibleNoEntityCheck() end
function CreateMobilePhone(phoneType) end
function DestroyMobilePhone() end
function SetMobilePhonePosition(posX, posY, posZ) end
function SetMobilePhoneScale(scale) end
function SetMobilePhoneRotation(rotX, rotY, rotZ, p3) end
function GetMobilePhoneRotation(rotation) end
function GetMobilePhonePosition(position) end
function ScriptIsMovingMobilePhoneOffscreen(flag) end
function CanPhoneBeSeenOnScreen() end
function SetMobilePhoneRadioState(toggle) end
function CellSetMouseOver(useMouseOver) end
function CellSetBlurBackground(toggle) end
function CellSetListMaxDisplayItems(maxItems) end
function CellSetListItemState(index, state) end
function CellSetListSelection(index) end
function CellSetListSelectionBackground(visible) end
function CellGetListItemNumber(index) end
function CellGetListSelection() end
function CellGetListMaxDisplayItems() end
function CellHasDisplayedItem(index) end
function CellSetCameraZoom(zoom) end

-- Datafile natives
function DatafileWatchRequestId(id) end
function DatafileHasLoadedFileData(fileIndex) end
function DatafileGetFileDict(fileIndex) end
function DatafileCreateDate(innerType, name) end
function UgcGetContentUserId(p0, p1) end
function UgcGetContentRatingCount(p0, p1) end
function UgcGetContentRatingPositiveCount(p0, p1) end
function UgcGetContentRatingNegativeCount(p0, p1) end
function UgcGetContentHasPlayerBookmarked(p0, p1) end
function UgcGetContentIsPublished(p0, p1) end
function UgcGetContentIsVerified(p0, p1) end
function UgcGetContentLanguage(p0, p1) end
function UgcGetContentCategory(p0, p1) end

-- Ragdoll / Physics natives
function SetRagdollBlockingFlags(ped, flags) end
function SetRagdollOnCollision(ped, toggle) end
function SetPedRagdollForceFall(ped) end
function HasPedGotUpFromRagdoll(ped) end
function SetCharacterTest(ped, p1, p2) end
function ResetRagdollTimer(ped) end

-- Decorative / Prop natives
function AddBolas(ped, p1, p2, p3, p4, p5, p6) end
function SetPedPropTextureIndex(ped, propId, textureId) end
function ClearPedProp(ped, propId) end
function ClearPedProps(ped) end
function ClearPedWetness(ped) end
function ClearPedBloodDamage(ped) end
function ClearPedBloodDamageByZone(ped, zone) end
function ClearPedEnvDirt(ped) end
function PedHasPermissionToDive(ped) end
function PedIsArrested(ped) end
function SetPedHelmet(ped, toggle) end
function SetPedHelmetFlag(ped, helmetFlag) end
function SetPedHelmetPropIndex(ped, propIndex) end
function SetPedHelmetTextureIndex(ped, textureIndex) end
function SetPedTexBlendSet(ped, p1, p2) end

-- Misc natives
function GetHashKey(input) end
function SetScenarioTypeEnabled(scenarioType, toggle) end
function ResetScenarioTypesEnabled() end
function UsePedHairGloss(useGloss) end
function UseVehicleTargeting(useFlag) end
function IsBitSet(value, bit) end
function SetBit(value, bit) end
function ClearBit(value, bit) end
function StartScriptFire(posX, posY, posZ, maxChildren, isGasFire) end
function RemoveScriptFire(fireHandle) end
function GetRandomFloatInRange(startRange, endRange) end
function GetRandomIntInRange(startRange, endRange) end
function GetGroundZFor_3dCoord(x, y, z, groundZ, p4, p5) end
function SetPtfxAssetNextCall(textureDict) end
function SetNumberOfPtfxEntries(numEntries) end
function UseParticleFxAsset(textureDict) end
function StartParticleFxLoopedAtCoord(effectName, x, y, z, xRot, yRot, zRot, scale, p8, p9, p10, p11) end
function StartParticleFxLoopedOnEntity(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale, p9, p10, p11, p12) end
function StartParticleFxNonLoopedAtCoord(effectName, x, y, z, xRot, yRot, zRot, scale, p8, p9, p10, p11) end
function StartParticleFxNonLoopedOnPedBone(effectName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, boneIndex, scale, p9, p10, p11) end
function StartParticleFxNonLoopedOnEntity(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale, p8, p9, p10, p11) end
function RemoveParticleFx(effectName, p1) end
function RemoveParticleFxFromEntity(entity) end
function RemoveParticleFxInRange(x, y, z, radius) end
function DoesParticleFxLoopedExist(ptfxHandle) end
function StopParticleFxLooped(ptfxHandle, p1) end
function SetParticleFxLoopedColour(ptfxHandle, r, g, b, p4) end
function SetParticleFxLoopedAlpha(ptfxHandle, alpha) end
function SetParticleFxLoopedScale(ptfxHandle, scale) end
function SetParticleFxLoopedFarClipDist(ptfxHandle, range) end
function SetParticleFxNonLoopedColour(r, g, b) end
function SetParticleFxNonLoopedAlpha(alpha) end
function SetParticleFxShootoutBoat(p0) end
function N_0x0000000000000000() end

-- Unk / Internal
function GetLabelText(labelName) end
function FindKvpInt(key) end
function FindKvpString(key) end
function SetResourceKvpInt(key, value) end
function SetResourceKvpString(key, value) end
function DeleteResourceKvp(key) end
function StartFindKvp(findHandle) end
function FindKvp(findHandle) end
function EndFindKvp(findHandle) end
function GetResourceKvpString(key) end
function GetResourceKvpInt(key) end
function RegisterCommand(commandName, handler, restricted) end
function RegisterKeyMapping(command, description, group, key) end
function RegisterConsoleListener(listener) end

-- Building natives
function GetInteriorAtCoordsWithType(x, y, z, interiorType) end
function CreateNewScriptedInterior(interiorSet) end
function ActivateInteriorEntitySet(interiorId, entitySetName) end
function SetInteriorEntitySetColor(interiorId, entitySet, color) end
function DeactivateInteriorEntitySet(interiorId, entitySetName) end
function RefreshInterior(interiorId) end
function PinInteriorInMemory(interiorId) end
function UnpinInterior(interiorId) end
function IsInteriorReady(interiorId) end
function GetInteriorName(interiorId) end
function GetOffsetFromInteriorInWorldCoords(interiorId, x, y, z) end

-- Door natives
function AddDoorToSystem(doorHash, modelHash, x, y, z, p5, p6, p7) end
function DoorSystemSetDoorState(doorHash, state, p2, p3) end
function DoorSystemGetDoorPending(doorHash) end
function DoorSystemSetAutomaticDistance(doorHash, distance, p2, p3) end
function DoorSystemSetOpenRatio(doorHash, ratio, p2, p3) end
function GetDoorSystemState(doorHash) end
function RemoveDoorFromSystem(doorHash) end
function IsDoorValid(doorHash) end

-- Decal natives
function AddDecal(decalType, posX, posY, posZ, dirX, dirY, dirZ, p7, p8, p9, width, height, r, g, b, alpha, timeout, p17, p18, p19) end
function RemoveDecal(decal) end
function RemoveAllDecalsFromObjectHeld(entity) end
function RemoveDecalsInRange(x, y, z, range) end
function RemoveDecalsFromObject(object) end
function RemoveDecalsFromObjectFade(object, fade) end
function SetDecalTexture(decal, textureDict, textureName) end
function IsDecalAlive(decal) end
function GetDecalAliveCount() end

-- Scaleform natives
function RequestScaleformMovie(scaleformName) end
function HasScaleformMovieLoaded(scaleformHandle) end
function SetScaleformMovieAsNoLongerNeeded(scaleformHandle) end
function DrawScaleformMovie(scaleformHandle, x, y, width, height, r, g, b, alpha, p8) end
function DrawScaleformMovieFullscreen(scaleformHandle, r, g, b, alpha, p4) end
function DrawScaleformMovieFullscreenMasked(scaleformHandle, r, g, b, alpha) end
function PushScaleformMovieFunction(scaleformHandle, functionName) end
function PushScaleformMovieFunctionParameterBool(value) end
function PushScaleformMovieFunctionParameterFloat(value) end
function PushScaleformMovieFunctionParameterInt(value) end
function PushScaleformMovieFunctionParameterString(value) end
function PopScaleformMovieFunctionVoid() end
function BeginScaleformMovieMethod(scaleformHandle, functionName) end
function BeginScaleformMovieMethodReturnValue(scaleformHandle, functionName) end
function EndScaleformMovieMethod() end
function EndScaleformMovieMethodReturnValue() end
function CallScaleformMovieMethod(scaleformHandle, functionName) end
function CallScaleformMovieMethodWithNumber(scaleformHandle, functionName, param1, param2, param3, param4, param5) end
function CallScaleformMovieMethodWithString(scaleformHandle, functionName, param1) end
function CallScaleformMovieMethodWithBool(scaleformHandle, functionName, param1) end
function CallScaleformMovieMethodWithFloat(scaleformHandle, functionName, param1) end
function HasScaleformScriptHudLoaded(scaleformHandle) end
function HasScaleformContainerMovieLoadedIntoParent(scaleformHandle) end

-- Streaming natives
function RequestModel(modelHash) end
function HasModelLoaded(modelHash) end
function SetModelAsNoLongerNeeded(modelHash) end
function IsModelInCdimage(modelHash) end
function IsModelValid(modelHash) end
function RequestCollisionAtCoord(x, y, z) end
function RequestAdditionalCollisionAtCoord(x, y, z) end
function HasCollisionForModelLoaded(modelHash) end
function RequestIpl(iplName) end
function RemoveIpl(iplName) end
function SetIplPropState(iplName, propName, state, p3) end
function IsIplActive(iplName) end
function GetIplGroup(iplName) end
function GetNumberOfInstancesOfStreamedScript(scriptHash) end
function SetStreamedTextureDictAsNoLongerNeeded(textureDict) end
function RequestStreamedTextureDict(textureDict, p1) end
function HasStreamedTextureDictLoaded(textureDict) end
function SetStreamedTexturesAsNoLongerNeeded(textureDict) end
function LoadScene(x, y, z, p3) end
function NetworkStopLoadingScreen() end
function NetworkRemoveEntityFromScript(entity, p1) end
function SetEntityAsMissionEntity(entity, p1, p2) end
function SetEntityAsNoLongerNeeded(entity) end
function SetPedAsNoLongerNeeded(ped) end
function SetVehicleAsNoLongerNeeded(vehicle) end
function SetObjectAsNoLongerNeeded(object) end

-- Train natives
function SetRandomTrains(toggle) end
function CreateMissionTrain(variation, x, y, z, heading) end
function DeleteMissionTrain(train) end
function SetMissionTrainAsNoLongerNeeded(train, p1) end
function SetTrainCruiseSpeed(train, speed) end
function SetTrainSpeed(train, speed) end
function SetTrainIsStopped(train, toggle) end
function SetTrainTrack(trainTrack, toggle) end
function GetTrainCarriage(train, carriage) end
function IsMissionTrain(train) end
function GetTrainCurrentTrackNode(train) end
function GetTrainDoorOpenRatio(train, door) end
function SetTrainDoorOpenRatio(train, door, ratio) end

-- Ped Model natives
function AddRelationshipGroup(groupName) end
function GetRelationshipBetweenPeds(ped1, ped2) end
function SetRelationshipBetweenGroups(relationship, group1, group2) end
function ClearRelationshipBetweenGroups(relationship, group1, group2) end
function DoesRelationshipGroupExist(group) end
function GetPedRelationshipGroupDefaultHash(ped) end
function GetRelationshipBetweenGroups(relationship, group1, group2) end
function SetPedRelationshipGroupHash(ped, hash) end
function SetPedRelationshipGroupDefaultHash(ped, hash) end

-- Text natives
function AddTextLabel(labelName, text) end
function AddTextLabelString(labelName, string) end
function BeginTextCommandDisplayText(text) end
function EndTextCommandDisplayText(x, y) end
function BeginTextCommandWidth(text) end
function EndTextCommandGetWidth(p1) end
function BeginTextCommandLineCount(text) end
function EndTextCommandGetLineCount(x, y) end
function AddTextComponentInteger(value) end
function AddTextComponentFloat(value, decimalPlaces) end
function AddTextComponentPlayerName(text) end
function AddTextComponentSubstringTime(time, flags) end
function AddTextComponentSubstringWebsite(text) end
function AddTextComponentSubstringKey(key) end
function SetTextScaleForEdgeDistance(p0, scale) end
function SetTextDropshadow(distance, r, g, b, alpha) end
function SetTextEdge(p0, r, g, b, alpha) end
function SetTextOutline() end
function SetTextJustification(justifyType) end
function SetTextWrap(startX, endX) end
function SetTextLeading(p0, p1) end
function SetTextProportional(toggle) end
function SetTextRenderId(renderId) end
function SetTextRightJustify(toggle) end

-- Shape test natives
function StartShapeTestRay(x1, y1, z1, x2, y2, z2, flags, entity, p8) end
function StartShapeTestBox(x, y, z, dimX, dimY, dimZ, rotX, rotY, rotZ, p9, flags, entity, p12) end
function StartShapeTestCapsule(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end
function GetShapeTestResult(shapeTestHandle) end
function GetShapeTestResultEx(shapeTestHandle) end
function StartShapeTestBound(entity, flags, p2) end
function StartShapeTestBoundBox(entity, flags, p2) end

-- World / Water natives
function GetWaterHeight(x, y, z, height) end
function SetWaterHeightForUV(p0, p1) end
function SetWaterHeight(x, y, z, height, p4) end
function TestProbeAgainstAllWater(x1, y1, z1, x2, y2, z2, flags, height) end
function TestVerticalProbeAgainstAllWater(x, y, z, p3, p4, height) end

-- Ped movement / vehicle exit
function GetPedConfigFlag(ped, flagId, p2) end
function SetPedConfigFlag(ped, flagId, toggle) end
function SetPedResetFlag(ped, flagId, toggle) end
function SetPedAllowedToDuck(ped, toggle) end
function SetPedGesture(ped, gestureHash, p2) end
function SetPedLodMultiplier(ped, multiplier) end
function SetPedFacialIdleAnimOverride(ped, animName, animDict) end
function SetPedCanPlayAmbientAnims(ped, toggle) end
function SetPedCanPlayAmbientBaseAnims(ped, toggle) end
function SetPedCanPlayGestures(ped, toggle) end
function SetPedCanUseAutoConversationLookat(ped, toggle) end
function IsPedInAnyVehicle(ped, atGetIn) end
function IsPedInModel(ped, modelHash) end
function IsPedInAnyPlane(ped) end
function IsPedInAnyHeli(ped) end
function IsPedInAnyTrain(ped) end
function IsPedInAnyBoat(ped) end
function IsPedInAnySub(ped) end
function IsPedInAnyTaxi(ped) end
function IsPedSittingInVehicle(ped, vehicle) end
function IsPedSittingInAnyVehicle(ped) end
function IsPedGettingIntoAVehicle(ped) end
function IsPedGettingUp(ped) end
function IsPedInMeleeCombat(ped) end
function IsPedRespondingToEvent(ped, event) end
function IsPedPerformingStealthKill(ped) end
function GetPedConfigFlag(ped, flagId, p2) end
function GetVehicleIsConsideredByPlayer(vehicle) end

-- Door System
function AddDoorToSystem(doorHash, modelHash, posX, posY, posZ, p5, p6, p7) end
function DoorSystemGetActive(doorHash) end
function DoorSystemSetHoldOpen(doorHash, toggle) end
function DoorSystemSetDoorState(doorHash, state, p2, p3) end
function DoorSystemGetDoorPending(doorHash) end
function DoorSystemSetAutomaticDistance(doorHash, distance, p2, p3) end
function DoorSystemSetOpenRatio(doorHash, ratio, p2, p3) end
function RemoveDoorFromSystem(doorHash) end
function IsDoorValid(doorHash) end
function GetDoorSystemState(doorHash) end
function SetDoorControl(doorHash, toggle, p2) end

-- Decision Maker
function AddTrevorRandomModifier(p0) end
function IsPedOnAnyBike(ped) end
function IsPedOnAnyBoat(ped) end
function IsPedOnAnyPlane(ped) end
function IsPedOnAnyHeli(ped) end
function IsPedOnFoot(ped) end
function IsPedOnMount(ped) end
function IsPedOnVehicle(ped) end

-- Vehicle extras
function CreateVehicle(modelHash, x, y, z, heading, isNetwork, bScriptHost, p7) end
function SetEntityMaxSpeed(entity, speed) end
function SetEntityMotionBlur(entity, toggle) end
function CreateLight(p0, p1, p2, p3, p4, ...) end
function SetVehicleEngineCanDegrade(vehicle, toggle) end
function DoesVehicleHaveRoof(vehicle) end
function IsVehicleDamaged(vehicle) end
function IsVehicleDriveable(vehicle, p1) end
function IsVehicleEngineStarting(vehicle) end
function SetVehicleDeformationFixed(vehicle) end
function SetVehicleDisableTowing(vehicle, toggle) end
function SetVehicleDropsMoneyWhenDestroyed(vehicle, toggle) end
function SetVehicleHasStrongAxle(vehicle, toggle) end
function SetVehicleIsWanted(vehicle, toggle) end
function SetVehicleIsConsideredByPlayer(vehicle, toggle) end
function SetVehicleProvidesCover(vehicle, toggle) end
function SetVehicleDensityMultiplierThisFrame(multiplier) end
function SetRandomVehicleDensityMultiplierThisFrame(multiplier) end
function SetParkedVehicleDensityMultiplierThisFrame(multiplier) end
function SetAmbientVehicleRangeMultiplierThisFrame(multiplier) end
function SetPedDensityMultiplierThisFrame(multiplier) end
function SetScenarioPedDensityMultiplierThisFrame(p0, p1, p2) end
function SetGarbageTrucks(toggle) end
function SetRandomBoats(toggle) end
function SetRandomTrains(toggle) end

-- Braindance (cutscene / mission)
function CreateCutscene(cutsceneName, p1, p2) end
function RequestCutscene(cutsceneName, p1) end
function HasCutsceneLoaded(cutsceneName) end
function RemoveCutscene() end
function StartCutscene(p0) end
function StartCutsceneAtCoords(x, y, z, p3) end
function StopCutscene(immediate) end
function WasCutsceneSkipped() end
function WasCutsceneSkippedByCutscene() end
function HasCutsceneFinished(cutsceneName) end
function GetCutsceneTime() end
function GetCutsceneTotalDuration() end
function SetCutsceneTriggerArea(p0, p1, p2, p3) end
function CanSetExitStateForRegisteredEntity(entity, cutscene, exitFlag) end
function RegisterEntityForCutscene(cutscenePed, cutsceneEnt, p2, p3, p4) end
function GetEntityIndexOfCutsceneEntity(cutsceneEnt, p1) end
function GetCutsceneEntityIndex(cutsceneEnt) end
function DoesCutsceneEntityExist(cutsceneEnt, entityHandle) end

-- Vehicle Escort / Tow
function SetVehicleSteeringAngle(vehicle, angle) end
function SetVehicleSteeringBias(vehicle, bias) end
function SetVehicleRampAndLaunchingGravity(p0) end
function GetVehicleSteeringAngle(vehicle) end
function IsVehicleSearchLightOn(vehicle) end
function IsVehicleStolen(vehicle) end
function IsVehiclePreviouslyOwnedByPlayer(vehicle) end
function SetVehiclePreviouslyOwnedByPlayer(vehicle, toggle) end

-- Cinematic
function DoAutoSave() end
function AbortAutoSave() end
function IsAutoSaveInProgress() end
function DoScreenFadeIn(duration) end
function DoScreenFadeOut(duration) end
function IsScreenFadedIn() end
function IsScreenFadedOut() end
function IsScreenFadingIn() end
function IsScreenFadingOut() end
function SetArtificialLightsState(toggle) end
function SetArtificialLightsStateAffectsVehicles(toggle) end
function DisableVehicleWorldCollision(toggle) end
function DisableLandingGear(vehicle, toggle) end
function HasEntityBeenDamagedByAnyPed(entity) end
function HasEntityBeenDamagedByAnyVehicle(entity) end
function HasEntityBeenDamagedByEntity(entity, damager, p2) end
function HasEntityClearLosToEntity(entity1, entity2, traceType) end
function HasEntityClearLosToEntityInFront(entity1, entity2) end

-- Audio - Radio
function SetRadioToStationName(stationName) end
function SetRadioToStationIndex(stationIndex) end
function SetVehRadioStation(vehicle, station) end
function GetPlayerRadioStationIndex() end
function GetPlayerRadioStationName() end
function ClearRadioStationPlaylist(station) end
function LockRadioStation(station, toggle) end
function UnlockRadioStation(station) end
function IsRadioStationExist(station) end
function IsRadioStationFadedOut(station) end
function IsRadioStationRetuning(station) end

-- Unclassified
function LoadMpTextDictionary(dictionary) end
function DoesTextDictionaryExist(dictionary) end
function DoesTextLabelExist(text) end
function GetCurrentLanguage() end
function IsLanguageCurrent(language) end
function GetStreetNameAtCoord(x, y, z, streetName, crossingRoad) end
function GetZoneName(coords) end
function GetZoneScumminessLevel(zoneId) end
function GetHashOfMapAreaAtCoords(x, y, z) end
function GetLandingTargetForParachute(ped, targetPos) end
function SetAllVehicleGeneratorsActiveInArea(x1, y1, z1, x2, y2, z2, toggle, p7) end
function SetAllVehicleGeneratorsActive(toggle) end
function SetAllLowGearVehicles(toggle) end
function SetEnableVehicleSlipstreaming(toggle) end
function SetFarDrawDistance(distance) end
function SetPedPopulationBudget(populationBudget) end
function SetPedPopulationCap(populationCap) end
function SetScenarioGroupEnabled(scenarioGroup, toggle) end
function SetAmbientPedRangeMultiplierThisFrame(multiplier) end
function SetAmbientVehicleRangeMultiplierThisFrame(multiplier) end
function DisableFirstPersonPhoneCamera(toggle) end

-- JSON
---@param str string
---@return table
function json.decode(str) end
---@param t table
---@param opts? table|string
---@return string
function json.encode(t, opts) end

-- Promise
---@class promise
---@field hasResolved fun(self): boolean
---@field result fun(self): any

---@return promise
function promise.new() end
---@return promise
function Promise.new() end

-- GlobalState
---@type table
GlobalState = {}

---@param key string
---@param value any
---@param replicated? boolean
function GlobalState.set(key, value, replicated) end

---@param key string
---@return any
function GlobalState.get(key) end

---@param key string
---@param cb fun(value: any)
function AddStateBagChangeHandler(key, cb) end

---@param bagName string
---@param key string
---@param cb fun(bagName: string, key: string, value: any)
function AddStateBagChangeHandler(key, bagName, cb) end

---@param key string
---@param value any
function SetConvar(key, value) end
function GetConvar(key, defaultValue) end
function GetConvarInt(key, default) end
function SetConvarReplicated(key, value) end
function SetConvarServerInfo(key, value) end

-- Entity
---@param entity number
---@return number
function Entity(entity) end

---@class Entity
---@field state EntityState

---@class EntityState
---@field set fun(self, key: string, value: any, replicated?: boolean)
---@field get fun(self, key: string): any

-- Player
---@param playerId number
---@return Entity
function Player(playerId) end

-- ox_target export definitions
---@class ox_target
---@field addModel fun(models: table|number, options: table): void
---@field addBoxZone fun(options: table): void
---@field removeZone fun(name: string): void
---@field removeModel fun(models: table|number): void
---@field addSphereZone fun(options: table): void
---@field addEntity fun(entity: number, options: table): void
---@field removeEntity fun(entity: number): void
---@field addGlobalModel fun(options: table): void
---@field removeGlobalModel fun(models: table|number): void
---@field addGlobalEntity fun(options: table): void
---@field removeGlobalEntity fun(entity: number): void
---@field addGlobalVehicle fun(options: table): void
---@field removeGlobalVehicle fun(modelHash: number): void
---@field addLocalEntity fun(entity: number, options: table): void
---@field removeLocalEntity fun(entity: number): void
---@field addAmmoList fun(ammoList: table): void
---@field removeAmmoList fun(ammoList: table): void
---@field getGlobalOptions fun(): table
---@field setGlobalOptions fun(options: table): void
---@field GetPlayerPed fun(): number
---@field GetClosestPlayer fun(): number
---@field GetPlayers fun(): number[]
---@field GetPlayersFromCoords fun(x: number, y: number, z: number, distance: number): number[]

exports.ox_target = nil

-- ox_inventory
---@class ox_inventory
---@field Search fun(source: number, count: number, slots: table, items: table|string): table
---@field AddItem fun(source: number, item: string, count: number, metadata?: table, slot?: number): number
---@field RemoveItem fun(source: number, item: string, count: number, metadata?: table, slot?: number): number
---@field GetItemCount fun(source: number, item: string, metadata?: table): number
---@field HasItem fun(source: number, item: string, metadata?: table): boolean
---@field GetCurrentWeapon fun(source: number): table
---@field GetInventory fun(source: number): table
---@field RegisterStash fun(stashId: string, label: string, slots: number, weight: number, owner?: string, groups?: table)
---@field OpenInventory fun(source: number, inventoryType: string, data: any, owner: number)
---@field GetSlots fun(source: number): number
---@field GetWeight fun(source: number): number

exports.ox_inventory = nil

-- PolyZone
---@class PolyZone
---@field new fun(points: table, options: table): PolyZone
---@field isPointInside fun(self, x: number, y: number): boolean
---@field onPlayerInOut fun(self, cb: function)
---@field destroy fun(self)

---@class BoxZone
---@field new fun(options: table): BoxZone
---@field isPointInside fun(self, x: number, y: number): boolean
---@field onPlayerInOut fun(self, cb: function)
---@field destroy fun(self)
---@field setRadius fun(self, radius: number)

exports['polyzone'] = nil
