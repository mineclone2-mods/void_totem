local S = minetest.get_translator("void_totem")
local C = minetest.colorize

local vector = vector

-- Register Item

minetest.register_craftitem("void_totem:totem", {
	description = S("Totem of Void Undying"),
	_tt_help = C(mcl_colors.GREEN, S("Protects you from void death while wielding it")),
	_doc_items_longdesc = S("A totem of void undying is a rare artifact which may safe you from void death."),
	_doc_items_usagehelp = S(
		"The totem only works while you hold it in your hand. "..
		"If you die in the void, you will be teleported back to the surfact with 1 HP. "..
		"The totem is destroyed in the process, however."
	),
	inventory_image = "void_totem_totem.png",
	wield_image = "void_totem_totem.png",
	stack_max = 1,
	groups = {combat_item = 1, offhand_item = 1},
})

-- Implemetation
-- Many things here a just copied from MineClone2

-- TODO: Teleport player to a safe place

local hud_totem = {}

minetest.register_on_leaveplayer(function(player)
	hud_totem[player] = nil
end)

local particle_colors = {"98BF22", "C49E09", "337D0B", "B0B021", "1E9200"}

mcl_damage.register_modifier(function(obj, damage, reason)
	--minetest.chat_send_all(dump(reason))
	if obj:is_player() then
		if reason.type == "out_of_world" then
			local ppos = obj:get_pos()
			local _, is_in_deadly_void = mcl_worlds.is_in_void(ppos)
			if not is_in_deadly_void then return end

			local hp = obj:get_hp()
			if hp - damage <= 0 then
				local wield = obj:get_wielded_item()
				local in_offhand = false
				if not (wield:get_name() == "void_totem:totem") then
					local inv = obj:get_inventory()
					if inv then
						wield = obj:get_inventory():get_stack("offhand", 1)
						in_offhand = true
					end
				end
				if wield:get_name() == "void_totem:totem" then

					if not minetest.is_creative_enabled(obj:get_player_name()) then
						wield:take_item()
						if in_offhand then
							obj:get_inventory():set_stack("offhand", 1, wield)
							mcl_inventory.update_inventory_formspec(obj)
						else
							obj:set_wielded_item(wield)
						end
					end

					-- Send to spawn (TODO: safe place)
					-- Reset velocity by hand (https://github.com/minetest/minetest/issues/11260#issuecomment-851650573)
					local vel = obj:get_velocity()
					obj:add_velocity(vector.multiply(vel, -1))
					mcl_spawn.spawn(obj)

					-- Update player position (to add the particles to the right place)
					ppos = obj:get_pos()

					-- Effects
					minetest.sound_play({name = "mcl_totems_totem", gain = 1}, {pos=ppos, max_hear_distance = 16}, true)

					for i = 1, 4 do
						for c = 1, #particle_colors do
							minetest.add_particlespawner({
								amount = math.floor(100 / (4 * #particle_colors)),
								time = 1,
								minpos = vector.offset(ppos, 0, -1, 0),
								maxpos = vector.offset(ppos, 0, 1, 0),
								minvel = vector.new(-1.5, 0, -1.5),
								maxvel = vector.new(1.5, 1.5, 1.5),
								minacc = vector.new(0, -0.1, 0),
								maxacc = vector.new(0, -1, 0),
								minexptime = 1,
								maxexptime = 3,
								minsize = 1,
								maxsize = 2,
								collisiondetection = true,
								collision_removal = true,
								object_collision = false,
								vertical = false,
								texture = "mcl_particles_totem" .. i .. ".png^[colorize:#" .. particle_colors[c],
								glow = 10,
							})
						end
					end

					-- Big totem overlay
					if not hud_totem[obj] then
						hud_totem[obj] = obj:hud_add({
							hud_elem_type = "image",
							text = "void_totem_totem.png",
							position = {x = 0.5, y = 1},
							scale = {x = 17, y = 17},
							offset = {x = 0, y = -178},
							z_index = 100,
						})
						minetest.after(3, function()
							if obj:is_player() then
								obj:hud_remove(hud_totem[obj])
								hud_totem[obj] = nil
							end
						end)
					end

					-- Set HP to exactly 1
					return hp - 1
				end
			end
		end
	end
end, 1001)


-- Craft

minetest.register_craft({
	output = "void_totem:totem",
	recipe = {
		{"mcl_end:chorus_fruit", "mcl_end:ender_eye", "mcl_end:chorus_fruit"},
		{"mcl_core:emerald",     "mobs_mc:totem",     "mcl_core:emerald"},
		{"",                     "mcl_end:ender_eye", ""},
	}
})