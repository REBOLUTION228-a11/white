/obj/item/electronics/firealarm
	name = "электроника пожарной сигнализации"
	desc = "Схема пожарной сигнализации. Может выдерживать температуру до 40 градусов по Цельсию."

/obj/item/wallframe/firealarm
	name = "рамка пожарной сигнализации"
	desc = "Используется для создания пожарной сигнализации."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire_bitem"
	result_path = /obj/machinery/firealarm
	pixel_shift = 26

/obj/machinery/firealarm
	name = "пожарная тревога"
	desc = "<i>\"Потяните в случае чрезвычайной ситуации\"</i>. То есть тяните его постоянно."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	max_integrity = 250
	integrity_failure = 0.4
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 90, ACID = 30)
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = AREA_USAGE_ENVIRON
	resistance_flags = FIRE_PROOF

	light_power = 0
	light_range = 7
	light_color = COLOR_VIVID_RED

	//Trick to get the glowing overlay visible from a distance
	luminosity = 1
	///Buildstate for contruction steps. 2 = complete, 1 = no wires, 0 = circuit gone
	var/buildstage = 2
	///Our home area, set in Init. Due to loading step order, this seems to be null very early in the server setup process, which is why some procs use `my_area?` for var or list checks.
	var/area/my_area = null
	///looping sound datum for our fire alarm siren.
	var/datum/looping_sound/firealarm/soundloop

/obj/machinery/firealarm/Initialize(mapload, dir, building)
	. = ..()
	if(building)
		buildstage = 0
		panel_open = TRUE
	if(name == initial(name))
		name = "[get_area_name(src)] [initial(name)]"
	update_appearance()
	my_area = get_area(src)
	LAZYADD(my_area.firealarms, src)

	AddElement(/datum/element/atmos_sensitive, mapload)
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(check_security_level))
	soundloop = new(src, FALSE)

	AddComponent(/datum/component/usb_port, list(
		/obj/item/circuit_component/firealarm,
	))

/obj/machinery/firealarm/Destroy()
	if(my_area)
		LAZYREMOVE(my_area.firealarms, src)
		my_area = null
	QDEL_NULL(soundloop)
	return ..()

/**
 * Sets the sound state, and then calls update_icon()
 *
 * This proc exists to be called by areas and firelocks
 * so that it may update its icon and start or stop playing
 * the alarm sound based on the state of an area variable.
 */
/obj/machinery/firealarm/proc/set_status()
	if( (my_area.fire || LAZYLEN(my_area.active_firelocks)) && !(obj_flags & EMAGGED) )
		set_light(l_power = 0.8)
	else
		soundloop.stop()
		set_light(l_power = 0)
	update_icon()

/obj/machinery/firealarm/update_icon_state()
	if(panel_open)
		icon_state = "fire_b[buildstage]"
		return ..()
	if(machine_stat & BROKEN)
		icon_state = "firex"
		return ..()
	icon_state = "fire0"
	return ..()

/obj/machinery/firealarm/update_overlays()
	. = ..()
	if(machine_stat & NOPOWER)
		return

	. += "fire_overlay"
	if(is_station_level(z))
		. += "fire_[SSsecurity_level.current_level]"
		. += mutable_appearance(icon, "fire_[SSsecurity_level.current_level]")
		. += emissive_appearance(icon, "fire_[SSsecurity_level.current_level]", alpha = src.alpha)
	else
		. += "fire_[SEC_LEVEL_GREEN]"
		. += mutable_appearance(icon, "fire_[SEC_LEVEL_GREEN]")
		. += emissive_appearance(icon, "fire_[SEC_LEVEL_GREEN]", alpha = src.alpha)

	if(!(my_area?.fire || LAZYLEN(my_area?.active_firelocks)))
		if(my_area?.fire_detect) //If this is false, leave the green light missing. A good hint to anyone paying attention.
			. += "fire_off"
			. += mutable_appearance(icon, "fire_off")
			. += emissive_appearance(icon, "fire_off", alpha = src.alpha)
	else if(obj_flags & EMAGGED)
		. += "fire_emagged"
		. += mutable_appearance(icon, "fire_emagged")
		. += emissive_appearance(icon, "fire_emagged", alpha = src.alpha)
	else
		. += "fire_on"
		. += mutable_appearance(icon, "fire_on")
		. += emissive_appearance(icon, "fire_on", alpha = src.alpha)

	if(!panel_open && my_area?.fire_detect && my_area?.fire) //It just looks horrible with the panel open
		. += "fire_detected"
		. += mutable_appearance(icon, "fire_detected")
		. += emissive_appearance(icon, "fire_detected", alpha = src.alpha) //Pain

/obj/machinery/firealarm/emp_act(severity)
	. = ..()

	if (. & EMP_PROTECT_SELF)
		return

	if(prob(50 / severity))
		alarm()

/obj/machinery/firealarm/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	update_appearance()
	if(user)
		user.visible_message(span_warning("Искры вылетают из [src]!"),
							span_notice("Ломаю [src], отключая динамик."))
	playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	set_status()

/**
 * Signal handler for checking if we should update fire alarm appearance accordingly to a newly set security level
 *
 * Arguments:
 * * source The datum source of the signal
 * * new_level The new security level that is in effect
 */
/obj/machinery/firealarm/proc/check_security_level(datum/source, new_level)
	SIGNAL_HANDLER

	if(is_station_level(z))
		update_appearance()

/**
 * Sounds the fire alarm and closes all firelocks in the area. Also tells the area to color the lights red.
 *
 * Arguments:
 * * mob/user is the user that pulled the alarm.
 */
/obj/machinery/firealarm/proc/alarm(mob/user)
	if(!is_operational)
		return

	if(my_area.fire)
		return //area alarm already active
	my_area.alarm_manager.send_alarm(ALARM_FIRE, my_area)
	my_area.set_fire_alarm_effect()
	for(var/obj/machinery/door/firedoor/firelock in my_area.firedoors)
		firelock.activate(FIRELOCK_ALARM_TYPE_GENERIC)
	if(user)
		log_game("[user] triggered a fire alarm at [COORD(src)]")
	soundloop.start() //Manually pulled fire alarms will make the sound, rather than the doors.
	SEND_SIGNAL(src, COMSIG_FIREALARM_ON_TRIGGER)

/**
 * Resets all firelocks in the area. Also tells the area to disable alarm lighting, if it was enabled.
 *
 * Arguments:
 * * mob/user is the user that reset the alarm.
 */
/obj/machinery/firealarm/proc/reset(mob/user)
	if(!is_operational)
		return
	my_area.unset_fire_alarm_effects()
	for(var/obj/machinery/door/firedoor/firelock in my_area.firedoors)
		firelock.reset()
	my_area.alarm_manager.clear_alarm(ALARM_FIRE, my_area)
	if(user)
		log_game("[user] reset a fire alarm at [COORD(src)]")
	soundloop.stop()
	SEND_SIGNAL(src, COMSIG_FIREALARM_ON_RESET)

/obj/machinery/firealarm/attack_hand(mob/user, list/modifiers)
	if(buildstage != 2)
		return
	. = ..()
	add_fingerprint(user)
	alarm(user)

/obj/machinery/firealarm/attack_hand_secondary(mob/user, list/modifiers)
	if(buildstage != 2)
		return ..()
	add_fingerprint(user)
	reset(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/firealarm/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attack_ai_secondary(mob/user)
	return attack_hand_secondary(user)

/obj/machinery/firealarm/attack_robot(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attack_robot_secondary(mob/user)
	return attack_hand_secondary(user)

/obj/machinery/firealarm/attackby(obj/item/tool, mob/living/user, params)
	add_fingerprint(user)

	if(tool.tool_behaviour == TOOL_SCREWDRIVER && buildstage == 2)
		tool.play_tool_sound(src)
		panel_open = !panel_open
		to_chat(user, span_notice("Провода теперь [panel_open ? "видно" : "скрыты"]."))
		update_appearance()
		return

	if(panel_open)

		if(tool.tool_behaviour == TOOL_WELDER && !user.a_intent == INTENT_HARM)
			if(obj_integrity < max_integrity)
				if(!tool.tool_start_check(user, amount=0))
					return

				to_chat(user, span_notice("Начинаю чинить [src]..."))
				if(tool.use_tool(src, user, 40, volume=50))
					obj_integrity = max_integrity
					to_chat(user, span_notice("Чиню [src]."))
			else
				to_chat(user, span_warning("[src] уже целая!"))
			return

		switch(buildstage)
			if(2)
				if(tool.tool_behaviour == TOOL_WIRECUTTER)
					buildstage = 1
					tool.play_tool_sound(src)
					new /obj/item/stack/cable_coil(user.loc, 5)
					to_chat(user, span_notice("Снимаю проводку [src]."))
					update_appearance()
					return

				else if(tool.force) //hit and turn it on
					..()
					var/area/area = get_area(src)
					if(!area.fire)
						alarm()
					return

			if(1)
				if(istype(tool, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/coil = tool
					if(coil.get_amount() < 5)
						to_chat(user, span_warning("Мне потребуется больше проводов!"))
					else
						coil.use(5)
						buildstage = 2
						to_chat(user, span_notice("Делаю проводку [src]."))
						update_appearance()
					return

				else if(tool.tool_behaviour == TOOL_CROWBAR)
					user.visible_message(span_notice("[user.name] удаляет электронику из [src.name]."), \
										span_notice("Начинаю вытаскивать плату..."))
					if(tool.use_tool(src, user, 20, volume=50))
						if(buildstage == 1)
							if(machine_stat & BROKEN)
								to_chat(user, span_notice("Удаляю разрушенную плату."))
								set_machine_stat(machine_stat & ~BROKEN)
							else
								to_chat(user, span_notice("Вытаскиваю плату."))
								new /obj/item/electronics/firealarm(user.loc)
							buildstage = 0
							update_appearance()
					return
			if(0)
				if(istype(tool, /obj/item/electronics/firealarm))
					to_chat(user, span_notice("Вставляю плату."))
					qdel(tool)
					buildstage = 1
					update_appearance()
					return

				else if(istype(tool, /obj/item/electroadaptive_pseudocircuit))
					var/obj/item/electroadaptive_pseudocircuit/pseudoc = tool
					if(!pseudoc.adapt_circuit(user, 15))
						return
					user.visible_message(span_notice("[user] создаёт специальную плату и вставляет в [src]."), \
					span_notice("Создаю специальную плату и вставляю."))
					buildstage = 1
					update_appearance()
					return

				else if(tool.tool_behaviour == TOOL_WRENCH)
					user.visible_message(span_notice("[user] снимает пожарную тревогу со стены."), \
						span_notice("Снимаю пожарную тревогу со стены."))
					var/obj/item/wallframe/firealarm/frame = new /obj/item/wallframe/firealarm()
					frame.forceMove(user.drop_location())
					tool.play_tool_sound(src)
					qdel(src)
					return
	return ..()

/obj/machinery/firealarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/firealarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] создаёт специальную плату и вставляет в [src]."), \
			span_notice("Создаю специальную плату и вставляю."))
			buildstage = 1
			update_appearance()
			return TRUE
	return FALSE

/obj/machinery/firealarm/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(.) //damage received
		if(obj_integrity > 0 && !(machine_stat & BROKEN) && buildstage != 0)
			if(prob(33))
				alarm()

/obj/machinery/firealarm/singularity_pull(S, current_size)
	if (current_size >= STAGE_FIVE) // If the singulo is strong enough to pull anchored objects, the fire alarm experiences integrity failure
		deconstruct()
	return ..()

/obj/machinery/firealarm/obj_break(damage_flag)
	if(buildstage == 0) //can't break the electronics if there isn't any inside.
		return
	return ..()

/obj/machinery/firealarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/iron(loc, 1)
		if(!(machine_stat & BROKEN))
			var/obj/item/item = new /obj/item/electronics/firealarm(loc)
			if(!disassembled)
				item.update_integrity(item.max_integrity * 0.5)
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

// Allows users to examine the state of the thermal sensor
/obj/machinery/firealarm/examine(mob/user)
	. = ..()
	if((my_area?.fire || LAZYLEN(my_area?.active_firelocks)))
		. += "<hr>Лампочка горит."
		. += "\n<b>ЛКМ</b> для активации всех пожарных шлюзов."
		. += "\n<b>ПКМ</b> для деактивации всех пожарных шлюзов."
	else
		. += "<hr>Температурный датчик [my_area.fire_detect ? "горит" : "не горит"]."
		. += "\n<b>ЛКМ</b> для активации всех пожарных шлюзов."

// Allows Silicons to disable thermal sensor
/obj/machinery/firealarm/BorgCtrlClick(mob/living/silicon/robot/user)
	if(get_dist(src,user) <= user.interaction_range)
		AICtrlClick(user)
		return
	return ..()

/obj/machinery/firealarm/AICtrlClick(mob/living/silicon/robot/user)
	if(obj_flags & EMAGGED)
		to_chat(user, span_warning("Плата внутри [src] не отвечает."))
		return
	my_area.fire_detect = !my_area.fire_detect
	for(var/obj/machinery/firealarm/fire_panel in my_area.firealarms)
		fire_panel.update_icon()
	to_chat(user, span_notice("[ my_area.fire_detect ? "Включаю" : "Выключаю" ] термальные датчики!"))
	log_game("[user] has [ my_area.fire_detect ? "enabled" : "disabled" ] firelock sensors using [src] at [COORD(src)]")

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/firealarm, 26)

/*
 * Return of Party button
 */

/area
	var/party = FALSE

/obj/machinery/firealarm/partyalarm
	name = "ПАТИ"
	desc = "Ruzone went up!"
	var/static/party_overlay

/obj/machinery/firealarm/partyalarm/reset()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/area = get_area(src)
	if (!area || !area.party)
		return
	area.party = FALSE
	area.cut_overlay(party_overlay)

/obj/machinery/firealarm/partyalarm/alarm()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/area = get_area(src)
	if (!area || area.party || area.name == "Космос")
		return
	area.party = TRUE
	if (!party_overlay)
		party_overlay = iconstate2appearance('icons/turf/areas.dmi', "party")
	area.add_overlay(party_overlay)

/obj/item/circuit_component/firealarm
	display_name = "Пожарная тревога"
	desc = "Позволяет работать с пожарной тревогой."

	var/datum/port/input/alarm_trigger
	var/datum/port/input/reset_trigger

	/// Returns a boolean value of 0 or 1 if the fire alarm is on or not.
	var/datum/port/output/is_on
	/// Returns when the alarm is turned on
	var/datum/port/output/triggered
	/// Returns when the alarm is turned off
	var/datum/port/output/reset

	var/obj/machinery/firealarm/attached_alarm

/obj/item/circuit_component/firealarm/populate_ports()
	alarm_trigger = add_input_port("Установить", PORT_TYPE_SIGNAL)
	reset_trigger = add_input_port("Сбросить", PORT_TYPE_SIGNAL)

	is_on = add_output_port("Включена", PORT_TYPE_NUMBER)
	triggered = add_output_port("Триггер", PORT_TYPE_SIGNAL)
	reset = add_output_port("Сброс", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/firealarm/register_usb_parent(atom/movable/parent)
	. = ..()
	if(istype(parent, /obj/machinery/firealarm))
		attached_alarm = parent
		RegisterSignal(parent, COMSIG_FIREALARM_ON_TRIGGER, PROC_REF(on_firealarm_triggered))
		RegisterSignal(parent, COMSIG_FIREALARM_ON_RESET, PROC_REF(on_firealarm_reset))

/obj/item/circuit_component/firealarm/unregister_usb_parent(atom/movable/parent)
	attached_alarm = null
	UnregisterSignal(parent, COMSIG_FIREALARM_ON_TRIGGER)
	UnregisterSignal(parent, COMSIG_FIREALARM_ON_RESET)
	return ..()

/obj/item/circuit_component/firealarm/proc/on_firealarm_triggered(datum/source)
	SIGNAL_HANDLER
	is_on.set_output(1)
	triggered.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/firealarm/proc/on_firealarm_reset(datum/source)
	SIGNAL_HANDLER
	is_on.set_output(0)
	reset.set_output(COMPONENT_SIGNAL)


/obj/item/circuit_component/firealarm/input_received(datum/port/input/port)
	if(COMPONENT_TRIGGERED_BY(alarm_trigger, port))
		attached_alarm?.alarm()

	if(COMPONENT_TRIGGERED_BY(reset_trigger, port))
		attached_alarm?.reset()
