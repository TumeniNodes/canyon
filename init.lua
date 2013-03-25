-- canyon 0.3.0 by paramat
-- License WTFPL, see license.txt

-- 0.3.0
-- "landup:upstone" added to "find stone y" routine for compatibility with landup.

-- Editable parameters.

local CANYON = false -- (true / false) -- Enable / disable canyon.
local WATFAC = 0.5 -- 0.5 (0 1) -- Proportion of water surface level to removed stone surface level.
local MINDEP = 11 -- 11 (0 30) -- Minimum river depth.
local MAXDEP = 30 -- 30 (0 30) -- Maximum river depth.
local DEBUG = true

local SEEDDIFF1 = 5192 
local OCTAVES1 = 5 -- 5
local PERSISTENCE1 = 0.6 -- 0.6
local SCALE1 = 384 -- 384
local NOISEL = -0.06 -- -0.06 -- NOISEL and NOISEH control canyon width.
local NOISEH = 0.06 -- 0.06 --

local SEEDDIFF2 = 9247
local OCTAVES2 = 4 -- 4
local PERSISTENCE2 = 0.5 -- 0.5
local SCALE2 = 192 -- 192

-- Stuff.

canyon = {}

local depran = MAXDEP - MINDEP
local noiran = NOISEH - NOISEL

-- On generated function.

if CANYON then
	minetest.register_on_generated(function(minp, maxp, seed)
		-- If generated chunk is surface chunk then.
		if minp.y == -32 then
			if DEBUG then
				print ("[canyon] Processing chunk ("..minp.x.." "..minp.y.." "..minp.z..")")
			end
			local env = minetest.env
			local perlin1 = env:get_perlin(SEEDDIFF1, OCTAVES1, PERSISTENCE1, SCALE1)
			local perlin2 = env:get_perlin(SEEDDIFF2, OCTAVES2, PERSISTENCE2, SCALE2)
			local xl = maxp.x-minp.x
			local zl = maxp.z-minp.z
			local x0 = minp.x
			local z0 = minp.z
			-- Loop through columns in chunk.
			for i = 0, xl do
			for j = 0, zl do
				-- For each column do.
				local x = x0 + i
				local z = z0 + j
				local noise1 = perlin1:get2d({x=x,y=z})
				-- If column is in canyon then.
				if noise1 > NOISEL and noise1 < NOISEH then
					-- Process column.
					local noise2 = perlin2:get2d({x=x,y=z})
					local norm1 = (noise1 - NOISEL) * (NOISEH - noise1) / noiran ^ 2 * 4
					local norm2 = (noise2 + 1.875) / 3.75
					-- Find surface y, if surface is snow:snow set digmos to true.
					local surfacey = 1
					for y = 47, 2, -1 do
						local nodename = env:get_node({x=x,y=y,z=z}).name
						if nodename ~= "air" then
							surfacey = y
							break
						end
					end
					-- Find stone y.
					local stoney = 1
					for y = 47, 2, -1 do
						local nodename = env:get_node({x=x,y=y,z=z}).name
						if nodename == "default:stone"
						or nodename == "default:desert_stone"
						or nodename == "landup:upstone" then
							stoney = y
							break
						end
					end
					-- Calculate water surface rise and riverbed sand bottom y.
					local watris = math.floor((stoney - 1) * WATFAC)
					local exboty = surfacey - math.floor(norm1 * (surfacey - watris + 2 + MINDEP + norm2 * depran))
					-- Find seabed y or airgap y.
					local seabedy = 47
					for y = exboty, 47 do
						local nodename = env:get_node({x=x,y=y,z=z}).name
						if nodename == "default:water_source"
						or nodename == "default:water_flowing"
						or nodename == "air" then
							seabedy = y - 1
							break
						end
					end
					-- Excavate canyon, add sand if below seabed or airgap, add water up to varying height, dig surface.
					for y = exboty, surfacey do
						if y <= exboty + 2 and y <= seabedy and y <= watris + 2 then
							env:add_node({x=x,y=y,z=z}, {name="default:sand"})
						elseif y < watris + 1 then
							env:add_node({x=x,y=y,z=z}, {name="default:water_source"})
						elseif y == watris + 1 then
							env:add_node({x=x,y=y,z=z}, {name="default:water_source"})
							env:dig_node({x=x,y=y+1,z=z})
						elseif y == surfacey then
							env:dig_node({x=x,y=y,z=z})
						else
							env:remove_node({x=x,y=y,z=z})
						end
					end
					-- Remove moss created by digging snow.
					local nodename = env:get_node({x=x,y=surfacey,z=z}).name
					if nodename == "snow:moss" then
						env:dig_node({x=x,y=surfacey,z=z})
					end
				end
			end
			end
			if DEBUG then
				print ("[canyon] Completed")
			end
		end
	end)
end

