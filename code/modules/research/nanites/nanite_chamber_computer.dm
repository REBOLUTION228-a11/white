/obj/machinery/computer/nanite_chamber_control
	name = "консоль управления нанитной камерой"
	desc = "Управляет нанитной камерой. Может имплантировать наниты, задавать текущее программное облако и анализировать существующие нанитные программы."
	var/obj/machinery/nanite_chamber/chamber
	icon_screen = "nanite_chamber_control"
	circuit = /obj/item/circuitboard/computer/nanite_chamber_control

/obj/machinery/computer/nanite_chamber_control/Initialize()
	. = ..()
	find_chamber()

/obj/machinery/computer/nanite_chamber_control/proc/find_chamber()
	for(var/direction in GLOB.cardinals)
		var/C = locate(/obj/machinery/nanite_chamber, get_step(src, direction))
		if(C)
			var/obj/machinery/nanite_chamber/NC = C
			set_connected_chamber(NC)

/obj/machinery/computer/nanite_chamber_control/interact()
	if(!chamber)
		find_chamber()
	..()

/obj/machinery/computer/nanite_chamber_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NaniteChamberControl", name)
		ui.open()

/obj/machinery/computer/nanite_chamber_control/ui_data()
	var/list/data = list()

	if(!chamber)
		data["status_msg"] = "Не обнаружена камера."
		return data

	if(!chamber.occupant)
		data["status_msg"] = "Внутри никого нет."
		return data

	var/mob/living/L = chamber.occupant

	if(!(L.mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		data["status_msg"] = "Пациент не подходит."
		return data

	if(chamber.busy)
		data["status_msg"] = chamber.busy_message
		return data

	data["status_msg"] = null
	data["scan_level"] = chamber.scan_level
	data["locked"] = chamber.locked
	data["occupant_name"] = chamber.occupant.name

	SEND_SIGNAL(L, COMSIG_NANITE_UI_DATA, data, chamber.scan_level)

	return data

/obj/machinery/computer/nanite_chamber_control/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle_lock")
			chamber.locked = !chamber.locked
			chamber.update_icon()
			. = TRUE
		if("set_safety")
			var/threshold = text2num(params["value"])
			if(!isnull(threshold))
				chamber.set_safety(clamp(round(threshold, 1),0,500))
				playsound(src, "terminal_type", 25, FALSE)
				chamber.occupant.investigate_log("'s nanites' safety threshold was set to [threshold] by [key_name(usr)] via [src] at [AREACOORD(src)].", INVESTIGATE_NANITES)
			. = TRUE
		if("set_cloud")
			var/cloud_id = text2num(params["value"])
			if(!isnull(cloud_id))
				chamber.set_cloud(clamp(round(cloud_id, 1),0,100))
				playsound(src, "terminal_type", 25, FALSE)
				chamber.occupant.investigate_log("'s nanites' cloud id was set to [cloud_id] by [key_name(usr)] via [src] at [AREACOORD(src)].", INVESTIGATE_NANITES)
			. = TRUE
		if("connect_chamber")
			find_chamber()
			. = TRUE
		if("remove_nanites")
			playsound(src, 'sound/machines/terminal_prompt.ogg', 25, FALSE)
			chamber.remove_nanites()
			log_combat(usr, chamber.occupant, "cleared nanites from", null, "via [src]")
			chamber.occupant.investigate_log("'s nanites were cleared by [key_name(usr)] via [src] at [AREACOORD(src)].", INVESTIGATE_NANITES)
			. = TRUE
		if("nanite_injection")
			playsound(src, 'sound/machines/terminal_prompt.ogg', 25, FALSE)
			chamber.inject_nanites()
			log_combat(usr, chamber.occupant, "injected", null, "with nanites via [src]")
			chamber.occupant.investigate_log("was injected with nanites by [key_name(usr)] via [src] at [AREACOORD(src)].", INVESTIGATE_NANITES)
			. = TRUE

/obj/machinery/computer/nanite_chamber_control/proc/set_connected_chamber(new_chamber)
	if(chamber)
		UnregisterSignal(chamber, COMSIG_PARENT_QDELETING)
	chamber = new_chamber
	if(chamber)
		RegisterSignal(chamber, COMSIG_PARENT_QDELETING, PROC_REF(react_to_chamber_del))

/obj/machinery/computer/nanite_chamber_control/proc/react_to_chamber_del(datum/source)
	SIGNAL_HANDLER
	set_connected_chamber(null)
