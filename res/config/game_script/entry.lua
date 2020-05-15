local func = require "entry/func"
local pipe = require "entry/pipe"
local arrayUtils = require('/entry/lolloArrayUtils')
local transfUtils = require('/entry/lolloTransfUtils')
local debugger = require('debugger')
local inspect = require('inspect')
local luadump = require('entry/luadump')

local _baseEntrySlotId = 90000
local _baseStationComponentSlotId = 10000
local _idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
local _maxDistanceForConnectedItems = 160.0
local _maxMergedStations = 8

local state = {
    warningShaderMod = false,
    
    items = {},
    popupItems = {},
    checkedItems = {},
    
    stations = {},
    entries = {},
    
    linkEntries = false,
    -- built = {},
    builtLevelCount = {},

    pos = false,
    showWindow = false,
}

local function _myErrorHandlerShort(err)
    print('entry.lua ERROR making the connection popup')
end

local function _cloneWoutModulesAndSeed(params)
    return arrayUtils.cloneOmittingFields(params, {'modules', 'seed'})
end

local function _cloneWoutModulesParamsAndSeed(params)
    return arrayUtils.cloneOmittingFields(params, {'modules', 'params', 'seed'})
end

local function _decomp(params)
    local group = {}
    for slotId, m in pairs(params.modules) do
        local groupId = (slotId - slotId % _baseStationComponentSlotId) / _baseStationComponentSlotId % 10
        if not group[groupId] then
            group[groupId] = {
                modules = {},
                params = m.params,
                transf = m.transf
            }
        end
        group[groupId].modules[slotId - groupId * _baseStationComponentSlotId] = m
    end
    return group
end

local function _getStationGroupName(constructionEntity)
    if type(constructionEntity) ~= 'table' or type(constructionEntity.position) ~= 'table' then return '' end

    local nearbyStationGroups = game.interface.getEntities(
        {pos = constructionEntity.position, radius = 0},
        {type = "STATION_GROUP", includeData = true}
    )

    for _, staGro in pairs(nearbyStationGroups) do
        return staGro.name
    end

    return constructionEntity.name
end

local function _guiAddEntry(id)
    if not (state.linkEntries) then return end

    local entity = game.interface.getEntity(id)
    if not (entity) then return end

    -- xpcall(
    -- function()
    
            local isEntry = entity.fileName == "street/underpass_entry.con"
            local isStation = entity.fileName == "station/rail/mus.con"
            -- local isBuilt = isStation and entity.params and entity.params.isFinalized == 1
            if not isEntry and not isStation then return end

            local stationName = isStation and _getStationGroupName(entity) or ''
            local layoutId = "underpass.link." .. tostring(id) .. "."
            local hLayout = gui.boxLayout_create(layoutId .. "layout", "HORIZONTAL")
            -- local label = gui.textView_create(layoutId .. "label", isEntry and tostring(id) or entity.name .. (isBuilt and _("BUILT") or ""), 300)
            local label = gui.textView_create(layoutId .. "label", isEntry and tostring(id) or stationName, 300)
            local icon = gui.imageView_create(layoutId .. "icon",
                isEntry and
                "ui/construction/street/underpass_entry_small.tga" or
                "ui/construction/station/rail/mus_small.tga"
            )
            local locateView = gui.imageView_create(layoutId .. "locate.icon", "ui/design/window-content/locate_small.tga")
            local locateBtn = gui.button_create(layoutId .. "locate", locateView)
            local checkboxView = gui.imageView_create(layoutId .. "checkbox.icon",
                func.contains(state.checkedItems, id)
                and "ui/design/components/checkbox_valid.tga"
                or "ui/design/components/checkbox_invalid.tga"
            )
            local checkboxBtn = gui.button_create(layoutId .. "checkbox", checkboxView)

            -- LOLLO TODO remove after testing
            local checkboxImage = func.contains(state.checkedItems, id)
            and "ui/design/components/checkbox_valid.tga"
            or "ui/design/components/checkbox_invalid.tga"
            print('LOLLO id = ', id, 'checkbox image = ', checkboxImage)

            
            hLayout:addItem(locateBtn)
            hLayout:addItem(checkboxBtn)
            hLayout:addItem(icon)
            hLayout:addItem(label)
            
            locateBtn:onClick(function()
                local pos = entity.position
                game.gui.setCamera({pos[1], pos[2], pos[3], -4.77, 0.2})
            end)
            
            checkboxBtn:onClick(
                function()
                    if (func.contains(state.checkedItems, id)) then
                        checkboxView:setImage("ui/design/components/checkbox_invalid.tga")
                        game.interface.sendScriptEvent("__underpassEvent__", "uncheck", {id = id})
                    else
                        checkboxView:setImage("ui/design/components/checkbox_valid.tga")
                        game.interface.sendScriptEvent("__underpassEvent__", "check", {id = id})
                    end
                end
            )
            local comp = gui.component_create(layoutId .. "comp", "")
            comp:setLayout(hLayout)
            state.linkEntries.layout:addItem(comp)
            state.popupItems[#state.popupItems + 1] = id
    --     end,
    --     _myErrorHandlerShort
    -- )
end

local function _guiCheckFn()
    if not (state.linkEntries) then return end

    local stations = func.filter(state.checkedItems, function(e) return func.contains(state.stations, e) end)
    local entries = func.filter(state.checkedItems, function(e) return func.contains(state.entries, e) end)
    -- local built = func.filter(state.checkedItems, function(e) return func.contains(state.built, e) end)
    
    if (#stations > 0) then
        -- if (#stations - #built + func.fold(built, 0, function(t, b) return (state.builtLevelCount[b] or 99) + t end) > _maxMergedStations) then
        --     game.gui.setEnabled(state.linkEntries.button.id, false)
        --     state.linkEntries.desc:setText(_("STATION_MAX_LIMIT"), 200)
        -- elseif (#entries > 0 or (#built > 0 and #stations > 1)) then
        --     game.gui.setEnabled(state.linkEntries.button.id, true)
        --     state.linkEntries.desc:setText(_("STATION_CAN_FINALIZE"), 200)
        -- else
        --     game.gui.setEnabled(state.linkEntries.button.id, false)
        --     state.linkEntries.desc:setText(_("STATION_NEED_ENTRY"), 200)
        -- end
        if (#stations + func.fold({}, 0, function(t, b) return (state.builtLevelCount[b] or 99) + t end) > _maxMergedStations) then
            game.gui.setEnabled(state.linkEntries.button.id, false)
            state.linkEntries.desc:setText(_("STATION_MAX_LIMIT"), 200)
        elseif #entries > 0 or #stations > 1 then
            game.gui.setEnabled(state.linkEntries.button.id, true)
            state.linkEntries.desc:setText(_("STATION_CAN_FINALIZE"), 200)
        else
            game.gui.setEnabled(state.linkEntries.button.id, false)
            state.linkEntries.desc:setText(_("STATION_NEED_ENTRY"), 200)
        end

        state.linkEntries.button.icon:setImage("ui/construction/station/rail/mus_op.tga")
        state.linkEntries:setTitle(_("STATION_CON"))
    elseif (#stations == 0) then
        if (#entries > 1) then
            game.gui.setEnabled(state.linkEntries.button.id, true)
            state.linkEntries.desc:setText(_("UNDERPASS_CAN_FINALIZE"), 200)
        else
            game.gui.setEnabled(state.linkEntries.button.id, false)
            state.linkEntries.desc:setText(_("UNDERPASS_NEED_ENTRY"), 200)
        end
        state.linkEntries.button.icon:setImage("ui/construction/street/underpass_entry_op.tga")
        state.linkEntries:setTitle(_("UNDERPASS_CON"))
    else
        game.gui.setEnabled(state.linkEntries.button.id, false)
    end
end

local function _guiCloseWindow()
    if (state.linkEntries) then
        local w = state.linkEntries
        state.pos = game.gui.getContentRect(w.id)
        w:close()
    end
    state.popupItems = {}
    state.linkEntries = false
end

local function _guiShowWindow()
    if state.linkEntries or #state.items < 1 then return end

    local finishIcon = gui.imageView_create("underpass.link.icon", "ui/construction/street/underpass_entry_op.tga")
    local finishButton = gui.button_create("underpass.link.button", finishIcon)
    local finishDesc = gui.textView_create("underpass.link.description", "")
    
    local hLayout = gui.boxLayout_create("underpass.link.hLayout", "HORIZONTAL")
    
    hLayout:addItem(finishButton)
    hLayout:addItem(finishDesc)
    local comp = gui.component_create("underpass.link.hComp", "")
    comp:setLayout(hLayout)
    
    local vLayout = gui.boxLayout_create("underpass.link.vLayout", "VERTICAL")
    vLayout:addItem(comp)
    
    state.linkEntries = gui.window_create("underpass.link.window", _("UNDERPASS_CON"), vLayout)
    state.linkEntries.desc = finishDesc
    state.linkEntries.button = finishButton
    state.linkEntries.button.icon = finishIcon
    state.linkEntries.layout = vLayout
    
    state.linkEntries:onClose(function()
        _guiCloseWindow()
        game.interface.sendScriptEvent("__underpassEvent__", "window.close", {})
    end)
    
    finishButton:onClick(function()
        _guiCloseWindow()
        game.interface.sendScriptEvent("__underpassEvent__", "window.close", {})
        game.interface.sendScriptEvent("__underpassEvent__", "construction", {})
    end)
    
    game.gui.window_setPosition(state.linkEntries.id, table.unpack(state.pos and {state.pos[1], state.pos[2]} or {200, 200}))

    -- for _, ite in pairs(state.items) do
    --     _guiAddEntry(ite)
    -- end

    -- _guiCheckFn()
end

local function _guiShaderWarning()
    if (not game.config.shaderMod) then
        if not state.warningShaderMod then
            local textview = gui.textView_create(
                "underpass.warning.textView",
                _([["SHADER_WARNING"]]),
                400
            )
            local layout = gui.boxLayout_create("underpass.warning.boxLayout", "VERTICAL")
            layout:addItem(textview)
            state.warningShaderMod = gui.window_create(
                "underpass.warning.window",
                _("Warning"),
                layout
            )
            state.warningShaderMod:onClose(function()state.warningShaderMod = false end)
        end
        
        local mainView = game.gui.getContentRect("mainView")
        local mainMenuHeight = game.gui.getContentRect("mainMenuTopBar")[4] + game.gui.getContentRect("mainMenuBottomBar")[4]
        local size = game.gui.calcMinimumSize(state.warningShaderMod.id)
        local y = mainView[4] - size[2] - mainMenuHeight
        local x = mainView[3] - size[1]
        
        game.gui.window_setPosition(state.warningShaderMod.id, x * 0.5, y * 0.5)
        game.gui.setHighlighted(state.warningShaderMod.id, true)
    end
end

local function _getRetransfedEntryModules(entries, leadingTransf, additionalParam)
    local results = {}

    for i, ent in ipairs(entries) do
        -- LOLLO NOTE not commutative
        local newTransfE = transfUtils.mul(ent.transf, transfUtils.getInverseTransf(leadingTransf))

        for _, modu in pairs(ent.params.modules) do
            if modu.transf == nil then
                results[#results + 1] = {
                    metadata = {entry = true},
                    name = "street/underpass_entry.module",
                    params = _cloneWoutModulesAndSeed(ent.params),
                    -- params = func.with(_cloneWoutModulesAndSeed(ent.params), {isStation = true}),
                    transf = _cloneWoutModulesAndSeed(newTransfE),
                    variant = 0,
                }
            else
                -- LOLLO NOTE not commutative
                -- local newTransfM = transfUtils.mul(newTransfE, modu.transf) -- no!
                -- local newTransfM = transfUtil.mul(newTransfE, modu.transf) -- yes!
                local newTransfM = transfUtils.mul(modu.transf, newTransfE) -- yes!
                -- local newTransfM = transfUtil.mul(modu.transf, newTransfE) -- no!
                results[#results + 1] = {
                    metadata = {entry = true},
                    name = 'street/underpass_entry.module',
                    params = _cloneWoutModulesAndSeed(ent.params),
                    transf = _cloneWoutModulesAndSeed(newTransfM),
                    variant = 0
                }
            end

            if type(additionalParam) == 'table' then
                arrayUtils.concatKeysValues(results[#results].params, additionalParam)
            end
        end
    end

    return results
end

local function _getIsStationIndexed(station)
    if type(station) ~= 'table' or type(station.params) ~= 'table' or type(station.params.modules) ~= 'table' then return false end

    for iii, _ in ipairs(station.params.modules) do
        if iii < _baseStationComponentSlotId then return false end
    end

    return true
end

local function _getLeadingAndAttachedStations(stations)
    local leadingStation = {}
    local attachedStationIds = {}
    -- first look for a station with the initial indexes
    for _, sta in ipairs(stations) do
        if not _getIsStationIndexed(sta) then
            leadingStation = sta
        end
    end
    -- if not found, fall back on the first
    if leadingStation.params == nil then leadingStation = stations[1] end
    -- still nothing found, leave
    if leadingStation.params == nil then return {}, {} end

    for _, sta in ipairs(stations) do
        if sta.id ~= leadingStation.id then
            attachedStationIds[#attachedStationIds + 1] = sta.id
        end
    end

    return leadingStation, attachedStationIds
end

local function _getSlotIdBase(leadingModules, attachedModules, minBase)
    local result
    for i = minBase, _maxMergedStations do
        result = i * _baseStationComponentSlotId
        local isNewSlotIdBaseOk = true
        -- for slotId, _ in pairs(sta.params.modules) do
        for slotId, _ in pairs(attachedModules) do
            -- if newLeadingStationModules[slotId + newSlotIdBase] ~= nil then isNewSlotIdBaseOk = false break end
            if leadingModules[slotId + result] ~= nil then isNewSlotIdBaseOk = false break end
        end
        if isNewSlotIdBaseOk then return result end
    end
    return -1
end

local function _buildStation(newEntries, stations) -- , built)
    local leadingStation, attachedStationIds = _getLeadingAndAttachedStations(stations)
    -- nothing found, leave
    if leadingStation.params == nil then return end

    local leadingTransf = _cloneWoutModulesAndSeed(leadingStation.transf)
    local newEntriesModules = _getRetransfedEntryModules(newEntries, leadingTransf, {isStation = true})

    -- LOLLO NOTE add a platform: the connections will disappear. It will reappear when you destroy the new platform or add stairs up
    -- LOLLO TODO two or more stations and an underpass in between: the connection is too long and winding.
    -- it appears that the underpass tries to connect to a station only.

    -- put all the modules of all stations into the leading one, except the new entries,
    -- which are not in any station props coz they are new.
    local newLeadingStationModules = {}
    -- first the modules that have existed before...
    for _, sta in pairs(stations) do
        if _getIsStationIndexed(sta) then
            local newStaTransf = transfUtils.mul(sta.transf, transfUtils.getInverseTransf(leadingTransf))
            -- with the leading station, transf should always be _idTransf

            local newSlotIdBase = _getSlotIdBase(newLeadingStationModules, sta.params.modules, 0)
            if newSlotIdBase < 0 then break end -- LOLLO TODO raise some error

            for slotId, modu in pairs(sta.params.modules) do
                local oldModuTransf = modu.transf or _idTransf
                local newModuTransf = transfUtils.mul(oldModuTransf, newStaTransf)
                if modu.metadata and modu.metadata.entry then
                    newEntriesModules[#newEntriesModules + 1] = modu
                    newEntriesModules[#newEntriesModules].transf = newModuTransf
                else
                    newLeadingStationModules[slotId + newSlotIdBase] = _cloneWoutModulesAndSeed(modu)
                    newLeadingStationModules[slotId + newSlotIdBase].transf = newModuTransf
                end
            end
        end
    end

    -- ... then the new modules
    for _, sta in ipairs(stations) do
        if not _getIsStationIndexed(sta) then
            local newStaTransf = transfUtils.mul(sta.transf, transfUtils.getInverseTransf(leadingTransf))
            -- with the leading station, transf should always be _idTransf

            -- when a station receives its first entry, bump its slot ids
            local newSlotIdBase = _getSlotIdBase(newLeadingStationModules, sta.params.modules, 1)
            if newSlotIdBase < 0 then break end -- LOLLO TODO raise some error

            for slotId, modu in pairs(sta.params.modules) do
                if modu.metadata and modu.metadata.entry then
                    newEntriesModules[#newEntriesModules + 1] = modu
                    newEntriesModules[#newEntriesModules].transf = newStaTransf
                else
                    local newModu = _cloneWoutModulesParamsAndSeed(modu)
                    newModu.params = _cloneWoutModulesAndSeed(sta.params)
                    newModu.transf = newStaTransf
                    newLeadingStationModules[slotId + newSlotIdBase] = newModu
                end
            end
        end
    end

    leadingStation.params.modules = newLeadingStationModules

    -- add new entries into leading station modules
    local i = 1
    for _, modu in pairs(newEntriesModules) do
        while leadingStation.params.modules[_baseEntrySlotId + i] ~= nil do
            i = i + 1
        end
        leadingStation.params.modules[_baseEntrySlotId + i] = _cloneWoutModulesAndSeed(modu)
    end

    -- set isFinalized for leading station (1 if it has entries, otherwise 0)
    leadingStation.params.isFinalized = 0
    for _, modu in pairs(leadingStation.params.modules) do
        if type(modu) == 'table' and type(modu.metadata) == 'table' and modu.metadata.entry then
            leadingStation.params.isFinalized = 1
            break
        end
    end

    -- set isFinalized for leading station modules, the same value as the leading station's
    for _, modu in pairs(leadingStation.params.modules) do
        if type(modu) == 'table' and type(modu.params) == 'table' then
            modu.params.isFinalized = leadingStation.params.isFinalized
        end
    end

    -- if (built and #built > 1) then local _ = built * pipe.range(2, #built) * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze) end
    -- local _ = stations * (built and pipe.noop() or pipe.range(2, #stations)) * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze)
    -- bulldoze other stations, which have been integrated into the leading one
    for _, staId in pairs(attachedStationIds) do
        game.interface.bulldoze(staId)
    end
    -- bulldoze entries, which have been turned into station modules.
    for _, ent in pairs(newEntries) do
        game.interface.bulldoze(ent.id)
    end

    -- commit the leading station
    local newId = game.interface.upgradeConstruction(
        leadingStation.id,
        "station/rail/mus.con",
        -- func.with(
        --     _cloneWoutModulesAndSeed(leadingStation.params),
        --     {
        --         modules = _cloneWoutModulesAndSeed(leadingStation.params.modules),
        --         isFinalized = 1,
        --     })
        -- leadingStation.params -- NO!
        arrayUtils.cloneOmittingFields(leadingStation.params, {'seed'})
    )
    -- update global variables

    if newId then
        -- if (built and #built > 1) then
        --     for _, b in ipairs(built) do
        --         state.builtLevelCount[b.id] = nil
        --     end
        -- end

        state.builtLevelCount[newId] = #stations

        print('LOLLO attachedStationIds = ')
        luadump(true)(attachedStationIds)

        state.items = func.filter(state.items, function(e) return not func.contains(state.checkedItems, e) end)
        print('LOLLO state.checkedItems after upgrade station 1 = ')
        luadump(true)(state.checkedItems)
        -- LOLLO TODO check this
        state.checkedItems = func.filter(
            state.checkedItems,
            function(e) return not func.contains(attachedStationIds, e) end
        )
        print('LOLLO state.checkedItems after upgrade station 2 = ')
        luadump(true)(state.checkedItems)

        state.stations = func.filter(state.stations, function(e) return func.contains(state.items, e) end)
        state.entries = func.filter(state.entries, function(e) return func.contains(state.items, e) end)
        -- state.built = func.filter(state.built, function(e) return func.contains(state.items, e) end)
    end
end

local function _buildUnderpass(incomingEntries)
    local leadingEntry = {}
    local attachedEntries = {}
    for _, ent in ipairs(incomingEntries) do
        if leadingEntry.params == nil and ent.params.modules[1].params == nil then
            leadingEntry = ent
        else
            attachedEntries[#attachedEntries + 1] = ent
        end
    end

    local newParams = _cloneWoutModulesAndSeed(leadingEntry.params)
    local leadingTransf = _cloneWoutModulesAndSeed(leadingEntry.transf)

    -- bulldoze the older entries, the new one will be the final construction and the others will be its modules
    for _, ent in pairs(attachedEntries) do
        game.interface.bulldoze(ent.id)
    end

    newParams.modules = {
        {
            metadata = {entry = true},
            name = "street/underpass_entry.module",
            params = _cloneWoutModulesAndSeed(leadingEntry.params),
            -- transf = invRotRef * rotE * coor.trans((traslE - traslRef) .. invRotRef),
            transf = _idTransf, -- same as above
            variant = 0,
        }
    }

    arrayUtils.concatValues(
        newParams.modules,
        _getRetransfedEntryModules(attachedEntries, leadingTransf)
    )

    local newId = game.interface.upgradeConstruction(
        leadingEntry.id,
        "street/underpass_entry.con",
        newParams
    )
    print('LOLLO newId after upgrading underpass = ', newId or 'NIL', 'leadingId = ', leadingEntry.id)

    if newId then
        print('LOLLO attachedEntries ids = ')
        luadump(true)(func.map(attachedEntries, function(e) return e.id end))
        state.items = func.filter(state.items, function(e) return not func.contains(state.checkedItems, e) end)
        state.entries = func.filter(state.entries, function(e) return func.contains(state.items, e) end)
        print('LOLLO state.checkedItems after underpass upgrade 1 = ')
        luadump(true)(state.checkedItems)
        -- LOLLO TODO check the following
        state.checkedItems = func.filter(
            state.checkedItems,
            function(e) return not func.contains(
                func.map(attachedEntries, function(e) return e.id end),
                e
            ) end
        )
        print('LOLLO state.checkedItems after underpass upgrade 2 = ')
        luadump(true)(state.checkedItems)
    end
end

local script = {
    save = function()
        if not state then state = {} end
        if not state.items then state.items = {} end
        if not state.checkedItems then state.checkedItems = {} end
        if not state.stations then state.stations = {} end
        if not state.entries then state.entries = {} end
        -- if not state.built then state.built = {} end
        if not state.builtLevelCount then state.builtLevelCount = {} end
        if not state.showWindow then state.showWindow = false else state.showWindow = true end

        return state
    end,
    load = function(data)
        if data then
            state.items = data.items or {}
            state.checkedItems = data.checkedItems or {}
            state.stations = data.stations or {}
            state.entries = data.entries or {}
            state.builtLevelCount = data.builtLevelCount or {}
            state.showWindow = (data.showWindow == true) or false
            -- state.built = data.built or {}
        end
    end,
    -- update = function()
    -- end,
    guiUpdate = function()
        -- this fires many times per second, and the state may be current, or not!
        if state.showWindow then
            _guiShowWindow()
            if #state.popupItems < #state.items then
                for _, ite in pairs(state.items) do
                    if not func.contains(state.popupItems, ite) then
                        _guiAddEntry(ite)
                    end
                end
            end
            _guiCheckFn()
        else
            _guiCloseWindow()
        end
    end,
    handleEvent = function(src, id, name, param)
        if (id == "__underpassEvent__") then
            print('-------- LOLLO handling event name = ', name)
            print('LOLLO state before event ', name, ' = ')
            luadump(true)(state)

            if (name == "remove") then
                state.items = func.filter(state.items, function(e) return not func.contains(param, e) end)
                state.checkedItems = func.filter(state.checkedItems, function(e) return not func.contains(param, e) end)
                state.entries = func.filter(state.entries, function(e) return not func.contains(param, e) end)
                state.stations = func.filter(state.stations, function(e) return not func.contains(param, e) end)
                -- state.built = func.filter(state.built, function(e) return not func.contains(param, e) end)
            elseif (name == "new") then
                if param and param.id then
                    local newEntity = game.interface.getEntity(param.id)
                    if newEntity ~= nil and newEntity.position then
                        local nearbyEntities = game.interface.getEntities(
                            {pos = newEntity.position, radius = _maxDistanceForConnectedItems},
                            {type = 'CONSTRUCTION', includeData = true}
                        )

                        state.items = {}
                        state.entries = {} --newEntity.fileName == 'street/underpass_entry.con' and {newEntity.id} or {} -- useless, lua will sort the table
                        state.checkedItems = {}
                        state.stations = {} --newEntity.fileName == 'station/rail/mus.con' and {newEntity.id} or {}
                        for _, nearbyEntity in pairs(nearbyEntities) do
                            if nearbyEntity.fileName == 'street/underpass_entry.con' then
                                state.entries[#state.entries + 1] = nearbyEntity.id -- LOLLO added this
                                state.checkedItems[#state.checkedItems + 1] = nearbyEntity.id -- LOLLO added this
                                state.items[#state.items + 1] = nearbyEntity.id -- LOLLO added this
                            elseif nearbyEntity.fileName == 'station/rail/mus.con' then
                                state.stations[#state.stations + 1] = nearbyEntity.id -- LOLLO added this
                                state.checkedItems[#state.checkedItems + 1] = nearbyEntity.id -- LOLLO added this
                                state.items[#state.items + 1] = nearbyEntity.id -- LOLLO added this
                            end
                        end

                        -- state.showWindow = true
                    end
                end
            elseif (name == "uncheck") then
                state.checkedItems = func.filter(state.checkedItems, function(e) return e ~= param.id end)
            elseif (name == "check") then
                arrayUtils.addUnique(state.checkedItems, param.id)
            elseif (name == "construction") then
                -- user clicked finalise button
                local entries = pipe.new
                    * state.checkedItems
                    * pipe.filter(function(e) return func.contains(state.entries, e) end)
                    * pipe.map(game.interface.getEntity)
                    * pipe.filter(pipe.noop())
                
                -- local built = pipe.new
                --     * state.checkedItems
                --     * pipe.filter(function(e) return func.contains(state.built, e) end)
                --     * pipe.map(game.interface.getEntity)
                --     * pipe.filter(pipe.noop())
                
                local stations = pipe.new
                    * state.checkedItems
                    -- * pipe.filter(function(e) return func.contains(state.stations, e) and not func.contains(state.built, e) end)
                    * pipe.filter(function(e) return func.contains(state.stations, e) end)
                    * pipe.map(game.interface.getEntity)
                    * pipe.filter(pipe.noop())
                
                -- if (#built > 0 and (#entries + #stations) > 0) then
                --     _buildStation(entries, stations, built)
                -- elseif (#built > 1) then
                --     _buildStation(entries, stations, built)
                -- elseif (#stations == 0 and #entries > 1) then
                --     _buildUnderpass(entries)
                -- elseif (#stations > 0 and #entries > 0) then
                --     _buildStation(entries, stations)
                -- end

                if (#stations == 0 and #entries > 1) then
                    _buildUnderpass(entries)
                else
                    _buildStation(entries, stations)
                end
            elseif (name == "select") then
                -- if not func.contains(state.built, param.id) then
                    arrayUtils.addUnique(state.items, param.id)
                    arrayUtils.addUnique(state.stations, param.id)
                    -- state.built[#state.built + 1] = param.id
                    state.builtLevelCount[param.id] = param.nbGroup
                -- end
            elseif (name == "window.close") then
                state.showWindow = false
                -- state.items = func.filter(state.items, function(i) return not func.contains(state.built, i) or func.contains(state.checkedItems, i) end)
                -- state.built = func.filter(state.built, function(b) return func.contains(state.checkedItems, b) end)
            elseif (name == "window.open") then
                state.showWindow = true
            end
            print('LOLLO state after event ', name, ' = ')
            luadump(true)(state)
        end
    end,
    guiHandleEvent = function(id, name, param)
        -- param is the id of the selected item.
        if (name == "select") then
            local entity = game.interface.getEntity(param)
            if (entity and entity.type == "CONSTRUCTION" and entity.fileName == "street/underpass_entry.con") then
                if func.contains(state.items, entity.id) then
                    game.interface.sendScriptEvent("__underpassEvent__", "window.open", {})
                end
            elseif (entity and entity.type == "STATION_GROUP") then
                local isShowWindow = false
                -- local lastVisited = false
                -- local nbGroup = 0
                local allUndergroundStationConstructions = game.interface.getEntities({pos = entity.pos, radius = 9999}, {type = "CONSTRUCTION", includeData = true, fileName = "station/rail/mus.con"})
                -- the game distinguishes constructions, stations and station groups.
                -- Constructions and stations are not selected, only station groups, which do not contain a lot of data.
                -- This is why we need this loop.
                for _, staId in ipairs(entity.stations) do
                    for _, con in pairs(allUndergroundStationConstructions) do
                        if func.contains(con.stations, staId) then
                            if con.params and con.params.isFinalized == 1 then
                                -- this is to assign builtLevelCount to every station in the selected group
                                -- lastVisited = con.id
                                -- nbGroup = #(func.filter(func.keys(_decomp(con.params)), function(g) return g < 9 end))
                                if con.id then
                                    local nbGroup = #(func.filter(func.keys(_decomp(con.params)), function(g) return g < 9 end))
                                    game.interface.sendScriptEvent("__underpassEvent__", "select", {id = con.id, nbGroup = nbGroup})
                                end
                            elseif func.contains(state.items, con.id) then
                                isShowWindow = true
                            end
                        end
                    end
                end
                -- this is to assign a value to builtLevelCount to the lastVisited station (original code)
                -- if lastVisited then
                --     game.interface.sendScriptEvent("__underpassEvent__", "select", {id = lastVisited, nbGroup = nbGroup})
                -- end
                if isShowWindow then
                    game.interface.sendScriptEvent("__underpassEvent__", "window.open", {})
                end
            end
        elseif name == "builder.apply" then
            local toRemove = param.proposal.toRemove
            local toAdd = param.proposal.toAdd
            if toRemove then
                local params = {}
                for _, r in ipairs(toRemove) do if func.contains(state.items, r) then params[#params + 1] = r end end
                if (#params > 0) then
                    game.interface.sendScriptEvent("__underpassEvent__", "remove", params)
                end
            end
            if toAdd and #toAdd > 0 then
                for i = 1, #toAdd do
                    local con = toAdd[i]
                    if (con.fileName == [[street/underpass_entry.con]]) then
                        _guiShaderWarning()

                        -- -- get the id
                        -- local newId = nil
                        -- for k, _ in pairs(param.data.entity2tn) do
                        --     local entity = game.interface.getEntity(k)
                        --     -- n BASE_EDGE, m BASE_NODE, 1 CONSTRUCTION
                        --     if type(entity) == 'table' and type(entity.type) == 'string' and entity.type == 'CONSTRUCTION' then
                        --         newId = entity.id
                        --         break
                        --     end
                        -- end

                        if type(param) == 'table' and param.result[1] ~= nil then
                            game.interface.sendScriptEvent(
                                "__underpassEvent__", "new", 
                                {
                                    id = param.result[1],
                                    isEntry = true
                                }
                            )
                            game.interface.sendScriptEvent("__underpassEvent__", "window.open", {})
                        else
                            print('error in entry.lua: cannot get underpass id')
                        end
                    end
                end
            end
        end
    end
}

function data()
    return script
end
