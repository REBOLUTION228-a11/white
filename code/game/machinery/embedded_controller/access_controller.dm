#define CLOSING			1
#define OPENING			2
#define CYCLE			3
#define CYCLE_EXTERIOR	4
#define CYCLE_INTERIOR	5

/obj/machinery/door_buttons
	power_channel = AREA_USAGE_ENVIRON
	use_power = IDLE_POWER_USE
	idle_power_usage = 200
	active_power_usage = 400
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/idSelf

/obj/machinery/door_buttons/attackby(obj/O, mob/user)
	return attack_hand(user)

/obj/machinery/door_buttons/proc/findObjsByTag()
	return

/obj/machinery/door_buttons/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door_buttons/LateInitialize()
	findObjsByTag()

/obj/machinery/door_buttons/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	req_access = list()
	req_one_access = list()
	playsound(src, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	to_chat(user, span_warning("You short out the access controller."))

/obj/machinery/door_buttons/proc/removeMe()


/obj/machinery/door_buttons/access_button
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "access_button_standby"
	name = "access button"
	desc = "A button used for the explicit purpose of opening an airlock."
	var/idDoor
	var/obj/machinery/door/airlock/door
	var/obj/machinery/door_buttons/airlock_controller/controller
	var/busy

/obj/machinery/door_buttons/access_button/findObjsByTag()
	for(var/obj/machinery/door_buttons/airlock_controller/A in GLOB.machines)
		if(A.idSelf == idSelf)
			controller = A
			break
	for(var/obj/machinery/door/airlock/I in GLOB.machines)
		if(I.id_tag == idDoor)
			door = I
			break

/obj/machinery/door_buttons/access_button/interact(mob/user)
	if(busy)
		return
	if(!allowed(user))
		to_chat(user, span_warning("Доступ запрещён."))
		return
	if(controller && !controller.busy && door)
		if(controller.machine_stat & NOPOWER)
			return
		busy = TRUE
		update_icon()
		if(door.density)
			if(!controller.exteriorAirlock || !controller.interiorAirlock)
				controller.onlyOpen(door)
			else
				if(controller.exteriorAirlock.density && controller.interiorAirlock.density)
					controller.onlyOpen(door)
				else
					controller.cycleClose(door)
		else
			controller.onlyClose(door)
		addtimer(CALLBACK(src, PROC_REF(not_busy)), 2 SECONDS)

/obj/machinery/door_buttons/access_button/proc/not_busy()
	busy = FALSE
	update_icon()

/obj/machinery/door_buttons/access_button/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "access_button_off"
	else
		if(busy)
			icon_state = "access_button_cycle"
		else
			icon_state = "access_button_standby"

/obj/machinery/door_buttons/access_button/removeMe(obj/O)
	if(O == door)
		door = null



/obj/machinery/door_buttons/airlock_controller
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "access_control_standby"
	name = "access console"
	desc = "A small console that can cycle opening between two airlocks."
	var/obj/machinery/door/airlock/interiorAirlock
	var/obj/machinery/door/airlock/exteriorAirlock
	var/idInterior
	var/idExterior
	var/busy
	var/lostPower

/obj/machinery/door_buttons/airlock_controller/removeMe(obj/O)
	if(O == interiorAirlock)
		interiorAirlock = null
	else if(O == exteriorAirlock)
		exteriorAirlock = null

/obj/machinery/door_buttons/airlock_controller/Destroy()
	for(var/obj/machinery/door_buttons/access_button/A in GLOB.machines)
		if(A.controller == src)
			A.controller = null
	return ..()

/obj/machinery/door_buttons/airlock_controller/Topic(href, href_list)
	if(..())
		return
	if(busy)
		return
	if(!allowed(usr))
		to_chat(usr, span_warning("Доступ запрещён."))
		return
	switch(href_list["command"])
		if("close_exterior")
			onlyClose(exteriorAirlock)
		if("close_interior")
			onlyClose(interiorAirlock)
		if("cycle_exterior")
			cycleClose(exteriorAirlock)
		if("cycle_interior")
			cycleClose(interiorAirlock)
		if("open_exterior")
			onlyOpen(exteriorAirlock)
		if("open_interior")
			onlyOpen(interiorAirlock)

/obj/machinery/door_buttons/airlock_controller/proc/onlyOpen(obj/machinery/door/airlock/A)
	if(A)
		busy = CLOSING
		update_icon()
		openDoor(A)

/obj/machinery/door_buttons/airlock_controller/proc/onlyClose(obj/machinery/door/airlock/A)
	if(A)
		busy = CLOSING
		closeDoor(A)

/obj/machinery/door_buttons/airlock_controller/proc/closeDoor(obj/machinery/door/airlock/A)
	if(A.density)
		goIdle()
		return FALSE
	update_icon()
	A.safe = FALSE //Door crushies, manual door after all. Set every time in case someone changed it, safe doors can end up waiting forever.
	A.unbolt()
	if(A.close())
		if(machine_stat & NOPOWER || lostPower || !A || QDELETED(A))
			goIdle(TRUE)
			return FALSE
		A.bolt()
		goIdle(TRUE)
		return TRUE
	goIdle(TRUE)
	return FALSE

/obj/machinery/door_buttons/airlock_controller/proc/cycleClose(obj/machinery/door/airlock/A)
	if(!A || !exteriorAirlock || !interiorAirlock)
		return
	if(exteriorAirlock.density == interiorAirlock.density || !A.density)
		return
	busy = CYCLE
	update_icon()
	if(A == interiorAirlock)
		if(closeDoor(exteriorAirlock))
			busy = CYCLE_INTERIOR
	else
		if(closeDoor(interiorAirlock))
			busy = CYCLE_EXTERIOR

/obj/machinery/door_buttons/airlock_controller/proc/cycleOpen(obj/machinery/door/airlock/A)
	if(!A)
		goIdle(TRUE)
	if(A == exteriorAirlock)
		if(interiorAirlock)
			if(!interiorAirlock.density || !interiorAirlock.locked)
				return
	else
		if(exteriorAirlock)
			if(!exteriorAirlock.density || !exteriorAirlock.locked)
				return
	if(busy != OPENING)
		busy = OPENING
		openDoor(A)

/obj/machinery/door_buttons/airlock_controller/proc/openDoor(obj/machinery/door/airlock/A)
	if(exteriorAirlock && interiorAirlock && (!exteriorAirlock.density || !interiorAirlock.density))
		goIdle(TRUE)
		return
	A.unbolt()
	INVOKE_ASYNC(src, PROC_REF(do_openDoor), A)

/obj/machinery/door_buttons/airlock_controller/proc/do_openDoor(obj/machinery/door/airlock/A)
	if(A?.open())
		if(machine_stat | (NOPOWER) && !lostPower && A && !QDELETED(A))
			A.bolt()
	goIdle(TRUE)

/obj/machinery/door_buttons/airlock_controller/proc/goIdle(update)
	lostPower = FALSE
	busy = FALSE
	if(update)
		update_icon()
	updateUsrDialog()

/obj/machinery/door_buttons/airlock_controller/process()
	if(machine_stat & NOPOWER)
		return
	if(busy == CYCLE_EXTERIOR)
		cycleOpen(exteriorAirlock)
	else if(busy == CYCLE_INTERIOR)
		cycleOpen(interiorAirlock)

/obj/machinery/door_buttons/airlock_controller/power_change()
	. = ..()
	if(machine_stat & NOPOWER)
		lostPower = TRUE
	else
		if(!busy)
			lostPower = FALSE

/obj/machinery/door_buttons/airlock_controller/findObjsByTag()
	for(var/obj/machinery/door/airlock/A in GLOB.machines)
		if(A.id_tag == idInterior)
			interiorAirlock = A
		else if(A.id_tag == idExterior)
			exteriorAirlock = A

/obj/machinery/door_buttons/airlock_controller/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "access_control_off"
		return
	if(busy || lostPower)
		icon_state = "access_control_process"
	else
		icon_state = "access_control_standby"

/obj/machinery/door_buttons/airlock_controller/ui_interact(mob/user)
	var/datum/browser/popup = new(user, "computer", name)
	popup.set_content(returnText())
	popup.open()

/obj/machinery/door_buttons/airlock_controller/proc/returnText()
	var/output
	if(!exteriorAirlock && !interiorAirlock)
		return "ERROR ERROR ERROR ERROR"
	if(lostPower)
		output = "Initializing..."
	else
		if(!exteriorAirlock || !interiorAirlock)
			if(!exteriorAirlock)
				if(interiorAirlock.density)
					output = "<A href='?src=[REF(src)];command=open_interior'>Open Interior Airlock</A><BR>"
				else
					output = "<A href='?src=[REF(src)];command=close_interior'>Close Interior Airlock</A><BR>"
			else
				if(exteriorAirlock.density)
					output = "<A href='?src=[REF(src)];command=open_exterior'>Open Exterior Airlock</A><BR>"
				else
					output = "<A href='?src=[REF(src)];command=close_exterior'>Close Exterior Airlock</A><BR>"
		else
			if(exteriorAirlock.density)
				if(interiorAirlock.density)
					output = {"<A href='?src=[REF(src)];command=open_exterior'>Open Exterior Airlock</A><BR>
					<A href='?src=[REF(src)];command=open_interior'>Open Interior Airlock</A><BR>"}
				else
					output = {"<A href='?src=[REF(src)];command=cycle_exterior'>Cycle to Exterior Airlock</A><BR>
					<A href='?src=[REF(src)];command=close_interior'>Close Interior Airlock</A><BR>"}
			else
				if(interiorAirlock.density)
					output = {"<A href='?src=[REF(src)];command=close_exterior'>Close Exterior Airlock</A><BR>
					<A href='?src=[REF(src)];command=cycle_interior'>Cycle to Interior Airlock</A><BR>"}
				else
					output = {"<A href='?src=[REF(src)];command=close_exterior'>Close Exterior Airlock</A><BR>
					<A href='?src=[REF(src)];command=close_interior'>Close Interior Airlock</A><BR>"}


	output = {"<B>Access Control Console</B><HR>
				[output]<HR>"}
	if(exteriorAirlock)
		output += "<B>Exterior Door: </B> [exteriorAirlock.density ? "closed" : "open"]<BR>"
	if(interiorAirlock)
		output += "<B>Interior Door: </B> [interiorAirlock.density ? "closed" : "open"]<BR>"

	return output

#undef CLOSING
#undef OPENING
#undef CYCLE
#undef CYCLE_EXTERIOR
#undef CYCLE_INTERIOR
