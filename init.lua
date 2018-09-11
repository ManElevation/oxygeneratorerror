oxygenerator = {}
oxygenerator.version = "08/14/2018a";
minetest.register_privilege("oxygenerator_bypass", {description = "Allows you to bypass oxygenerator functions", give_to_singleplayer = false})
dofile(minetest.get_modpath("oxygenerator").."/particles.lua") --makes small particles emanate from the beginning of a beam
dofile(minetest.get_modpath("oxygenerator").."/generator.lua") --generates fuel for oxygenerators
oxygenerator.radius = tonumber(minetest.settings:get("oxygenerator_radius")) or 5
oxygenerator.consume_rate = tonumber(minetest.settings:get("oxygenerator_rate")) or 60 -- seconds
local oxygenerate_fuel =60
oxygenerator.players = {}

--
-- Formspec
--
local text = "1: Craft a generator for oxygenerator fuel\n2: Once the generator has generated the fuel place the fuel inside the oxygenerator\n3: You should now be safe in its radius inside water and in space till the fuel runs out\n\nUse Air tanks for fuel!";

local oxygenerator_formspec =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[current_name;fuel;1,0.6;3,3;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	"label[0.1,0.3;Fuel:]"..
	"label[0,3.6;PUNCH node to show oxygenerated area]"..
	"listring[current_player;main]"..
	"listring[current_player;main]"..
	"listring[context;fuel]"..
	"listring[current_player;main]"..
	"size [5.5,5.5] textarea[4.5,0.5;3.8,4;help;Oxygenerator Instructions;".. text.."]"
	default.get_hotbar_bg(0, 4.25)

--
-- Node callback functions that are the same for active and inactive oxygenerator
--

local function allow_metadata_inventory_put(pos, ttl, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return 0
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel")
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name, param2)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	node.param2 = param2
	minetest.swap_node(pos, node)
end

 --
 -- Node timer
 --oxygenerator_small_active
 
local function oxygenerator_node_timer(pos)
    --
    -- Update formspec, infotext and node
    -- oxygenerate_fuel
    local timer = minetest.get_node_timer(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = ItemStack("oxygenerator:air_tank 1")
    local fuel = inv:contains_item("fuel", stack) -- nil if not true
    local node = minetest.get_node(pos)

    if fuel then
	minetest.get_node_timer(pos):start(1)
        if timer:is_started() == false then
            timer:start(oxygenerator.consume_rate)
            minetest.get_node_timer(pos):start(1)
        inv:remove_item("fuel", stack)
        minetest.swap_node(pos, {name="oxygenerator:oxygenerator_small_active"})
        end
    else
    minetest.swap_node(pos, {name="oxygenerator:oxygenerator_small", param2=node.param2})
        meta:set_string("infotext", "Insert Air tanks as fuel12.")
        --
        --
        -- stop timer on the inactive oxygenerator
        timer:stop()
end
end
--
-- Node definitions
--

minetest.register_node("oxygenerator:oxygenerator_small", {
	description = "oxygenerator",
	tiles = {
		"oxygenerator_top.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_front.png",
		"oxygenerator_side.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, dig_immediate = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	can_dig = can_dig,
	on_timer = oxygenerator_node_timer,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", oxygenerator_formspec)
		meta:set_string("infotext", "Insert Air Tanks as fuel11.")
		local inv = meta:get_inventory()
		inv:set_size('fuel', 9)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "fuel", drops)
		drops[#drops+1] = "oxygenerator:oxygenerator_small"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
on_punch = function(pos, node, puncher)
minetest.add_entity(pos, "oxygenerator:display") end
})

minetest.register_node("oxygenerator:oxygenerator_small_active", {
	description = "oxygenerator_active",
	tiles = {
		"oxygenerator_top.png", "oxygenerator_side.png", -- TOP, BOTTOM
		"oxygenerator_side.png", "oxygenerator_side.png", -- SIDE, SIDE
		"oxygenerator_side.png", -- SIDE
		{
			image = "oxygenerator_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 3.5
			},
		}
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "oxygenerator:oxygenerator_small",
--	groups = {cracky=2, dig_immediate = 2, not_in_creative_inventory=1},
	groups = {cracky=2, dig_immediate = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
--	on_timer = oxygenerator_node_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
--on_timer = function oxygen12(pos, elapsed)
on_punch = function(pos, node, puncher)
minetest.add_entity(pos, "oxygenerator:display") end,
    on_construct=function(pos)
        minetest.get_node_timer(pos):start(1)
    end,
    on_timer = function (pos, elapsed)
        for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 27)) do
           if ob:get_breath() ~= 11 then
   		 ob:set_breath(10)
	    end
        end
    minetest.get_node_timer(pos):set(0.1, 0)
    end
})
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTS
minetest.register_craftitem("oxygenerator:air_tank", {
	description = "Air Tank: fuel for oxygenerator",
	inventory_image = "air_tank.png",
})

minetest.register_craft({
	output = "oxygenerator:air_tank",
	recipe = {
                {"", "default:steel_ingot", "", },
                {"default:steel_ingot", "default:leaves", "default:steel_ingot", },
                {"", "default:steel_ingot", "", }
	}
})

minetest.register_craft({
	output = "oxygenerator:oxygenerator_small",
	recipe = {
                {"default:steel_ingot", "default:steelblock", "default:steel_ingot", },
                {"default:steel_ingot", "oxygenerator:air_tank",        "default:steel_ingot", },
                {"default:steel_ingot", "default:steelblock", "default:steel_ingot", }
	}
})


-- DISPLAY (radius)
minetest.register_entity("oxygenerator:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"oxygenerator:display_node"},
	timer = 0,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		-- remove after 5 seconds
		if self.timer > 5 then
			self.object:remove()
		end
	end,
})


-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

local x = oxygenerator.radius
minetest.register_node("oxygenerator:display_node", {
	tiles = {"oxygenerator_display.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
			{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
			-- top
			{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
			-- bottom
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
			-- middle (surround oxygenerator)
			{-.55,-.55,-.55, .55,.55,.55},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})

-- SPACE
local function is_populated(pos)
    if minetest.find_node_near(pos, 5, {"oxygenerator:oxygenerator_small_active"}) ~= nil or
        minetest.find_node_near(pos, 26, {"oxygeneratorbig:oxygenerator_big"}) ~=nil then
        return true
    else
        return false
    end
end

space_timer=0

minetest.register_globalstep(function(dtime)
    space_timer=space_timer + dtime;
    if space_timer>1 then
        space_timer=0
        for _,player in ipairs(minetest.get_connected_players()) do
             if player then
                local pos=player:get_pos()
                if pos.y >= 1100 then
                    player:set_physics_override({gravity=0.1})
                    player:set_sky({r=0, g=0, b=0},"skybox",{"sky_pos_y.png","sky_neg_y.png","sky_pos_z.png","sky_neg_z.png","sky_neg_x.png","sky_pos_x.png"})
                else
                    player:set_physics_override({gravity=1.0})
                    player:set_sky({r=219, g=168, b=117},"regular",{}) 
                end
                    if not is_populated(pos) then
                        local hp = player:get_hp()
                    local privs = minetest.get_player_privs(player:get_player_name());
                       if pos.y >= 1100 and hp>0 and not privs.oxygenerator then
                            player:set_hp(hp-1)
                    end
                end
            end
        end
    end
end)