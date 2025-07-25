// Crew has to build a bluespace cannon
// Cargo orders part for high price
// Requires high amount of power
// Requires high level stock parts
/datum/station_goal/bluespace_cannon
	name = "Блюспейс артиллерия"

/datum/station_goal/bluespace_cannon/get_report()
	return {"\nНашего военного присутствия в вашем секторе недостаточно.
		\nНам нужно, чтобы вы построили БСА-[rand(1,99)] Артиллерию на борту вашей станции.
		\n
		\nБазовые части доступны для отправки грузовым транспортом.
		\n - Военно-космическое Командование NanoTrasen"}

/datum/station_goal/bluespace_cannon/on_report()
	//Unlock BSA parts
	var/datum/supply_pack/engineering/bsa/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/bsa]
	P.special_enabled = TRUE

/datum/station_goal/bluespace_cannon/check_completion()
	if(..())
		return TRUE
	var/obj/machinery/bsa/full/B = locate()
	if(B && !B.machine_stat)
		return TRUE
	return FALSE

/obj/machinery/bsa
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	density = TRUE
	anchored = TRUE

/obj/machinery/bsa/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I, 10)
	return TRUE

/obj/machinery/bsa/back
	name = "Генератор орудия"
	desc = "Генерирует пушечный импульс. Должен быть соединен с фузором."
	icon_state = "power_box"

/obj/machinery/bsa/back/multitool_act(mob/living/user, obj/item/I)
	if(!multitool_check_buffer(user, I)) //make sure it has a data buffer
		return
	var/obj/item/multitool/M = I
	M.buffer = src
	to_chat(user, span_notice("You store linkage information in [I] buffer."))
	return TRUE

/obj/machinery/bsa/front
	name = "Ствол орудия"
	desc = "Не стойте перед пушкой во время выстрела. Должен быть соединен с фузором."
	icon_state = "emitter_center"

/obj/machinery/bsa/front/multitool_act(mob/living/user, obj/item/I)
	if(!multitool_check_buffer(user, I)) //make sure it has a data buffer
		return
	var/obj/item/multitool/M = I
	M.buffer = src
	to_chat(user, span_notice("You store linkage information in [I] buffer."))
	return TRUE

/obj/machinery/bsa/middle
	name = "Фузор орудия"
	desc = "Содержание засекречено командованием Нанотрейзен. Должен быть соеденен с другим частями БСА с помощью мультитула."
	icon_state = "fuel_chamber"
	var/datum/weakref/back_ref
	var/datum/weakref/front_ref

/obj/machinery/bsa/middle/multitool_act(mob/living/user, obj/item/I)
	if(!multitool_check_buffer(user, I))
		return
	var/obj/item/multitool/M = I
	if(M.buffer)
		if(istype(M.buffer, /obj/machinery/bsa/back))
			back_ref = WEAKREF(M.buffer)
			to_chat(user, span_notice("You link [src] with [M.buffer]."))
			M.buffer = null
		else if(istype(M.buffer, /obj/machinery/bsa/front))
			front_ref = WEAKREF(M.buffer)
			to_chat(user, span_notice("You link [src] with [M.buffer]."))
			M.buffer = null
	else
		to_chat(user, span_warning("[I] data buffer is empty!"))
	return TRUE

/obj/machinery/bsa/middle/proc/check_completion()
	var/obj/machinery/bsa/front/front = front_ref?.resolve()
	var/obj/machinery/bsa/back/back = back_ref?.resolve()
	if(!front || !back)
		return "Не обнаружено связанных частей!"
	if(!front.anchored || !back.anchored || !anchored)
		return "Связанные части не прикручены!"
	if(front.y != y || back.y != y || !(front.x > x && back.x < x || front.x < x && back.x > x) || front.z != z || back.z != z)
		return "Неправильное расположение деталей!"
	if(!has_space())
		return "Недостаточно места!"

/obj/machinery/bsa/middle/proc/has_space()
	var/cannon_dir = get_cannon_direction()
	var/x_min
	var/x_max
	switch(cannon_dir)
		if(EAST)
			x_min = x - 4 //replace with defines later
			x_max = x + 6
		if(WEST)
			x_min = x + 4
			x_max = x - 6

	for(var/turf/T in block(locate(x_min,y-1,z),locate(x_max,y+1,z)))
		if(T.density || isspaceturf(T))
			return FALSE
	return TRUE

/obj/machinery/bsa/middle/proc/get_cannon_direction()
	var/obj/machinery/bsa/front/front = front_ref?.resolve()
	var/obj/machinery/bsa/back/back = back_ref?.resolve()
	if(!front || !back)
		return
	if(front.x > x && back.x < x)
		return EAST
	else if(front.x < x && back.x > x)
		return WEST


/obj/machinery/bsa/full
	name = "Блюспейс Артиллерия"
	desc = "Артиллерия дальнего радиуса действия."
	icon = 'icons/obj/lavaland/cannon.dmi'
	icon_state = "orbital_cannon1"
	var/static/mutable_appearance/top_layer
	var/ex_power = 3
	var/power_used_per_shot = 2000000 //enough to kil standard apc - todo : make this use wires instead and scale explosion power with it
	var/ready
	pixel_y = -32
	pixel_x = -192
	bound_width = 352
	bound_x = -192
	appearance_flags = NONE //Removes default TILE_BOUND

/obj/machinery/bsa/full/wrench_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/bsa/full/proc/get_front_turf()
	switch(dir)
		if(WEST)
			return locate(x - 7,y,z)
		if(EAST)
			return locate(x + 7,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/proc/get_back_turf()
	switch(dir)
		if(WEST)
			return locate(x + 5,y,z)
		if(EAST)
			return locate(x - 5,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/proc/get_target_turf()
	switch(dir)
		if(WEST)
			return locate(1,y,z)
		if(EAST)
			return locate(world.maxx,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/Initialize(mapload, cannon_direction = WEST)
	. = ..()
	if(!top_layer)
		top_layer = mutable_appearance(icon, layer = ABOVE_MOB_LAYER)
		top_layer.plane = GAME_PLANE_UPPER
	switch(cannon_direction)
		if(WEST)
			setDir(WEST)
			top_layer.icon_state = "top_west"
			icon_state = "cannon_west"
		if(EAST)
			setDir(EAST)
			pixel_x = -128
			bound_x = -128
			top_layer.icon_state = "top_east"
			icon_state = "cannon_east"
	add_overlay(top_layer)
	reload()

/obj/machinery/bsa/full/proc/fire(mob/user, turf/bullseye)
	reload()

	var/turf/point = get_front_turf()
	var/turf/target = get_target_turf()
	var/atom/movable/blocker
	for(var/T in get_line(get_step(point, dir), target))
		var/turf/tile = T
		if(SEND_SIGNAL(tile, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
			blocker = tile
		else
			for(var/AM in tile)
				var/atom/movable/stuff = AM
				if(SEND_SIGNAL(stuff, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
					blocker = stuff
					break
		if(blocker)
			target = tile
			break
		else
			SSexplosions.highturf += tile //also fucks everything else on the turf
	point.Beam(target, icon_state = "bsa_beam", time = 5 SECONDS, maxdistance = world.maxx) //ZZZAP
	new /obj/effect/temp_visual/bsa_splash(point, dir)

	if(!blocker)
		message_admins("[ADMIN_LOOKUPFLW(user)] has launched an artillery strike targeting [ADMIN_VERBOSEJMP(bullseye)].")
		log_game("[key_name(user)] has launched an artillery strike targeting [AREACOORD(bullseye)].")
		explosion(bullseye, ex_power, ex_power*2, ex_power*4)
	else
		message_admins("[ADMIN_LOOKUPFLW(user)] has launched an artillery strike targeting [ADMIN_VERBOSEJMP(bullseye)] but it was blocked by [blocker] at [ADMIN_VERBOSEJMP(target)].")
		log_game("[key_name(user)] has launched an artillery strike targeting [AREACOORD(bullseye)] but it was blocked by [blocker] at [AREACOORD(target)].")


/obj/machinery/bsa/full/proc/reload()
	ready = FALSE
	use_power(power_used_per_shot)
	addtimer(CALLBACK(src, PROC_REF(ready_cannon)), 600)

/obj/machinery/bsa/full/proc/ready_cannon()
	ready = TRUE

/obj/structure/filler
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/obj/machinery/parent

/obj/structure/filler/ex_act()
	return

/obj/machinery/computer/bsa_control
	name = "Компьютер блюспейс артиллерии"
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/computer/bsa_control
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "control_boxp"

	var/datum/weakref/cannon_ref
	var/notice
	var/target
	var/area_aim = FALSE //should also show areas for targeting

/obj/machinery/computer/bsa_control/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/computer/bsa_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BluespaceArtillery", name)
		ui.open()

/obj/machinery/computer/bsa_control/ui_data()
	var/obj/machinery/bsa/full/cannon = cannon_ref?.resolve()
	var/list/data = list()
	data["ready"] = cannon ? cannon.ready : FALSE
	data["connected"] = cannon
	data["notice"] = notice
	data["unlocked"] = GLOB.bsa_unlock
	if(target)
		data["target"] = get_target_name()
	return data

/obj/machinery/computer/bsa_control/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("build")
			cannon_ref = WEAKREF(deploy())
			. = TRUE
		if("fire")
			fire(usr)
			. = TRUE
		if("recalibrate")
			calibrate(usr)
			. = TRUE
	update_icon()

/obj/machinery/computer/bsa_control/proc/calibrate(mob/user)
	if(!GLOB.bsa_unlock)
		return
	var/list/gps_locators = list()
	for(var/datum/component/gps/G in GLOB.GPS_list) //nulls on the list somehow
		if(G.tracking)
			gps_locators[G.gpstag] = G

	var/list/options = gps_locators
	if(area_aim)
		options += GLOB.teleportlocs
	var/V = input(user,"Select target", "Select target",null) in options|null
	target = options[V]


/obj/machinery/computer/bsa_control/proc/get_target_name()
	if(istype(target, /area))
		return get_area_name(target, TRUE)
	else if(istype(target, /datum/component/gps))
		var/datum/component/gps/G = target
		return G.gpstag

/obj/machinery/computer/bsa_control/proc/get_impact_turf()
	if(istype(target, /area))
		return pick(get_area_turfs(target))
	else if(istype(target, /datum/component/gps))
		var/datum/component/gps/G = target
		return get_turf(G.parent)

/obj/machinery/computer/bsa_control/proc/fire(mob/user)
	var/obj/machinery/bsa/full/cannon = cannon_ref?.resolve()
	if(!cannon)
		notice = "Не найдено пушки!"
		return
	if(cannon.machine_stat)
		notice = "Пушка не запитана!"
		return
	notice = null
	cannon.fire(user, get_impact_turf())

/obj/machinery/computer/bsa_control/proc/deploy(force=FALSE)
	var/obj/machinery/bsa/full/prebuilt = locate() in range(7) //In case of adminspawn
	if(prebuilt)
		return prebuilt

	var/obj/machinery/bsa/middle/centerpiece = locate() in range(7)
	if(!centerpiece)
		notice = "Части БСА поблизости не обнаружены"
		return null
	notice = centerpiece.check_completion()
	if(notice)
		return null
	//Totally nanite construction system not an immersion breaking spawning
	var/datum/effect_system/smoke_spread/s = new
	s.set_up(4,get_turf(centerpiece))
	s.start()
	var/obj/machinery/bsa/full/cannon = new(get_turf(centerpiece),centerpiece.get_cannon_direction())
	QDEL_NULL(centerpiece.front_ref)
	QDEL_NULL(centerpiece.back_ref)
	qdel(centerpiece)
	return cannon
