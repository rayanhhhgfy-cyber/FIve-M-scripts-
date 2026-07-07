local currentDiagnosis = nil

RegisterNetEvent('advanced-mechanics:client:doFieldRepair', function(vehicleNetId, kitType)
  local kitConfig = Config.AdvancedMechanics.fieldRepairs[kitType]
  if not kitConfig then return end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle or not DoesEntityExist(vehicle) then return end
  local success = Wrappers.ProgressBar({
    duration = kitConfig.duration,
    label = 'Repairing vehicle...',
    useWhileDead = false,
    canCancel = true,
    disable = { move = true, car = true, mouse = false, combat = true },
    anim = { dict = kitConfig.animDict or Config.AdvancedMechanics.fieldKitAnim.dict, clip = kitConfig.animClip or Config.AdvancedMechanics.fieldKitAnim.clip, flag = kitConfig.animFlag or Config.AdvancedMechanics.fieldKitAnim.flag },
  })
  if success then
    TriggerServerEvent('advanced-mechanics:server:completeFieldRepair', vehicleNetId, kitType)
  end
end)

RegisterNetEvent('advanced-mechanics:client:showDiagnosis', function(dashboard, plate)
  currentDiagnosis = { plate = plate, components = dashboard }
  local menuItems = {}
  for _, comp in ipairs(dashboard) do
    local icon = comp.pct > 80 and 'fas fa-check-circle' or (comp.pct > 50 and 'fas fa-exclamation-triangle' or 'fas fa-times-circle')
    local color = comp.pct > 80 and '#00ff00' or (comp.pct > 50 and '#ffff00' or '#ff0000')
    table.insert(menuItems, {
      title = comp.label .. ' (' .. comp.status .. ')',
      description = 'Health: ' .. math.floor(comp.health) .. '/' .. math.floor(comp.maxHealth) .. ' (' .. comp.pct .. '%)',
      icon = icon,
      iconColor = color,
      onSelect = function()
        TriggerServerEvent('advanced-mechanics:server:repairComponent', plate, comp.key)
      end
    })
  end
  Wrappers.ContextMenu({ id = 'vehicle_diagnosis', title = 'Vehicle Diagnosis', menuItems = menuItems })
end)

CreateThread(function()
  for _, zone in ipairs(Config.AdvancedMechanics.workshopZones) do
    exports['ox_target']:addBoxZone({
      coords = zone.coords,
      size = vector3(zone.radius * 2, zone.radius * 2, 4.0),
      rotation = 0,
      debug = false,
      options = {
        {
          name = 'workshop_diagnose_' .. zone.name,
          label = 'Diagnose Vehicle',
          icon = 'fas fa-stethoscope',
          job = 'mechanic',
          onSelect = function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if not vehicle or vehicle == 0 then
              Wrappers.Notify('Get in a vehicle first', 'error')
              return
            end
            TriggerServerEvent('advanced-mechanics:server:diagnose', NetworkGetNetworkIdFromEntity(vehicle))
          end,
        },
        {
          name = 'workshop_repair_complete_' .. zone.name,
          label = 'Full Service',
          icon = 'fas fa-tools',
          job = 'mechanic',
          onSelect = function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if not vehicle or vehicle == 0 then
              Wrappers.Notify('Get in a vehicle first', 'error')
              return
            end
            TriggerServerEvent('advanced-mechanics:server:diagnose', NetworkGetNetworkIdFromEntity(vehicle))
          end,
        },
      }
    })
  end
end)

--- Save on garage entry
AddEventHandler('Renewed-Garages:client:ParkVehicle', function(vehicleNetId)
  TriggerServerEvent('advanced-mechanics:server:saveVehicleState', vehicleNetId)
end)
