package.path = package.path .. ';res/scripts/?.lua'

-- actboy lua debugger
-- actboy extension path
-- sumneko lua assist

local pipe = require 'entry/pipe'
local func = require 'entry/func'
local coor = require 'entry/coor'
local arrayUtils = require('/entry/lolloArrayUtils')

local cov = function(m)
    return func.seqMap(
        {0, 3},
        function(r)
            return func.seqMap(
                {1, 4},
                function(c)
                    return m[r * 4 + c]
                end
            )
        end
    )
end

local pureWoutModulesAndSeed = function(pa)
    local params = {}
    for key, value in pairs(pa) do
        if (key ~= 'seed' and key ~= 'modules') then
            params[key] = value
        end
    end
    return params
end

local incomingEntries = {
    {
        baseEdges = {},
        baseNodes = {},
        dateBuilt = {day = 4, month = 1, year = 1962},
        depots = {},
        fileName = 'street/underpass_entry.con',
        id = 12422,
        name = 'no name',
        params = {
            busLane = 0,
            floor = 0,
            modules = {
                {
                    metadata = {entry = true},
                    name = 'street/underpass_entry.module',
                    variant = 0
                }
            },
            paramX = 0,
            paramY = 0,
            seed = 0,
            style = 0,
            tramTrack = 0,
            wall = 0,
            width = 1,
            year = 1962
        },
        particleSystems = {},
        position = {-3230.4936523438, 3528.2353515625, 51.266723632813},
        simBuildings = {},
        stations = {},
        townBuildings = {},
        transf = {1, 0, 0, 0, -0, 1, 0, 0, 0, 0, 1, 0, -3230.4936523438, 3527.8603515625, 52.864807128906, 1},
        type = 'CONSTRUCTION'
    },
    {
        baseEdges = {},
        baseNodes = {},
        dateBuilt = {day = 4, month = 1, year = 1962},
        depots = {},
        fileName = 'street/underpass_entry.con',
        id = 9343,
        name = 'no name',
        params = {
            busLane = 0,
            floor = 0,
            modules = {
                {
                    metadata = {entry = true},
                    name = 'street/underpass_entry.module',
                    params = {busLane = 0, floor = 0, paramX = 0, paramY = 0, style = 0, tramTrack = 0, wall = 0, width = 1, year = 1962},
                    transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1},
                    variant = 0
                },
                {
                    metadata = {entry = true},
                    name = 'street/underpass_entry.module',
                    params = {busLane = 0, floor = 0, paramX = 0, paramY = 0, style = 0, tramTrack = 0, wall = 0, width = 1, year = 1962},
                    transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 60.21337890625, 6.58447265625, -1.3434143066406, 1},
                    variant = 0
                }
            },
            paramX = 0,
            paramY = 0,
            seed = -11932,
            style = 0,
            tramTrack = 0,
            upgrade = true,
            wall = 0,
            width = 1,
            year = 1962
        },
        particleSystems = {},
        position = {-3212.8391113281, 3575.12109375, 52.206100463867},
        simBuildings = {},
        stations = {},
        townBuildings = {},
        transf = {1, 0, 0, 0, -0, 1, 0, 0, 0, 0, 1, 0, -3242.9458007813, 3571.4536132813, 54.505416870117, 1},
        type = 'CONSTRUCTION'
    }
}

local ref = incomingEntries[1] -- the new one
local vecRef, rotRef, _ = coor.decomposite(ref.transf)
local iRot = coor.inv(cov(rotRef))
-- bulldoze the entries other than the new one
-- local _ = incomingEntries * pipe.range(2, #incomingEntries) * pipe.map(pipe.select("id")) * pipe.forEach(game.interface.bulldoze)

local modules = {}

for i, ent in ipairs(incomingEntries) do
    if i == 1 then -- new entry
        local vec, rot, _ = coor.decomposite(ent.transf)
        modules[#modules + 1] = {
            metadata = {entry = true},
            name = 'street/underpass_entry.module',
            variant = 0,
            transf = iRot * rot * coor.trans((vec - vecRef) .. iRot),
            params = pureWoutModulesAndSeed(ent.params)
        }
    else -- older entries
        for ii, modu in pairs(ent.params.modules) do
            local deltaPosVec = {x = ref.position[1] - ent.position[1], y = ref.position[2] - ent.position[2], z = ref.position[3] - ent.position[3]}
            -- local vec, rot, _ =
            --     coor.decomposite(coor.mul(ent.transf, modu.transf, coor.trans(deltaPosVec)))

            local vec, rot, _ = coor.decomposite(ent.transf)
            modules[#modules + 1] = {
                metadata = {entry = true},
                name = 'street/underpass_entry.module',
                params = pureWoutModulesAndSeed(ent.params),
                transf = iRot * rot * coor.trans((vec - vecRef) .. iRot) * coor.trans(deltaPosVec) * modu.transf,
                variant = 0
            }
        end
    end
end
