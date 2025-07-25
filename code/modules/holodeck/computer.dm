/*
Map Template Holodeck

Holodeck finds the location of mapped_start_area and loads offline_program in it on LateInitialize. It then passes its program templates to Holodeck.js in the form of program_cache and emag_programs. when a user selects a program the
ui calls load_program() with the id of the selected program.
load_program() -> map_template/load() on map_template/holodeck.

holodeck map templates:
1. have an update_blacklist that doesnt allow placing on non holofloors (except for engine floors so you can repair it)
2. has should_place_on_top = FALSE, so that the baseturfs list doesnt pull a kilostation oom crash
3. has returns_created = TRUE, so that SSatoms gives the map template a list of spawned atoms
all the fancy flags and shit are added to holodeck objects in finish_spawn()

Easiest way to add new holodeck programs:
1. Define new map template datums in code/modules/holodeck/holodeck_map_templates, make sure they have the access flags
of the holodeck you want them to be able to load, for the onstation holodeck the flag is STATION_HOLODECK.
2. Create the new map templates in _maps/templates (remember theyre 9x10, and make sure they have area/noop or else it will fuck with linked)
all turfs in holodeck programs MUST be of type /turf/open/floor/holofloor, OR /turf/open/floor/engine, or they will block future programs!

Note: if youre looking at holodeck code because you want to see how returns_created is handled so that templates return a list of atoms
created from them: make sure you handle that list correctly! Either copy them by value and delete them or reference it and handle qdel'ing
and clear when youre done! if you dont i will use :newspaper2: on you
*/

#define HOLODECK_CD 2 SECONDS
#define HOLODECK_DMG_CD 5 SECONDS


/obj/machinery/computer/holodeck
	name = "консоль управления голодеком"
	desc = "Компьютер, который использется для управления ближайшим голодеком."
	icon_screen = "holocontrol"
	idle_power_usage = 1000
	active_power_usage = 5000

	//new vars
	///what area type this holodeck loads into. linked turns into the nearest instance of this area
	var/area/mapped_start_area = /area/holodeck/rec_center

	///the currently used map template
	var/datum/map_template/holodeck/template

	///bottom left corner of the loading room, used for placing
	var/turf/bottom_left

	///if TRUE the holodeck is busy spawning another simulation and should immediately stop loading the newest one
	var/spawning_simulation = FALSE

	//old vars

	///the area that this holodeck loads templates into, used for power and deleting holo objects that leave it
	var/area/holodeck/linked

	///what program is loaded right now or is about to be loaded
	var/program = "holodeck_offline"
	var/last_program

	///the default program loaded by this holodeck when spawned and when deactivated
	var/offline_program = "holodeck_offline"

	///stores all of the unrestricted holodeck map templates that this computer has access to
	var/list/program_cache
	///stores all of the restricted holodeck map templates that this computer has access to
	var/list/emag_programs

	///subtypes of this (but not this itself) are loadable programs
	var/program_type = /datum/map_template/holodeck

	///every holo object created by the holodeck goes in here to track it
	var/list/spawned = list()
	var/list/effects = list() //like above, but for holo effects

	///TRUE if the holodeck is using extra power because of a program, FALSE otherwise
	var/active = FALSE
	///increases the holodeck cooldown if TRUE, causing the holodeck to take longer to allow loading new programs
	var/damaged = FALSE

	//creates the timer that determines if another program can be manually loaded
	COOLDOWN_DECLARE(holodeck_cooldown)

/obj/machinery/computer/holodeck/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/holodeck/LateInitialize()//from here linked is populated and the program list is generated. its also set to load the offline program
	linked = GLOB.areas_by_type[mapped_start_area]
	bottom_left = locate(linked.x, linked.y, src.z)

	var/area/computer_area = get_area(src)
	if(istype(computer_area, /area/holodeck))
		log_mapping("Holodeck computer cannot be in a holodeck, This would cause circular power dependency.")
		qdel(src)
		return

	// the following is necessary for power reasons
	if(!linked)
		log_world("No matching holodeck area found")
		qdel(src)
		return
	else if (!offline_program)
		stack_trace("Holodeck console created without an offline program")
		qdel(src)
		return

	else
		linked.linked = src
		var/area/my_area = get_area(src)
		if(my_area)
			linked.power_usage = my_area.power_usage
		else
			linked.power_usage = list(AREA_USAGE_LEN)

	COOLDOWN_START(src, holodeck_cooldown, HOLODECK_CD)
	generate_program_list()
	load_program(offline_program,TRUE)

///adds all programs that this holodeck has access to, and separates the restricted and unrestricted ones
/obj/machinery/computer/holodeck/proc/generate_program_list()
	for(var/typekey in subtypesof(program_type))
		var/datum/map_template/holodeck/program = typekey
		var/list/info_this = list("id" = initial(program.template_id), "name" = initial(program.name))
		if(initial(program.restricted))
			LAZYADD(emag_programs, list(info_this))
		else
			LAZYADD(program_cache, list(info_this))

/obj/machinery/computer/holodeck/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Holodeck", name)
		ui.open()

/obj/machinery/computer/holodeck/ui_data(mob/user)
	var/list/data = list()

	data["default_programs"] = program_cache
	if(obj_flags & EMAGGED)
		data["emagged"] = TRUE
		data["emag_programs"] = emag_programs
	data["program"] = program
	data["can_toggle_safety"] = issilicon(user) || isAdminGhostAI(user)
	return data

/obj/machinery/computer/holodeck/ui_act(action, params)
	. = ..()
	if(.)
		return
	. = TRUE
	switch(action)
		if("load_program")
			var/program_to_load = params["id"]

			var/list/checked = program_cache.Copy()
			if (obj_flags & EMAGGED)
				checked |= emag_programs
			var/valid = FALSE //dont tell security about this

			for (var/prog in checked)//checks if program_to_load is any one of the loadable programs, if it isnt then it rejects it
				var/list/check_list = prog
				if (check_list["id"] == program_to_load)
					valid = TRUE
					break
			if (!valid)
				return FALSE
			//load the map_template that program_to_load represents
			if(program_to_load)
				load_program(program_to_load)
		if("safety")
			if (!(obj_flags & EMAGGED) || !issilicon(usr))
				return
			if((obj_flags & EMAGGED) && program)
				emergency_shutdown()
			nerf(obj_flags & EMAGGED,FALSE)
			obj_flags ^= EMAGGED
			say("Протоколы безопасности восстановлены. Перезагрузка...")
			log_game("[key_name(usr)] disabled Holodeck safeties.")

///this is what makes the holodeck not spawn anything on broken tiles (space and non engine plating / non holofloors)
/datum/map_template/holodeck/update_blacklist(turf/placement, list/input_blacklist)
	for (var/_turf in get_affected_turfs(placement))
		var/turf/possible_blacklist = _turf
		if (possible_blacklist.holodeck_compatible)
			continue
		input_blacklist += possible_blacklist

///loads the template whose id string it was given ("offline_program" loads datum/map_template/holodeck/offline)
/obj/machinery/computer/holodeck/proc/load_program(map_id, force = FALSE, add_delay = TRUE)
	if (program == map_id)
		return

	if (!is_operational)//load_program is called once with a timer (in toggle_power) we dont want this to load anything if its off
		map_id = offline_program
		force = TRUE

	if (!force && (!COOLDOWN_FINISHED(src, holodeck_cooldown) || spawning_simulation))
		say("ОШИБКА. Перекалибровка...")
		return

	if(spawning_simulation)
		return

	if (add_delay)
		COOLDOWN_START(src, holodeck_cooldown, (damaged ? HOLODECK_CD + HOLODECK_DMG_CD : HOLODECK_CD))
		if (damaged && floorcheck())
			damaged = FALSE

	spawning_simulation = TRUE
	active = (map_id != offline_program)
	update_use_power(active + IDLE_POWER_USE)
	program = map_id

	//clear the items from the previous program
	for (var/_item in spawned)
		var/obj/holo_item = _item
		derez(holo_item)

	for (var/_effect in effects)
		var/obj/effect/holodeck_effect/holo_effect = _effect
		effects -= holo_effect
		holo_effect.deactivate(src)

	//makes sure that any time a holoturf is inside a baseturf list (e.g. if someone put a wall over it) its set to the OFFLINE turf
	//so that you cant bring turfs from previous programs into other ones (like putting the plasma burn turf into lounge for example)
	for (var/turf/closed/holo_turf in linked)
		for (var/_baseturf in holo_turf.baseturfs)
			if (ispath(_baseturf, /turf/open/floor/holofloor))
				holo_turf.baseturfs -= _baseturf
				holo_turf.baseturfs += /turf/open/floor/holofloor/plating

	template = SSmapping.holodeck_templates[map_id]
	template.load(bottom_left) //this is what actually loads the holodeck simulation into the map

	if(template.restricted)
		log_game("[key_name(usr)] loaded a restricted Holodeck program: [program].")
		message_admins("[ADMIN_LOOKUPFLW(usr)] loaded a restricted Holodeck program: [program].")

	spawned = template.created_atoms //populate the spawned list with the atoms belonging to the holodeck

	if(istype(template, /datum/map_template/holodeck/thunderdome1218) && !SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_MEDISIM])
		say("Специальная заметка от разработчика \"1218 AD\": I see you too are interested in the REAL dark ages of humanity! I've made this program also unlock some interesting shuttle designs on any communication console around. Have fun!")
		SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_MEDISIM] = TRUE

	nerf(!(obj_flags & EMAGGED))
	finish_spawn()

///finalizes objects in the spawned list
/obj/machinery/computer/holodeck/proc/finish_spawn()
	//this is used for holodeck effects (like spawners). otherwise they dont do shit
	//holo effects are taken out of the spawned list and added to the effects list
	//turfs and overlay objects are taken out of the spawned list
	//objects get resistance flags added to them
	for (var/atom/atoms in spawned)
		RegisterSignal(atoms, COMSIG_PARENT_PREQDELETED, PROC_REF(remove_from_holo_lists))
		atoms.flags_1 |= HOLOGRAM_1

		if (isholoeffect(atoms))//activates holo effects and transfers them from the spawned list into the effects list
			var/obj/effect/holodeck_effect/holo_effect = atoms
			effects += holo_effect
			spawned -= holo_effect
			var/atom/active_effect = holo_effect.activate(src)
			if(istype(active_effect) || islist(active_effect))
				spawned += active_effect // we want mobs or objects spawned via holoeffects to be tracked as objects
			continue

		if (isobj(atoms))
			var/obj/holo_object = atoms
			holo_object.resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

			if (isstructure(holo_object))
				holo_object.flags_1 |= NODECONSTRUCT_1
				continue

			if (ismachinery(holo_object))
				var/obj/machinery/machines = holo_object
				machines.flags_1 |= NODECONSTRUCT_1
				machines.power_change()

				if(istype(machines, /obj/machinery/button))
					var/obj/machinery/button/buttons = machines
					buttons.setup_device()
	spawning_simulation = FALSE

///this qdels holoitems that should no longer exist for whatever reason
/obj/machinery/computer/holodeck/proc/derez(obj/object, silent = TRUE, forced = FALSE)
	spawned -= object
	if(!object)
		return
	UnregisterSignal(object, COMSIG_PARENT_PREQDELETED)
	var/turf/target_turf = get_turf(object)
	for(var/c in object) //make sure that things inside of a holoitem are moved outside before destroying it
		var/atom/movable/object_contents = c
		object_contents.forceMove(target_turf)

	if(!silent)
		visible_message(span_notice("[object] пропадает!"))

	qdel(object)

/obj/machinery/computer/holodeck/proc/remove_from_holo_lists(datum/to_remove, _forced)
	spawned -= to_remove
	UnregisterSignal(to_remove, COMSIG_PARENT_PREQDELETED)

/obj/machinery/computer/holodeck/process(delta_time)
	if(damaged && DT_PROB(5, delta_time))
		for(var/turf/holo_turf in linked)
			if(DT_PROB(2.5, delta_time))
				do_sparks(2, 1, holo_turf)
				return
	. = ..()
	if(!. || program == offline_program)//we dont need to scan the holodeck if the holodeck is offline
		return

	if(!floorcheck()) //if any turfs in the floor of the holodeck are broken
		emergency_shutdown()
		damaged = TRUE
		visible_message("Голодек перегружается!")
		for(var/turf/holo_turf in linked)
			if(prob(30))
				do_sparks(2, 1, holo_turf)
			SSexplosions.lowturf += holo_turf
			holo_turf.hotspot_expose(1000,500,1)

	if(!(obj_flags & EMAGGED))
		for(var/item in spawned)
			if(!(get_turf(item) in linked))
				derez(item)
	for(var/_effect in effects)
		var/obj/effect/holodeck_effect/holo_effect = _effect
		holo_effect.tick()
	update_mode_power_usage(ACTIVE_POWER_USE, 50 + spawned.len * 3 + effects.len * 5)

/obj/machinery/computer/holodeck/proc/toggle_power(toggleOn = FALSE)
	if(active == toggleOn)
		return

	if(toggleOn)
		if(last_program && (last_program != offline_program))
			addtimer(CALLBACK(src,PROC_REF(load_program), last_program, TRUE), 25)
		active = TRUE
	else
		last_program = program
		load_program(offline_program, TRUE)
		active = FALSE

/obj/machinery/computer/holodeck/power_change()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(toggle_power), !machine_stat)

///shuts down the holodeck and force loads the offline_program
/obj/machinery/computer/holodeck/proc/emergency_shutdown()
	last_program = program
	active = FALSE
	load_program(offline_program, TRUE)

///returns TRUE if the entire floor of the holodeck is intact, returns FALSE if any are broken
/obj/machinery/computer/holodeck/proc/floorcheck()
	for(var/turf/holo_floor in linked)
		if(isspaceturf(holo_floor))
			return FALSE
		if(!holo_floor.intact)
			return FALSE
	return TRUE

///changes all weapons in the holodeck to do stamina damage if set
/obj/machinery/computer/holodeck/proc/nerf(nerf_this, is_loading = TRUE)
	if (!nerf_this && is_loading)
		return
	for(var/obj/item/to_be_nerfed in spawned)
		to_be_nerfed.damtype = nerf_this ? STAMINA : initial(to_be_nerfed.damtype)
	for(var/to_be_nerfed in effects)
		var/obj/effect/holodeck_effect/holo_effect = to_be_nerfed
		holo_effect.safety(nerf_this)

/obj/machinery/computer/holodeck/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	if(!LAZYLEN(emag_programs))
		to_chat(user, "[src] does not seem to have a card swipe port. It must be an inferior model.")
		return
	playsound(src, "sparks", 75, TRUE)
	obj_flags |= EMAGGED
	to_chat(user, span_warning("You vastly increase projector power and override the safety and security protocols."))
	say("Warning. Automatic shutoff and derezzing protocols have been corrupted. Please call Nanotrasen maintenance and do not use the simulator.")
	log_game("[key_name(user)] emagged the Holodeck Control Console")
	nerf(!(obj_flags & EMAGGED),FALSE)

/obj/machinery/computer/holodeck/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	emergency_shutdown()

/obj/machinery/computer/holodeck/ex_act(severity, target)
	emergency_shutdown()
	return ..()

/obj/machinery/computer/holodeck/Destroy()
	emergency_shutdown()
	if(linked)
		linked.linked = null
		linked.power_usage = list(AREA_USAGE_LEN)
	return ..()

/obj/machinery/computer/holodeck/blob_act(obj/structure/blob/B)
	emergency_shutdown()
	return ..()

#undef HOLODECK_CD
#undef HOLODECK_DMG_CD
