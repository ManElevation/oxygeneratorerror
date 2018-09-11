generator = {}
oxygenerator = {}
--generator.add_rate = tonumber(minetest.settings:get("generator_rate")) or 2 -- seconds
--minetest.log(dump(generate_fuel))
local generate_fuel =50
---
---
local generator_formspec =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;fuel;2.75,2.5;1,1;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	"listring[current_player;main]"..
	"listring[current_player;main]"..
	"listring[context;fuel]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0, 4.25)

allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos);
			local privs = minetest.get_player_privs(player:get_player_name());
			if minetest.is_protected(pos,player:get_player_name()) and not privs.oxygenerator_bypass then return 0 end
			return stack:get_count();
		end
		
local function generator_node_timer(pos, itemstack, player)
        
        local timer = minetest.get_node_timer(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local node = minetest.get_node(pos)
        
        if timer:is_started() == false then
            timer:start(generate_fuel)
        end
		inv:add_item("fuel", "oxygenerator:air_tank")
end

minetest.register_node("oxygenerator:generator", {
	description = "Generator",
	tiles = {
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png",
		"oxygenerator_side.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, dig_immediate = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	can_dig = can_dig,
	on_timer = generator_node_timer,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", generator_formspec)
		meta:set_string("infotext", "Generates fuel for oxygenerators.")
		local inv = meta:get_inventory()
		inv:set_size('fuel', 1)
		minetest.get_node_timer(pos):start(generate_fuel)
	end,

	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

	