/datum/wires/autolathe
	holder_type = /obj/machinery/autolathe
	proper_name = "Autolathe"

/datum/wires/autolathe/New(atom/holder)
	wires = list(
		WIRE_HACK, WIRE_DISABLE,
		WIRE_SHOCK, WIRE_ZAP
	)
	add_duds(6)
	..()

/datum/wires/autolathe/interactable(mob/user)
	var/obj/machinery/autolathe/A = holder
	if(A.panel_open)
		return TRUE

/datum/wires/autolathe/get_status()
	var/obj/machinery/autolathe/A = holder
	var/list/status = list()
	status += "Красный индикатор [A.disabled ? "горит" : "не горит"]."
	status += "Синий индикатор [A.hacked ? "горит" : "не горит"]."
	return status

/datum/wires/autolathe/on_pulse(wire)
	var/obj/machinery/autolathe/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!A.hacked)
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/autolathe, reset), wire), 60)
		if(WIRE_SHOCK)
			A.shocked = !A.shocked
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/autolathe, reset), wire), 60)
		if(WIRE_DISABLE)
			A.disabled = !A.disabled
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/autolathe, reset), wire), 60)

/datum/wires/autolathe/on_cut(wire, mend)
	var/obj/machinery/autolathe/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!mend)
		if(WIRE_HACK)
			A.shocked = !mend
		if(WIRE_DISABLE)
			A.disabled = !mend
		if(WIRE_ZAP)
			A.shock(usr, 50)
