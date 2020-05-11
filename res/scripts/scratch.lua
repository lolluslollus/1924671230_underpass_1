package.path = package.path .. ';res/scripts/?.lua;C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

-- actboy lua debugger
-- actboy extension path
-- sumneko lua assist

local pipe = require 'entry/pipe'
local func = require 'entry/func'
local coor = require 'entry/coor'
local arrayUtils = require('/entry/lolloArrayUtils')
local transfUtil = require('transf')
local lolloTransfUtils = require('/entry/lolloTransfUtils')
local vec2 = require('vec2')
local vec3 = require('vec3')
local vec4 = require('vec4')
local matrixUtils = require('entry/matrix')
local luadump = require('entry/luadump')
local _idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
local _pi = math.pi -- 3.1415926535 -- 3.141592653589793238462643383279502884197169399375105820974944592

local cov = function(m)
    return func.seqMap({0, 3}, function(r)
        return func.seqMap({1, 4}, function(c)
            return m[r * 4 + c]
        end)
    end)
end

local transf22 = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 5, 5, 1}
local transf222 = transfUtil.mul(_idTransf, transf22)

local transf1 = { 1, 0, 0, 0, -0, 1, 0, 0, 0, 0, 1, 0, -1717.6416015625, 706.005859375, 31.600006103516, 1 }
local transf2 = { 1, 0, 0, 0, -0, 1, 0, 0, 0, 0, 1, 0, -1676.6469726563, 708.84033203125, 31.650009155273, 1 }


local vec1 = {x = 1, y = 1, z = 1}
local vec2 = {x = 10, y = 1, z = 1}
local vec3 = {x = 1, y = 10, z = 1}
local vec4 = {x = 1, y = 1, z = 10}
local leadingTransf = { 7.5497901264043e-08, -1, 0, 0, 1, 7.5497901264043e-08, 0, 0, 0, 0, 1, 0, -1749.0004882813, 708.31372070313, 33.100082397461, 1 }
local test = lolloTransfUtils.flipXYZ(leadingTransf)
local leadingTransf = { 0.9238795042038, -0.38268345594406, 0, 0, 0.38268345594406, 0.9238795042038, 0, 0, 0, 0, 1, 0, 2914.9611816406, -335.0537109375, 4.640007019043, 1 }
local test1 = lolloTransfUtils.flipXYZ(leadingTransf)
local test2 = coor.inv(cov(leadingTransf))

local test1 = lolloTransfUtils.getVecTransformed(vec1, leadingTransf)
local test11 = lolloTransfUtils.getVecTransformed(vec1, lolloTransfUtils.flipXYZ(leadingTransf))
local test2 = lolloTransfUtils.getVecTransformed(vec2, leadingTransf)
local test21 = lolloTransfUtils.getVecTransformed(vec2, lolloTransfUtils.flipXYZ(leadingTransf))
local test3 = lolloTransfUtils.getVecTransformed(vec3, leadingTransf)
local test31 = lolloTransfUtils.getVecTransformed(vec3, lolloTransfUtils.flipXYZ(leadingTransf))
local test4 = lolloTransfUtils.getVecTransformed(vec4, leadingTransf)
local test41 = lolloTransfUtils.getVecTransformed(vec4, lolloTransfUtils.flipXYZ(leadingTransf))

local test5 = lolloTransfUtils.mul(leadingTransf, lolloTransfUtils.flipXYZ(leadingTransf))
local test5i = lolloTransfUtils.mul(lolloTransfUtils.flipXYZ(leadingTransf), leadingTransf)

local invertedLeadingTransf = lolloTransfUtils.getInverseTransf(leadingTransf)
local test6 = lolloTransfUtils.mul(leadingTransf, invertedLeadingTransf) -- both look good, this and the following
local test6i = lolloTransfUtils.mul(invertedLeadingTransf, leadingTransf)
local test7 = transfUtil.mul(leadingTransf, invertedLeadingTransf) -- both look good, this and the following
local test7i = transfUtil.mul(invertedLeadingTransf, leadingTransf)
local aaa = 123


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
