local pipe = require "entry/pipe"
local func = require "entry/func"
local coor = require "entry/coor"
local arrayUtils = require('/entry/lolloArrayUtils')
local transfUtil = require('transf')
local lolloTransfUtils = require('/entry/lolloTransfUtils')
local vec3 = require('vec3')
local vec4 = require('vec4')
local luadump = require('luadump')
local _idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}

local _maxDistanceForConnectedItems = 160.0 -- 250.0


local state = {
    warningShaderMod = false,
    
    items = {},
    addedItems = {},
    checkedItems = {},
    
    stations = {},
    entries = {},
    
    linkEntries = false,
    built = {},
    builtLevelCount = {},

    pos = false
}

local function myErrorHandler(err)
    print('entry.lua ERROR: ', err)
end

local function myErrorHandlerShort(err)
    print('entry.lua ERROR making the connection popup')
end

local cov = function(m)
    return func.seqMap({0, 3}, function(r)
        return func.seqMap({1, 4}, function(c)
            return m[r * 4 + c]
        end)
    end)
end

local cloneWoutModulesAndSeed = function(pa)
    local params = {}
    for key, value in pairs(pa) do
        if (key ~= "seed" and key ~= "modules") then
            params[key] = value
        end
    end
    return params
end

local decomp = function(params)
    local group = {}
    for slotId, m in pairs(params.modules) do
        local groupId = (slotId - slotId % 10000) / 10000 % 10
        if not group[groupId] then
            group[groupId] = {
                modules = {},
                params = m.params,
                transf = m.transf
            }
        end
        group[groupId].modules[slotId - groupId * 10000] = m
    end
    return group
end

local addEntry = function(id)
    if (state.linkEntries) then
        local entity = game.interface.getEntity(id)
        if (entity) then
            xpcall(function()
                local isEntry = entity.fileName == "street/underpass_entry.con"
                local isStation = entity.fileName == "station/rail/mus.con"
                local isBuilt = isStation and entity.params and entity.params.isFinalized == 1
                if (isEntry or isStation) then
                -- print('LOLLO game.interface = ')
                -- require('luadump')(true)(game.interface)
                -- findPath = (),
                -- get...()
                -- sendScriptEvent = (),
                -- setBuildInPauseModeAllowed = (),
                -- setMarker = (),
                -- setZone = ()
                    local layoutId = "underpass.link." .. tostring(id) .. "."
                    print('LOLLO id = ', id)
                    print('LOLLO layoutId = ', layoutId)
                    -- print('LOLLO entity = ')
                    -- require('luadump')(true)(entity)
                    local hLayout = gui.boxLayout_create(layoutId .. "layout", "HORIZONTAL")
                    local label = gui.textView_create(layoutId .. "label", isEntry and tostring(id) or entity.name .. (isBuilt and _("BUILT") or ""), 300)
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
                    state.addedItems[#state.addedItems + 1] = id
                end
            end,
            myErrorHandlerShort
        )
        end
    end
end

local showWindow = function()
    if (not state.linkEntries and #state.items > 0) then
        local finishIcon = gui.imageView_create("underpass.link.icon", "ui/construction/street/underpass_entry_op.tga")
        local finishButton = gui.button_create("underpass.link.button", finishIcon)
        -- local keepOldIcon = gui.imageView_create("underpass.link.icon", "ui/construction/street/tiles.tga")
        -- local keepOldButton = gui.button_create("underpass.link.button", finishIcon)
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
            state.linkEntries = false
            state.addedItems = {}
            game.interface.sendScriptEvent("__underpassEvent__", "window.close", {})
        end)
        
        finishButton:onClick(function()
            if (state.linkEntries) then
                state.linkEntries:close()
                game.interface.sendScriptEvent("__underpassEvent__", "construction", {})
            end
        end)
        
        game.gui.window_setPosition(state.linkEntries.id, table.unpack(state.pos and {state.pos[1], state.pos[2]} or {200, 200}))
    end
end

local checkFn = function()
    if (state.linkEntries) then
        local stations = func.filter(state.checkedItems, function(e) return func.contains(state.stations, e) end)
        local entries = func.filter(state.checkedItems, function(e) return func.contains(state.entries, e) end)
        local built = func.filter(state.checkedItems, function(e) return func.contains(state.built, e) end)
        
        if (#stations > 0) then
            if (#stations - #built + func.fold(built, 0, function(t, b) return (state.builtLevelCount[b] or 99) + t end) > 8) then
                game.gui.setEnabled(state.linkEntries.button.id, false)
                state.linkEntries.desc:setText(_("STATION_MAX_LIMIT"), 200)
            elseif (#entries > 0 or (#built > 0 and #stations > 1)) then
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
end

local closeWindow = function()
    if (state.linkEntries) then
        local w = state.linkEntries
        state.pos = game.gui.getContentRect(w.id)
        w:close()
    end
end

local shaderWarning = function()
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

local buildStation = function(newEntries, stations, built)
    print('LOLLO state before building station = ')
    require('luadump')(true)(state)
    print('LOLLO stations before building station = ')
    require('luadump')(true)(stations)
    -- print('LOLLO newEntries before building station = ')
    -- require('luadump')(true)(newEntries)

    local ref = built and #built > 0 and built[1] or stations[1]

    local vecRef, rotRef, _ = coor.decomposite(ref.transf)
    local iRot = coor.inv(cov(rotRef))
    
    -- if (built and #built > 0) then
    --     for _, b in ipairs(built) do
    --         local group = decomp(b.params)
    --         print('LOLLO group = ')
    --         require('luadump')(true)(group)
    --         for gId, g in pairs(group) do
    --             if (gId == 9) then
    --                 for _, m in ipairs(g.modules) do
    --                     m.transf = coor.I() * m.transf * b.transf
    --                     table.insert(newEntriesModules, m)
    --                 end
    --             else
    --                 g.transf = coor.I() * g.transf * b.transf
    --                 table.insert(groups, g)
    --             end
    --         end
    --     end
    -- end

    local groups = {}
    for _, e in ipairs(stations) do
        table.insert(groups, {
            modules = e.params.modules,
            params = func.with(cloneWoutModulesAndSeed(e.params), {isFinalized = 1}),
            transf = e.transf
        })
    end

    -- print('LOLLO groups = ')
    -- require('luadump')(true)(groups)

    local newEntriesModules = {}
    for _, ent in ipairs(newEntries) do
        -- local ent = {
        --     metadata = {entry = true},
        --     name = "street/underpass_entry.module",
        --     variant = 0,
        --     transf = ent.transf,
        --     params = func.with(cloneWoutModulesAndSeed(ent.params), {isStation = true})
        -- }
        local vec, rot, _ = coor.decomposite(ent.transf)
        for _, modu in pairs(ent.params.modules) do
            local transf = iRot * rot * coor.trans((vec - vecRef) .. iRot) * (modu.transf or iRot)
            newEntriesModules[#newEntriesModules + 1] =
                {
                    metadata = {entry = true},
                    name = "street/underpass_entry.module",
                    params = func.with(cloneWoutModulesAndSeed(ent.params), {isStation = true}),
                    transf = transf,
                    variant = 0,
                }
        end
    end

    -- print('LOLLO newEntriesModules before building station = ')
    -- require('luadump')(true)(newEntriesModules)

    -- LOLLO TODO make two stations nearby. Make one underpass and connect it to both. One of the stations disappears.
    -- LOLLO TODO add a platform: the connections will disappear
    local modules = {}
    -- put all the modules of all stations into one, except the non-finalised entries, which are not in the groups
    for i, gro in ipairs(groups) do
        local vec, rot, _ = coor.decomposite(gro.transf)
        local transf = iRot * rot * coor.trans((vec - vecRef) .. iRot)
        for slotId, modu in pairs(gro.modules) do
            -- if modu.params and modu.params.isFinalized == 1 then
            if gro.params and gro.params.isFinalized == 1 then
                -- modu.params = gro.params
                -- modu.transf = transf
                modules[slotId] = modu
            else
                modu.params = gro.params
                modu.transf = transf
                modules[slotId + i * 10000] = modu -- only change the index the first time
                modules[slotId + i * 10000].params.isFinalized = 1 -- unnecessary but safer
            end
        end
    end
    
    print('LOLLO modules first = ')
    require('luadump')(true)(modules)

    -- LOLLO this replaces previous entries
    -- for i, e in ipairs(newEntriesModules) do
    --     local vec, rot, _ = coor.decomposite(e.transf)
    --     e.transf = iRot * rot * coor.trans((vec - vecRef) .. iRot)
    --     modules[90000 + i] = e
    -- end
    
    local i = 1
    if type(groups) == 'table' and type(groups[1]) == 'table' then
        while groups[1].modules[90000 + i] ~= nil do
            print('LOLLO old module index = ', 90000 + i)
            modules[90000 + i] = groups[1].modules[90000 + i]
            modules[90000 + i].params.isFinalized = 1
            i = i + 1
        end
    
        local newEntryFirstModuleId = i - 1
        for iii = 1, #newEntriesModules do
            local modu = newEntriesModules[iii]
            -- local vec, rot, _ = coor.decomposite(modu.transf)
            -- modu.transf = iRot * rot * coor.trans((vec - vecRef) .. iRot)
            print('LOLLO new module index = ', 90000 + iii + newEntryFirstModuleId)
            modules[90000 + iii + newEntryFirstModuleId] = cloneWoutModulesAndSeed(modu)
            modules[90000 + iii + newEntryFirstModuleId].params.isFinalized = 1
        end    
    else
        print('LOLLO WARNING: type(groups) =', type(groups), '#groups == ', #groups)
        for iii = 1, #newEntriesModules do
            local modu = newEntriesModules[iii]
            -- local vec, rot, _ = coor.decomposite(modu.transf)
            -- modu.transf = iRot * rot * coor.trans((vec - vecRef) .. iRot)
            print('LOLLO warning module index = ', 90000 + iii)
            modules[90000 + iii] = cloneWoutModulesAndSeed(modu)
            modules[90000 + iii].params.isFinalized = 1
        end    
    end

    print('LOLLO modules second = ')
    require('luadump')(true)(modules)

    -- bulldoze entries, which have been turned into station modules. Also bulldoze some other stuff that I don't understand.
    if (built and #built > 1) then local _ = built * pipe.range(2, #built) * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze) end
    local _ = stations * (built and pipe.noop() or pipe.range(2, #stations)) * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze)
    local _ = newEntries * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze)
    
    local newId = game.interface.upgradeConstruction(
        ref.id,
        "station/rail/mus.con",
        -- LOLLO this is like ellipsis in JS, it works fine
        func.with(
            cloneWoutModulesAndSeed(ref.params),
            {
                modules = cloneWoutModulesAndSeed(modules),
                isFinalized = 1
            })
    )
    if newId then
        if (built and #built > 1) then
            for _, b in ipairs(built) do
                state.builtLevelCount[b.id] = nil
            end
        end
        state.builtLevelCount[newId] = #groups
        state.items = func.filter(state.items, function(e) return not func.contains(state.checkedItems, e) end)
        state.checkedItems = {}
        state.stations = func.filter(state.stations, function(e) return func.contains(state.items, e) end)
        state.entries = func.filter(state.entries, function(e) return func.contains(state.items, e) end)
        -- state.built = func.filter(state.built, function(e) return func.contains(state.items, e) end)
    end

    print('LOLLO state after building station = ')
    require('luadump')(true)(state)
end

local buildUnderpass = function(incomingEntries)
    -- print('LOLLO state before building underpass = ')
    -- require('luadump')(true)(state)
    -- print('LOLLO incomingEntries before building underpass = ')
    -- require('luadump')(true)(incomingEntries)

    local leadingEntry = {}
    local otherEntries = {}
    for _, ent in ipairs(incomingEntries) do
        if leadingEntry.params == nil and ent.params.modules[1].params == nil then
            leadingEntry = ent
        else
            otherEntries[#otherEntries + 1] = ent
        end
    end

    local newParams = cloneWoutModulesAndSeed(leadingEntry.params)
    local leadingTransf = cloneWoutModulesAndSeed(leadingEntry.transf)

    -- bulldoze the older entries, the new one will be the final construction and the others will be its modules
    for _, ent in pairs(otherEntries) do
        game.interface.bulldoze(ent.id)
    end

    local modules = {
        {
            metadata = {entry = true},
            name = "street/underpass_entry.module",
            params = cloneWoutModulesAndSeed(leadingEntry.params),
            -- transf = invRotRef * rotE * coor.trans((traslE - traslRef) .. invRotRef),
            transf = _idTransf, -- same as above
            variant = 0,
        }
    }

    for i, ent in ipairs(otherEntries) do
        -- LOLLO NOTE not commutative
        local newTransfE = lolloTransfUtils.mul(ent.transf, lolloTransfUtils.getInverseTransf(leadingTransf))

        for ii, modu in pairs(ent.params.modules) do
            if modu.transf == nil then
                modules[#modules + 1] = {
                    metadata = {entry = true},
                    name = "street/underpass_entry.module",
                    params = cloneWoutModulesAndSeed(ent.params),
                    transf = cloneWoutModulesAndSeed(newTransfE),
                    variant = 0,
                }
            else
                -- LOLLO NOTE not commutative
                -- local newTransfM = lolloTransfUtils.mul(newTransfE, modu.transf) -- no!
                -- local newTransfM = transfUtil.mul(newTransfE, modu.transf) -- yes!
                local newTransfM = lolloTransfUtils.mul(modu.transf, newTransfE) -- yes!
                -- local newTransfM = transfUtil.mul(modu.transf, newTransfE) -- no!
                modules[#modules + 1] = {
                    metadata = {entry = true},
                    name = 'street/underpass_entry.module',
                    params = cloneWoutModulesAndSeed(ent.params),
                    transf = cloneWoutModulesAndSeed(newTransfM),
                    variant = 0
                }
            end
        end
    end

    -- local newParams = func.with(
    --     cloneWoutModulesAndSeed(leadingEntry.params),
    --     {
    --         modules = func.map(incomingEntries,
    --             function(entry)
    --                 local traslE, rotE, _ = coor.decomposite(entry.transf)
    --                 return {
    --                     metadata = {entry = true},
    --                     name = "street/underpass_entry.module",
    --                     variant = 0,
    --                     transf = invRotRef * rotE * coor.trans((traslE - traslRef) .. invRotRef),
    --                     params = cloneWoutModulesAndSeed(entry.params)
    --                 }
    --             end)
    --     })

    newParams.modules = modules

    local newId = game.interface.upgradeConstruction(
        leadingEntry.id,
        "street/underpass_entry.con",
        newParams
    )
    if newId then
        state.items = func.filter(state.items, function(e) return not func.contains(state.checkedItems, e) end)
        state.entries = func.filter(state.entries, function(e) return func.contains(state.items, e) end)
        state.checkedItems = {}
    end
end

local script = {
    save = function()
        if not state then state = {} end
        if not state.items then state.items = {} end
        if not state.checkedItems then state.checkedItems = {} end
        if not state.stations then state.stations = {} end
        if not state.entries then state.entries = {} end
        if not state.built then state.built = {} end
        if not state.builtLevelCount then state.builtLevelCount = {} end

        return state
    end,
    load = function(data)
        if data then
            state.items = data.items or {}
            state.checkedItems = data.checkedItems or {}
            state.stations = data.stations or {}
            state.entries = data.entries or {}
            state.builtLevelCount = data.builtLevelCount or {}
            state.built = data.built or {}
        end
    end,
    guiUpdate = function()
        -- print('LOLLO guiUpdate') -- this happens many times per second
        -- require('debugger')()
        if state.linkEntries then
            if (#state.items < 1) then
                closeWindow()
                state.addedItems = {}
            else
                -- LOLLO TODO this is dodgy: it does not account for the sequence.
                -- print('LOLLO state.addedItems = ')
                -- require('luadump')(true)(state.addedItems)
                -- print('LOLLO state.items = ')
                -- require('luadump')(true)(state.items)
                -- require('debugger')()
                if (#state.addedItems < #state.items) then -- LOLLO
                    -- print('LOLLO state.items = ')
                    -- require('luadump')(true)(state.items)
                    -- print('LOLLO state.addedItems = ')
                    -- require('luadump')(true)(state.addedItems)
                    -- print('LOLLO state.checkedItems = ')
                    -- require('luadump')(true)(state.checkedItems)
                -- if (#state.addedItems <= #state.items) then
                    for i = #state.addedItems + 1, #state.items do
                        print('LOLLO about to add entry = ', tostring(state.items[i]))
                        addEntry(state.items[i])
                    end
                elseif (#state.addedItems > #state.items) then
                    closeWindow()
                    state.showWindow = true
                end
                checkFn()
            end
        elseif (state.showWindow and #state.items - #state.built > 0) then
            showWindow()
            checkFn()
            state.showWindow = false
        end
    end,
    handleEvent = function(src, id, name, param)
        if (id == "__underpassEvent__") then
            print('-------- LOLLO event name = ', name)
            -- LOLLO TODO renew names in state. Cannot be done from game.interface, the game won't allow it
            -- print('LOLLO state = ')
            -- require('luadump')(true)(state)
            --[[ { -- after adding 1 underpass
                addedItems = {  },
                built = {  },
                builtLevelCount = {  },
                checkedItems = { 26379 },
                entries = { 26379 },
                items = { 26379 },
                linkEntries = false,
                pos = false,
                stations = {  },
                warningShaderMod = false
              }
              LOLLO state = 
              { -- then I add a station, too
                addedItems = {  },
                built = {  },
                builtLevelCount = {  },
                checkedItems = { 26379, 25278 },
                entries = { 26379 },
                items = { 26379, 25278 },
                linkEntries = false,
                pos = false,
                stations = { 25278 },
                warningShaderMod = false
              }
              LOLLO state = 
              { -- finally, I connect them together
                addedItems = {  },
                built = {  },
                builtLevelCount = { 25278 = 1 },
                checkedItems = {  },
                entries = {  },
                items = {  },
                linkEntries = false,
                pos = false,
                stations = {  },
                warningShaderMod = false
              } ]]
            if (name == "remove") then
                state.items = func.filter(state.items, function(e) return not func.contains(param, e) end)
                state.checkedItems = func.filter(state.checkedItems, function(e) return not func.contains(param, e) end)
                state.entries = func.filter(state.entries, function(e) return not func.contains(param, e) end)
                state.stations = func.filter(state.stations, function(e) return not func.contains(param, e) end)
                -- state.built = func.filter(state.built, function(e) return not func.contains(param, e) end)
            elseif (name == "new") then
                -- local e = game.interface.getEntity(param.id)
                -- game.interface.upgradeConstruction(
                --     param.id,
                --     e.fileName,
                --     func.with(cloneWoutModulesAndSeed(e.params), {modules = e.modules, isNotPreview = true})
                -- )

                if param and param.id then
                    local newEntity = game.interface.getEntity(param.id)
                    if newEntity ~= nil and newEntity.position then
                        print('LOLLO newEntity = ')
                        require('luadump')(true)(newEntity)
                        local nearbyEntities = game.interface.getEntities(
                            {pos = newEntity.position, radius = _maxDistanceForConnectedItems},
                            {type = 'CONSTRUCTION', includeData = true}
                        )
                        local relevantNearbyEntities = {}

                        -- print('LOLLO state before new = ')
                        -- require('luadump')(true)(state)
                        state.items = {}
                        state.entries = {} --newEntity.fileName == 'street/underpass_entry.con' and {newEntity.id} or {} -- useless, lua will sort the table
                        state.checkedItems = {}
                        state.stations = {} --newEntity.fileName == 'station/rail/mus.con' and {newEntity.id} or {}
                        -- print('LOLLO state at the beginning of new = ')
                        -- require('luadump')(true)(state)
                        for ii, vv in pairs(nearbyEntities) do
                            -- print('LOLLO ii = ', ii)
                            -- print('LOLLO vv = ', vv)
                            -- require('luadump')(true)(vv)
                            if vv.fileName == 'street/underpass_entry.con' then
                                -- arrayUtils.addUnique(state.entries, vv.id or ii) -- LOLLO added this
                                -- arrayUtils.addUnique(state.checkedItems, vv.id or ii) -- LOLLO added this
                                -- arrayUtils.addUnique(state.items, vv.id or ii) -- LOLLO added this
                                state.entries[#state.entries + 1] = vv.id -- LOLLO added this
                                state.checkedItems[#state.checkedItems + 1] = vv.id -- LOLLO added this
                                state.items[#state.items + 1] = vv.id -- LOLLO added this
                                relevantNearbyEntities[#relevantNearbyEntities + 1] = {[ii] = vv}
                            elseif vv.fileName == 'station/rail/mus.con' then
                                -- arrayUtils.addUnique(state.stations, vv.id or ii) -- LOLLO added this
                                -- arrayUtils.addUnique(state.checkedItems, vv.id or ii) -- LOLLO added this
                                -- arrayUtils.addUnique(state.items, vv.id or ii) -- LOLLO added this
                                state.stations[#state.stations + 1] = vv.id -- LOLLO added this
                                state.checkedItems[#state.checkedItems + 1] = vv.id -- LOLLO added this
                                state.items[#state.items + 1] = vv.id -- LOLLO added this
                                relevantNearbyEntities[#relevantNearbyEntities + 1] = {[ii] = vv}
                            end
                        end

                        -- print('LOLLO nearby constructions = ')
                        -- require('luadump')(true)(relevantNearbyEntities)

                        -- state.items[#state.items + 1] = param.id
                        -- state.checkedItems[#state.checkedItems + 1] = param.id
                        -- if (param.isEntry) then state.entries[#state.entries + 1] = param.id
                        -- elseif (param.isStation) then state.stations[#state.stations + 1] = param.id end

                        -- print('LOLLO state at the end of new = ')
                        -- require('luadump')(true)(state)
                    end
                end
            elseif (name == "uncheck") then
                state.checkedItems = func.filter(state.checkedItems, function(e) return e ~= param.id end)
            elseif (name == "check") then
                if (not func.contains(state.checkedItems, param.id)) then
                    state.checkedItems[#state.checkedItems + 1] = param.id
                end
            elseif (name == "construction") then
                -- user clicked finalise button
                local entries = pipe.new
                    * state.checkedItems
                    * pipe.filter(function(e) return func.contains(state.entries, e) end)
                    * pipe.map(game.interface.getEntity)
                    * pipe.filter(pipe.noop())
                
                local built = pipe.new
                    * state.checkedItems
                    * pipe.filter(function(e) return func.contains(state.built, e) end)
                    * pipe.map(game.interface.getEntity)
                    * pipe.filter(pipe.noop())
                
                local stations = pipe.new
                    * state.checkedItems
                    -- * pipe.filter(function(e) return func.contains(state.stations, e) and not func.contains(state.built, e) end)
                    * pipe.filter(function(e) return func.contains(state.stations, e) end)
                    * pipe.map(game.interface.getEntity)
                    * pipe.filter(pipe.noop())
                
                -- if (#built > 0 and (#entries + #stations) > 0) then
                --     buildStation(entries, stations, built)
                -- elseif (#built > 1) then
                --     buildStation(entries, stations, built)
                -- elseif (#stations == 0 and #entries > 1) then
                --     buildUnderpass(entries)
                -- elseif (#stations > 0 and #entries > 0) then
                --     buildStation(entries, stations)
                -- end
                if (#stations == 0 and #entries > 1) then
                    buildUnderpass(entries)
                else
                    buildStation(entries, stations)
                end
            elseif (name == "select") then
                if not func.contains(state.built, param.id) then
                    state.items[#state.items + 1] = param.id
                    state.stations[#state.stations + 1] = param.id
                    -- state.built[#state.built + 1] = param.id
                    state.builtLevelCount[param.id] = param.nbGroup
                end
            elseif (name == "window.close") then
                -- LOLLO TODO this is also funny
                state.items = func.filter(state.items, function(i) return not func.contains(state.built, i) or func.contains(state.checkedItems, i) end)
                -- state.built = func.filter(state.built, function(b) return func.contains(state.checkedItems, b) end)
            end
        end
    end,
    guiHandleEvent = function(id, name, param)
        if (name == "select") then
            local entity = game.interface.getEntity(param)
            if (entity and entity.type == "CONSTRUCTION" and entity.fileName == "street/underpass_entry.con") then
                if func.contains(state.items, entity.id) then
                    showWindow()
                end
            elseif (entity and entity.type == "STATION_GROUP") then
                local lastVisited = false
                local nbGroup = 0
                local cons = game.interface.getEntities({pos = entity.pos, radius = 9999}, {type = "CONSTRUCTION", includeData = true, fileName = "station/rail/mus.con"})
                for _, s in ipairs(entity.stations) do
                    for _, c in pairs(cons) do
                        if c.params and c.params.isFinalized == 1 and func.contains(c.stations, s) then -- LOLLO check this
                        -- if c.params and func.contains(c.stations, s) then
                            lastVisited = c.id
                            nbGroup = #(func.filter(func.keys(decomp(c.params)), function(g) return g < 9 end))
                        elseif func.contains(state.items, c.id) then
                            showWindow()
                        end
                    end
                end
                if lastVisited then
                    game.interface.sendScriptEvent("__underpassEvent__", "select", {id = lastVisited, nbGroup = nbGroup})
                end
            end
        end
        if name == "builder.apply" then
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
                        shaderWarning()

                        -- get the id
                        local newId = nil
                        for k, _ in pairs(param.data.entity2tn) do
                            local entity = game.interface.getEntity(k)
                            -- n BASE_EDGE, m BASE_NODE, 1 CONSTRUCTION
                            if type(entity) == 'table' and type(entity.type) == 'string' and entity.type == 'CONSTRUCTION' then
                                newId = entity.id
                                break
                            end
                        end

                        if newId ~= nil then
                            game.interface.sendScriptEvent(
                                "__underpassEvent__", "new", 
                                {
                                    -- id = param.result[1],
                                    id = newId,
                                    isEntry = true
                                }
                            )
                            state.showWindow = true
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
