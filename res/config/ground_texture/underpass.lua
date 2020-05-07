local tu = require "texutil"

function data()
return {
	texture = tu.makeMaterialIndexTexture("res/textures/terrain/material/ballast.tga", "REPEAT", "REPEAT"),
	texSize = { 32.0, 4.0 },
	materialIndexMap = {
	},
	
	priority = 12
}
end
