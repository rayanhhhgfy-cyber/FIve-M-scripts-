local QBox = exports['qbx-core']:GetCoreObject()

--- Apply a uniform preset to the player's character
--- Called by ox_inventory item export 'police-uniforms.applyUniform'
--- @param itemName string The uniform item name from Config.Uniforms.Presets
function ApplyUniform(itemName)
    local preset = Config.Uniforms.Presets[itemName]
    if not preset then
        Wrappers.Notify('Unknown uniform item', 'error')
        return
    end

    local ped = PlayerPedId()
    local model = GetEntityModel(ped)

    -- Only apply to male/female player models
    if model ~= `mp_m_freemode_01` and model ~= `mp_f_freemode_01` then
        Wrappers.Notify('Cannot apply uniform to this model', 'error')
        return
    end

    -- Apply components
    for _, comp in ipairs(preset.components) do
        SetPedComponentVariation(ped, comp.componentId, comp.drawable, comp.texture, 0)
    end

    -- Apply props
    for _, prop in ipairs(preset.props) do
        if prop.propId then
            SetPedPropIndex(ped, prop.propId, prop.drawable, prop.texture, true)
        end
    end

    -- Sync skin to illenium-appearance metadata
    TriggerServerEvent('illenium-appearance:server:saveSkin', GetResourceState('illenium-appearance') ~= 'missing')

    Wrappers.Notify(('%s uniform applied'):format(preset.label), 'success')
end

exports('applyUniform', ApplyUniform)

--- Register commands for quick uniform change (optional)
RegisterCommand('+applyUniform', function()
    local player = QBox.Functions.GetPlayerData()
    if not player or not player.job then return end

    local jobName = player.job.name
    local grade = player.job.grade

    if jobName == 'police' or jobName == 'sheriff' or jobName == 'statepolice' then
        local uniformMap = { ['0'] = 'lspd_cadet_uniform', ['1'] = 'lspd_officer_uniform', ['2'] = 'lspd_sgt_uniform', ['3'] = 'lspd_lt_uniform', ['4'] = 'lspd_chief_uniform' }
        local item = uniformMap[tostring(grade)]
        if item and exports.ox_inventory:Search('count', item) > 0 then
            ApplyUniform(item)
        else
            Wrappers.Notify('No uniform item in inventory for your rank', 'error')
        end
    elseif jobName == 'cid' then
        local uniformMap = { ['0'] = 'cid_agent_uniform', ['1'] = 'cid_agent_uniform', ['2'] = 'cid_agent_uniform', ['3'] = 'cid_agent_uniform', ['4'] = 'cid_director_uniform' }
        local item = uniformMap[tostring(grade)]
        if item and exports.ox_inventory:Search('count', item) > 0 then
            ApplyUniform(item)
        else
            Wrappers.Notify('No CID uniform item in inventory for your rank', 'error')
        end
    end
end, false)

RegisterKeyMapping('+applyUniform', 'Apply duty uniform from inventory', 'keyboard', 'u')
