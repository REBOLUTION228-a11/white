SUBSYSTEM_DEF(mapping)
	name = "Картография"
	init_order = INIT_ORDER_MAPPING
	flags = SS_NO_FIRE

	var/list/nuke_tiles = list()
	var/list/nuke_threats = list()

	var/datum/map_config/config
	var/datum/map_config/next_map_config

	var/map_voted = FALSE

	var/list/map_templates = list()

	var/list/ruins_templates = list()
	var/list/space_ruins_templates = list()
	var/list/lava_ruins_templates = list()
	var/list/gens_ruins_templates = list()
	var/list/ice_ruins_templates = list()
	var/list/ice_ruins_underground_templates = list()

	var/datum/space_level/isolated_ruins_z //Created on demand during ruin loading.

	var/list/shuttle_templates = list()
	var/list/shelter_templates = list()
	var/list/holodeck_templates = list()

	var/list/areas_in_z = list()

	var/loading_ruins = FALSE
	var/list/turf/unused_turfs = list()				//Not actually unused turfs they're unused but reserved for use for whatever requests them. "[zlevel_of_turf]" = list(turfs)
	var/list/datum/turf_reservations		//list of turf reservations
	var/list/used_turfs = list()				//list of turf = datum/turf_reservation

	var/list/reservation_ready = list()
	var/clearing_reserved_turfs = FALSE

	///All possible biomes in assoc list as type || instance
	var/list/biomes = list()

	// Z-manager stuff
	var/station_start  // should only be used for maploading-related tasks
	var/space_levels_so_far = 0
	var/near_space_levels_so_far = 0
	var/list/z_list
	var/datum/space_level/transit
	var/datum/space_level/empty_space
	var/num_of_res_levels = 1
	/// True when in the process of adding a new Z-level, global locking
	var/adding_new_zlevel = FALSE

	var/current_mining

//dlete dis once #39770 is resolved
/datum/controller/subsystem/mapping/proc/HACK_LoadMapConfig()
	if(!config)
#ifdef FORCE_MAP
		config = load_map_config(FORCE_MAP)
#else
		config = load_map_config(error_if_missing = FALSE)
#endif

/datum/controller/subsystem/mapping/Initialize(timeofday)
	HACK_LoadMapConfig()
	if(initialized)
		return
	if(config.defaulted)
		var/old_config = config
		config = global.config.defaultmap
		if(!config || config.defaulted)
			to_chat(world, span_boldannounce("Не могу загрузить следующий или стандартный конфиг карты, ставлю Meta Station."))
			config = old_config
	initialize_biomes()
	loadWorld()
	repopulate_sorted_areas()
	process_teleport_locs()			//Sets up the wizard teleport locations
	preloadTemplates()
	run_map_generation()

#ifndef LOWMEMORYMODE
	// Create space ruin levels
	while (space_levels_so_far < config.space_ruin_levels)
		++space_levels_so_far
		LAZYADD(SSzclear.free_levels, add_new_zlevel("Empty Area [space_levels_so_far]", ZTRAITS_SPACE, orbital_body_type = null))
	while (near_space_levels_so_far < config.space_ruin_levels)
		++near_space_levels_so_far
		add_new_zlevel("Near Space [near_space_levels_so_far]", ZTRAITS_NEAR_SPACE, orbital_body_type = null)
	// and one level with no ruins
	for (var/i in 1 to config.space_empty_levels)
		++space_levels_so_far
		empty_space = add_new_zlevel("Empty Area [space_levels_so_far]", list(ZTRAIT_LINKAGE = SELFLOOPING), orbital_body_type = /datum/orbital_object/z_linked/beacon/weak)

	// Pick a random away mission.
	if(CONFIG_GET(flag/roundstart_away))
		createRandomZlevel()

	// Generate mining ruins
	loading_ruins = TRUE
	var/list/lava_ruins = levels_by_trait(ZTRAIT_LAVA_RUINS)
	if (lava_ruins.len)
		seedRuins(lava_ruins, CONFIG_GET(number/lavaland_budget), list(/area/lavaland/surface/outdoors/unexplored), lava_ruins_templates)
		for (var/lava_z in lava_ruins)
			spawn_rivers(lava_z)

	var/list/gens_ruins = levels_by_trait(ZTRAIT_GENSOKYO_RUINS)
	if (gens_ruins.len)
		seedRuins(gens_ruins, CONFIG_GET(number/lavaland_budget), /area/mine/unexplored/gensokyo, gens_ruins_templates)
	var/list/ice_ruins = levels_by_trait(ZTRAIT_ICE_RUINS)
	if (ice_ruins.len)
		// needs to be whitelisted for underground too so place_below ruins work
		seedRuins(ice_ruins, CONFIG_GET(number/icemoon_budget), list(/area/icemoon/surface/outdoors/unexplored, /area/icemoon/underground/unexplored), ice_ruins_templates)
		for (var/ice_z in ice_ruins)
			spawn_rivers(ice_z, 4, /turf/open/openspace/icemoon, /area/icemoon/surface/outdoors/unexplored/rivers)

	var/list/ice_ruins_underground = levels_by_trait(ZTRAIT_ICE_RUINS_UNDERGROUND)
	if (ice_ruins_underground.len)
		seedRuins(ice_ruins_underground, CONFIG_GET(number/icemoon_budget), list(/area/icemoon/underground/unexplored), ice_ruins_underground_templates)
		for (var/ice_z in ice_ruins_underground)
			spawn_rivers(ice_z, 4, level_trait(ice_z, ZTRAIT_BASETURF), /area/icemoon/underground/unexplored/rivers)

	// Generate deep space ruins
	var/list/space_ruins = levels_by_trait(ZTRAIT_NEAR_SPACE_LEVEL)
	if (space_ruins.len)
		seedRuins(space_ruins, CONFIG_GET(number/space_budget), list(/area/space), space_ruins_templates)
	seedStation() //yogs - random station rooms
	loading_ruins = FALSE
#endif
	// Add the transit level
	transit = add_new_zlevel("Transit/Reserved", list(ZTRAIT_RESERVED = TRUE))
	repopulate_sorted_areas()
	// Set up Z-level transitions.
	setup_map_transitions()
	generate_station_area_list()
	initialize_reserved_level(transit.z_value)
	return ..()

/datum/controller/subsystem/mapping/proc/wipe_reservations(wipe_safety_delay = 100)
	if(clearing_reserved_turfs || !initialized)			//in either case this is just not needed.
		return
	clearing_reserved_turfs = TRUE
	SSshuttle.transit_requesters.Cut()
	message_admins("Clearing dynamic reservation space.")
	var/list/obj/docking_port/mobile/in_transit = list()
	for(var/i in SSshuttle.transit)
		var/obj/docking_port/stationary/transit/T = i
		if(!istype(T))
			continue
		in_transit[T] = T.get_docked()
	var/go_ahead = world.time + wipe_safety_delay
	if(in_transit.len)
		message_admins("Shuttles in transit detected. Attempting to fast travel. Timeout is [wipe_safety_delay/10] seconds.")
	var/list/cleared = list()
	for(var/i in in_transit)
		INVOKE_ASYNC(src, PROC_REF(safety_clear_transit_dock), i, in_transit[i], cleared)
	UNTIL((go_ahead < world.time) || (cleared.len == in_transit.len))
	do_wipe_turf_reservations()
	clearing_reserved_turfs = FALSE

/datum/controller/subsystem/mapping/proc/safety_clear_transit_dock(obj/docking_port/stationary/transit/T, obj/docking_port/mobile/M, list/returning)
	M.setTimer(0)
	var/error = M.initiate_docking(M.destination)
	if(!error)
		returning += M
		qdel(T, TRUE)

/* Nuke threats, for making the blue tiles on the station go RED
Used by the AI doomsday and the self-destruct nuke.
*/

/datum/controller/subsystem/mapping/proc/add_nuke_threat(datum/nuke)
	nuke_threats[nuke] = TRUE
	check_nuke_threats()

/datum/controller/subsystem/mapping/proc/remove_nuke_threat(datum/nuke)
	nuke_threats -= nuke
	check_nuke_threats()

/datum/controller/subsystem/mapping/proc/check_nuke_threats()
	for(var/datum/d in nuke_threats)
		if(!istype(d) || QDELETED(d))
			nuke_threats -= d

	for(var/N in nuke_tiles)
		var/turf/open/floor/circuit/C = N
		C.update_icon()

/datum/controller/subsystem/mapping/Recover()
	flags |= SS_NO_INIT
	initialized = SSmapping.initialized
	map_templates = SSmapping.map_templates
	ruins_templates = SSmapping.ruins_templates
	space_ruins_templates = SSmapping.space_ruins_templates
	lava_ruins_templates = SSmapping.lava_ruins_templates
	ice_ruins_templates = SSmapping.ice_ruins_templates
	ice_ruins_underground_templates = SSmapping.ice_ruins_underground_templates
	shuttle_templates = SSmapping.shuttle_templates
	shelter_templates = SSmapping.shelter_templates
	unused_turfs = SSmapping.unused_turfs
	turf_reservations = SSmapping.turf_reservations
	used_turfs = SSmapping.used_turfs
	holodeck_templates = SSmapping.holodeck_templates
	transit = SSmapping.transit
	areas_in_z = SSmapping.areas_in_z

	config = SSmapping.config
	next_map_config = SSmapping.next_map_config

	clearing_reserved_turfs = SSmapping.clearing_reserved_turfs

	z_list = SSmapping.z_list

#define INIT_ANNOUNCE(X) to_chat(world, span_green("[X]")); log_world(X)
/datum/controller/subsystem/mapping/proc/LoadGroup(list/errorList, name, path, files, list/traits, list/default_traits, silent = FALSE, orbital_body_type)
	. = list()
	var/start_time = REALTIMEOFDAY

	if (!islist(files))  // handle single-level maps
		files = list(files)

	// check that the total z count of all maps matches the list of traits
	var/total_z = 0
	var/list/parsed_maps = list()
	for (var/file in files)
		var/full_path = "_maps/[path]/[file]"
		var/datum/parsed_map/pm = new(file(full_path))
		var/bounds = pm?.bounds
		if (!bounds)
			errorList |= full_path
			continue
		parsed_maps[pm] = total_z  // save the start Z of this file
		total_z += bounds[MAP_MAXZ] - bounds[MAP_MINZ] + 1

	if (!length(traits))  // null or empty - default
		for (var/i in 1 to total_z)
			traits += list(default_traits)
	else if (total_z != traits.len)  // mismatch
		INIT_ANNOUNCE("WARNING: [traits.len] trait sets specified for [total_z] z-levels in [path]!")
		if (total_z < traits.len)  // ignore extra traits
			traits.Cut(total_z + 1)
		while (total_z > traits.len)  // fall back to defaults on extra levels
			traits += list(default_traits)

	// preload the relevant space_level datums
	var/start_z = world.maxz + 1
	var/i = 0
	var/list/datum/space_level/space_levels = list()
	for (var/level in traits)
		space_levels += add_new_zlevel("[name][i ? " [i + 1]" : ""]", level)
		++i
	//Shared orbital body
	if(orbital_body_type)
		var/datum/orbital_object/z_linked/orbital_body = new orbital_body_type()
		for(var/datum/space_level/level as() in space_levels)
			level.orbital_body = orbital_body
			orbital_body.link_to_z(level)

	// load the maps
	for (var/P in parsed_maps)
		var/datum/parsed_map/pm = P
		if (!pm.load(1, 1, start_z + parsed_maps[P], no_changeturf = TRUE))
			errorList |= pm.original_path
	if(!silent)
		log_world("Map [name] loaded for [(REALTIMEOFDAY - start_time)/10] seconds!")
		switch(name)
			if("Station")
				name = "Станция"
			if("Lavaland")
				name = "Лаваленд"
		to_chat(world, span_green(" -- #<b>[name]</b>:> <b>[(REALTIMEOFDAY - start_time)/10]</b> -- "))
	return parsed_maps

/datum/controller/subsystem/mapping/proc/loadWorld()
	//if any of these fail, something has gone horribly, HORRIBLY, wrong
	var/list/FailedZs = list()

	// ensure we have space_level datums for compiled-in maps
	InitializeDefaultZLevels()

	// load the station
	station_start = world.maxz + 1
	log_world("Loading map config named [config.map_name]...")
	to_chat(world, span_green(" -- $<b>Настройка</b>:> <b>[config.map_name]</b> -- "))
	LoadGroup(FailedZs, "Station", config.map_path, config.map_file, config.traits, ZTRAITS_STATION, orbital_body_type = /datum/orbital_object/z_linked/station)

	if(SSdbcore.Connect())
		var/datum/db_query/query_round_map_name = SSdbcore.NewQuery({"
			UPDATE [format_table_name("round")] SET map_name = :map_name WHERE id = :round_id
		"}, list("map_name" = config.map_name, "round_id" = GLOB.round_id))
		query_round_map_name.Execute()
		qdel(query_round_map_name)

#ifndef LOWMEMORYMODE
	// TODO: remove this when the DB is prepared for the z-levels getting reordered
	while (world.maxz < (5 - 1) && near_space_levels_so_far < config.space_ruin_levels)
		++space_levels_so_far
		add_new_zlevel("Near Space [near_space_levels_so_far]", ZTRAITS_NEAR_SPACE, orbital_body_type = null)

	if(config.minetype == "lavaland")
		LoadGroup(FailedZs, "Lavaland", "map_files/Mining", "Lavaland.dmm", default_traits = ZTRAITS_LAVALAND, orbital_body_type = /datum/orbital_object/z_linked/lavaland)
	else if (!isnull(config.minetype) && config.minetype != "none")
		INIT_ANNOUNCE("WARNING: An unknown minetype '[config.minetype]' was set! This is being ignored! Update the maploader code!")
#endif

	if(LAZYLEN(FailedZs))	//but seriously, unless the server's filesystem is messed up this will never happen
		var/msg = "RED ALERT! The following map files failed to load: [FailedZs[1]]"
		if(FailedZs.len > 1)
			for(var/I in 2 to FailedZs.len)
				msg += ", [FailedZs[I]]"
		msg += ". Yell at your server host!"
		INIT_ANNOUNCE(msg)
#undef INIT_ANNOUNCE

	// Custom maps are removed after station loading so the map files does not persist for no reason.
	if(config.map_path == "custom")
		fdel("_maps/custom/[config.map_file]")
		// And as the file is now removed set the next map to default.
		next_map_config = load_map_config(default_to_box = TRUE)

GLOBAL_LIST_EMPTY(the_station_areas)

/datum/controller/subsystem/mapping/proc/generate_station_area_list()
	var/list/station_areas_blacklist = typecacheof(list(/area/space, /area/mine, /area/ruin, /area/asteroid/nearstation))
	for(var/area/A in world)
		if (is_type_in_typecache(A, station_areas_blacklist))
			continue
		if (!A.contents.len || !(A.area_flags & UNIQUE_AREA))
			continue
		var/turf/picked = A.contents[1]
		if (is_station_level(picked.z))
			GLOB.the_station_areas += A.type

	if(!GLOB.the_station_areas.len)
		log_world("ERROR: Station areas list failed to generate!")

/datum/controller/subsystem/mapping/proc/run_map_generation()
	for(var/area/A in world)
		A.RunGeneration()

/datum/controller/subsystem/mapping/proc/run_map_generation_in_z(desired_z_level)
	for(var/ar in SSmapping.areas_in_z["[desired_z_level]"])
		var/area/A = ar
		A.RunGeneration()

/datum/controller/subsystem/mapping/proc/maprotate()
	if(map_voted || SSmapping.next_map_config) //If voted or set by other means.
		return

	var/players = GLOB.clients.len
	var/list/mapvotes = list()
	//count votes
	var/pmv = CONFIG_GET(flag/preference_map_voting)
	if(pmv)
		for (var/client/c in GLOB.clients)
			var/vote = c.prefs.preferred_map
			if (!vote)
				if (global.config.defaultmap)
					mapvotes[global.config.defaultmap.map_name] += 1
				continue
			mapvotes[vote] += 1
	else
		for(var/M in global.config.maplist)
			mapvotes[M] = 1

	//filter votes
	for (var/map in mapvotes)
		if (!map)
			mapvotes.Remove(map)
			continue
		if (!(map in global.config.maplist))
			mapvotes.Remove(map)
			continue
		if(map in SSpersistence.blocked_maps)
			mapvotes.Remove(map)
			continue
		var/datum/map_config/VM = global.config.maplist[map]
		if (!VM)
			mapvotes.Remove(map)
			continue
		if (VM.voteweight <= 0)
			mapvotes.Remove(map)
			continue
		if (VM.config_min_users > 0 && players < VM.config_min_users)
			mapvotes.Remove(map)
			continue
		if (VM.config_max_users > 0 && players > VM.config_max_users)
			mapvotes.Remove(map)
			continue

		if(pmv)
			mapvotes[map] = mapvotes[map]*VM.voteweight

	var/pickedmap = pickweight(mapvotes)
	if (!pickedmap)
		return
	var/datum/map_config/VM = global.config.maplist[pickedmap]
	message_admins("Случайно выбираем [VM.map_name]")
	. = changemap(VM)
	if (. && VM.map_name != config.map_name)
		to_chat(world, span_boldannounce("Выбрана карта [VM.map_name] для следующего раунда!"))

/datum/controller/subsystem/mapping/proc/mapvote()
	if(map_voted || SSmapping.next_map_config) //If voted or set by other means.
		return
	if(SSvote.mode) //Theres already a vote running, default to rotation.
		maprotate()
	SSvote.initiate_vote("карту", "автоматическая ротация карт")

/datum/controller/subsystem/mapping/proc/changemap(datum/map_config/VM)
	if(!VM.MakeNextMap())
		next_map_config = load_map_config(default_to_box = TRUE)
		message_admins("Failed to set new map with next_map.json for [VM.map_name]! Using default as backup!")
		return

	next_map_config = VM
	return TRUE

/datum/controller/subsystem/mapping/proc/preloadTemplates(path = "_maps/templates/") //see master controller setup
	var/list/filelist = flist(path)
	for(var/map in filelist)
		var/datum/map_template/T = new(path = "[path][map]", rename = "[map]")
		map_templates[T.name] = T

	preloadRuinTemplates()
	preloadShuttleTemplates()
	preloadShelterTemplates()
	preloadHolodeckTemplates()

/datum/controller/subsystem/mapping/proc/preloadRuinTemplates()
	// Still supporting bans by filename
	var/list/banned = generateMapList("[global.config.directory]/lavaruinblacklist.txt")
	banned += generateMapList("[global.config.directory]/spaceruinblacklist.txt")
	banned += generateMapList("[global.config.directory]/iceruinblacklist.txt")

	for(var/item in sort_list(subtypesof(/datum/map_template/ruin), GLOBAL_PROC_REF(cmp_ruincost_priority)))
		var/datum/map_template/ruin/ruin_type = item
		// screen out the abstract subtypes
		if(!initial(ruin_type.id))
			continue
		var/datum/map_template/ruin/R = new ruin_type()

		if(banned.Find(R.mappath))
			continue

		map_templates[R.name] = R
		ruins_templates[R.name] = R

		if(istype(R, /datum/map_template/ruin/lavaland))
			lava_ruins_templates[R.name] = R
		else if(istype(R, /datum/map_template/ruin/gensokyo))
			gens_ruins_templates[R.name] = R
		else if(istype(R, /datum/map_template/ruin/icemoon/underground))
			ice_ruins_underground_templates[R.name] = R
		else if(istype(R, /datum/map_template/ruin/icemoon))
			ice_ruins_templates[R.name] = R
		else if(istype(R, /datum/map_template/ruin/space))
			space_ruins_templates[R.name] = R
		else if(istype(R, /datum/map_template/ruin/station)) //yogs
			station_room_templates[R.name] = R //yogs
		else if(istype(R, /datum/map_template/ruin/maint)) // white
			station_room_templates[R.name] = R // white

/datum/controller/subsystem/mapping/proc/preloadShuttleTemplates()
	var/list/unbuyable = generateMapList("[global.config.directory]/unbuyableshuttles.txt")

	for(var/item in subtypesof(/datum/map_template/shuttle))
		var/datum/map_template/shuttle/shuttle_type = item
		if(!(initial(shuttle_type.suffix)))
			continue

		var/datum/map_template/shuttle/S = new shuttle_type()
		if(unbuyable.Find(S.mappath))
			S.can_be_bought = FALSE

		shuttle_templates[S.shuttle_id] = S
		map_templates[S.shuttle_id] = S

/datum/controller/subsystem/mapping/proc/preloadShelterTemplates()
	for(var/item in subtypesof(/datum/map_template/shelter))
		var/datum/map_template/shelter/shelter_type = item
		if(!(initial(shelter_type.mappath)))
			continue
		var/datum/map_template/shelter/S = new shelter_type()

		shelter_templates[S.shelter_id] = S
		map_templates[S.shelter_id] = S

/datum/controller/subsystem/mapping/proc/preloadHolodeckTemplates()
	for(var/item in subtypesof(/datum/map_template/holodeck))
		var/datum/map_template/holodeck/holodeck_type = item
		if(!(initial(holodeck_type.mappath)))
			continue
		var/datum/map_template/holodeck/holo_template = new holodeck_type()

		holodeck_templates[holo_template.template_id] = holo_template

//Manual loading of away missions.
/client/proc/admin_away()
	set name = "Load Away Mission"
	set category = "Адм.События"

	if(!holder ||!check_rights(R_FUN))
		return


	if(!GLOB.the_gateway)
		if(tgui_alert(usr, "There's no home gateway on the station. You sure you want to continue ?", "Uh oh", list("Yes", "No")) != "Yes")
			return

	var/list/possible_options = GLOB.potentialRandomZlevels + "Custom"
	var/away_name
	var/datum/space_level/away_level

	var/answer = input("What kind ? ","Away") as null|anything in possible_options
	switch(answer)
		if("Custom")
			var/mapfile = input("Pick file:", "File") as null|file
			if(!mapfile)
				return
			away_name = "[mapfile] custom"
			to_chat(usr,span_notice("Открываем врата к [away_name]..."))
			var/datum/map_template/template = new(mapfile, "Away Mission")
			away_level = template.load_new_z()
		else
			if(answer in GLOB.potentialRandomZlevels)
				away_name = answer
				to_chat(usr,span_notice("Открываем врата к [away_name]..."))
				var/datum/map_template/template = new(away_name, "Away Mission")
				away_level = template.load_new_z()
			else
				return

	message_admins("Admin [key_name_admin(usr)] has loaded [away_name] away mission.")
	log_admin("Admin [key_name(usr)] has loaded [away_name] away mission.")
	if(!away_level)
		message_admins("Loading [away_name] failed!")
		return

/datum/controller/subsystem/mapping/proc/RequestBlockReservation(width, height, z, type = /datum/turf_reservation, turf_type_override)
	UNTIL((!z || reservation_ready["[z]"]) && !clearing_reserved_turfs)
	var/datum/turf_reservation/reserve = new type
	if(turf_type_override)
		reserve.turf_type = turf_type_override
	if(!z)
		for(var/i in levels_by_trait(ZTRAIT_RESERVED))
			if(reserve.Reserve(width, height, i))
				return reserve
		//If we didn't return at this point, theres a good chance we ran out of room on the exisiting reserved z levels, so lets try a new one
		num_of_res_levels += 1
		var/datum/space_level/newReserved = add_new_zlevel("Transit/Reserved [num_of_res_levels]", list(ZTRAIT_RESERVED = TRUE))
		initialize_reserved_level(newReserved.z_value)
		if(reserve.Reserve(width, height, newReserved.z_value))
			return reserve
	else
		if(!level_trait(z, ZTRAIT_RESERVED))
			qdel(reserve)
			return
		else
			if(reserve.Reserve(width, height, z))
				return reserve
	QDEL_NULL(reserve)

//This is not for wiping reserved levels, use wipe_reservations() for that.
/datum/controller/subsystem/mapping/proc/initialize_reserved_level(z)
	UNTIL(!clearing_reserved_turfs)				//regardless, lets add a check just in case.
	clearing_reserved_turfs = TRUE			//This operation will likely clear any existing reservations, so lets make sure nothing tries to make one while we're doing it.
	if(!level_trait(z,ZTRAIT_RESERVED))
		clearing_reserved_turfs = FALSE
		CRASH("Invalid z level prepared for reservations.")
	var/turf/A = get_turf(locate(SHUTTLE_TRANSIT_BORDER,SHUTTLE_TRANSIT_BORDER,z))
	var/turf/B = get_turf(locate(world.maxx - SHUTTLE_TRANSIT_BORDER,world.maxy - SHUTTLE_TRANSIT_BORDER,z))
	var/block = block(A, B)
	for(var/t in block)
		// No need to empty() these, because it's world init and they're
		// already /turf/open/space/basic.
		var/turf/T = t
		T.turf_flags |= UNUSED_RESERVATION_TURF
	unused_turfs["[z]"] = block
	reservation_ready["[z]"] = TRUE
	clearing_reserved_turfs = FALSE

/datum/controller/subsystem/mapping/proc/reserve_turfs(list/turfs)
	for(var/i in turfs)
		var/turf/T = i
		T.empty(RESERVED_TURF_TYPE, RESERVED_TURF_TYPE, null, TRUE)
		LAZYINITLIST(unused_turfs["[T.z]"])
		unused_turfs["[T.z]"] |= T
		T.turf_flags |= UNUSED_RESERVATION_TURF
		GLOB.areas_by_type[world.area].contents += T
		CHECK_TICK

//DO NOT CALL THIS PROC DIRECTLY, CALL wipe_reservations().
/datum/controller/subsystem/mapping/proc/do_wipe_turf_reservations()
	PRIVATE_PROC(TRUE)
	UNTIL(initialized)							//This proc is for AFTER init, before init turf reservations won't even exist and using this will likely break things.
	for(var/i in turf_reservations)
		var/datum/turf_reservation/TR = i
		if(!QDELETED(TR))
			qdel(TR, TRUE)
	UNSETEMPTY(turf_reservations)
	var/list/clearing = list()
	for(var/l in unused_turfs)			//unused_turfs is an assoc list by z = list(turfs)
		if(islist(unused_turfs[l]))
			clearing |= unused_turfs[l]
	clearing |= used_turfs		//used turfs is an associative list, BUT, reserve_turfs() can still handle it. If the code above works properly, this won't even be needed as the turfs would be freed already.
	unused_turfs.Cut()
	used_turfs.Cut()
	reserve_turfs(clearing)

///Initialize all biomes, assoc as type || instance
/datum/controller/subsystem/mapping/proc/initialize_biomes()
	for(var/biome_path in subtypesof(/datum/biome))
		var/datum/biome/biome_instance = new biome_path()
		biomes[biome_path] += biome_instance

/datum/controller/subsystem/mapping/proc/reg_in_areas_in_z(list/areas)
	for(var/B in areas)
		var/area/A = B
		A.reg_in_areas_in_z()

/datum/controller/subsystem/mapping/proc/get_isolated_ruin_z()
	if(!isolated_ruins_z)
		isolated_ruins_z = add_new_zlevel("Isolated Ruins/Reserved", list(ZTRAIT_RESERVED = TRUE, ZTRAIT_ISOLATED_RUINS = TRUE))
		initialize_reserved_level(isolated_ruins_z.z_value)
	return isolated_ruins_z.z_value
