/datum/wires/airalarm
	holder_type = /obj/machinery/airalarm
	proper_name = "Air Alarm"

/datum/wires/airalarm/New(atom/holder)
	wires = list(
		WIRE_POWER,
		WIRE_IDSCAN, WIRE_AI,
		WIRE_PANIC, WIRE_ALARM
	)
	add_duds(3)
	..()

/datum/wires/airalarm/interactable(mob/user)
	var/obj/machinery/airalarm/A = holder
	if(A.panel_open && A.buildstage == 2)
		return TRUE

/datum/wires/airalarm/get_status()
	var/obj/machinery/airalarm/A = holder
	var/list/status = list()
	status += "Индикатор блокировки [A.locked ? "красный" : "зелёный"]."
	status += "Индикатор питания [A.shorted ? "горит" : "не горит"]."
	status += "Индикатор соединения с ИИ [!A.aidisabled ? "горит" : "не горит"]."
	return status

/datum/wires/airalarm/on_pulse(wire)
	var/obj/machinery/airalarm/A = holder
	switch(wire)
		if(WIRE_POWER) // Short out for a long time.
			if(!A.shorted)
				A.shorted = TRUE
				A.update_icon()
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/airalarm, reset), wire), 1200)
		if(WIRE_IDSCAN) // Toggle lock.
			A.locked = !A.locked
		if(WIRE_AI) // Disable AI control for a while.
			if(!A.aidisabled)
				A.aidisabled = TRUE
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/airalarm, reset), wire), 100)
		if(WIRE_PANIC) // Toggle panic siphon.
			if(!A.shorted)
				if(A.mode == 1) // AALARM_MODE_SCRUB
					A.mode = 3 // AALARM_MODE_PANIC
				else
					A.mode = 1 // AALARM_MODE_SCRUB
				A.apply_mode(usr)
		if(WIRE_ALARM) // Clear alarms.
			if(A.alarm_manager.clear_alarm(ALARM_ATMOS))
				A.post_alert(0)
			A.update_icon()

/datum/wires/airalarm/on_cut(wire, mend)
	var/obj/machinery/airalarm/A = holder
	switch(wire)
		if(WIRE_POWER) // Short out forever.
			A.shock(usr, 50)
			A.shorted = !mend
			A.update_icon()
		if(WIRE_IDSCAN)
			if(!mend)
				A.locked = TRUE
		if(WIRE_AI)
			A.aidisabled = mend // Enable/disable AI control.
		if(WIRE_PANIC) // Force panic syphon on.
			if(!mend && !A.shorted)
				A.mode = 3 // AALARM_MODE_PANIC
				A.apply_mode(usr)
		if(WIRE_ALARM) // Post alarm.
			if(A.alarm_manager.send_alarm(ALARM_ATMOS))
				A.post_alert(2)
			A.update_icon()
