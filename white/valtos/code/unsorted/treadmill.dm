#define BASE_MOVE_DELAY	8
#define MAX_SPEED		2

/obj/machinery/power/treadmill
	icon = 'icons/obj/recycling.dmi'
	icon_state = "conveyor0"
	name = "беговая дорожка"
	desc = "Генерирует энергию при беге по ней."
	layer = 2.2
	anchored = 1
	use_power = 0

	var/speed = 0
	var/friction = 0.15		// lose this much speed every ptick
	var/inertia = 1			// multiplier to mob speed, when increasing treadmill speed
	var/throw_dist = 2		// distance to throw the person, worst case
	var/power_gen = 80000	// amount of power output at max speed
	var/list/mobs_running[0]
	var/id = null			// for linking to monitor

/obj/machinery/power/treadmill/Initialize()
	. = ..()
	if(anchored)
		connect_to_network()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_EXITED = PROC_REF(on_exited),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/machinery/power/treadmill/update_icon()
	icon_state = speed ? "conveyor1" : "conveyor0"

/obj/machinery/power/treadmill/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(anchored && !H.anchored)
			if(!istype(H) || H.dir != dir)
				throw_off(H)
			else
				mobs_running[H] = H?.client?.move_delay

/obj/machinery/power/treadmill/proc/on_exited(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(anchored && istype(H))
			mobs_running -= H

/obj/machinery/power/treadmill/proc/throw_off(atom/movable/A)
	// if 2fast, throw the person, otherwise they just slide off, if there's reasonable speed at all
	if(speed)
		var/dist = max(throw_dist * speed / MAX_SPEED, 1)
		A.throw_at(get_distant_turf(get_turf(src), REVERSE_DIR(dir), dist), A.throw_range, A.throw_speed)

/obj/machinery/power/treadmill/process()
	if(!anchored)
		speed = 0
		update_icon()
		return

	speed = clamp(speed - friction, 0, MAX_SPEED)
	for(var/A in (loc.contents - src))
		var/atom/movable/AM = A
		if(AM.anchored)
			continue
		if(istype(A, /mob/living))
			var/mob/living/M = A
			var/last_move
			// get/update old step count
			if(mobs_running[M])
				last_move = mobs_running[M]
			else
				last_move = M?.client?.move_delay
			mobs_running[M] = M?.client?.move_delay
			// if we "stepped" in right direction, add to speed, else throw the person off like a common obj
			if(last_move != M?.client?.move_delay && dir == M.dir)
				// a reasonable approximation of movement speed
				var/mob_speed = M.total_multiplicative_slowdown()
				switch(M.m_intent)
					if(MOVE_INTENT_RUN)
						if(M.drowsyness > 0)
							mob_speed += 6
						mob_speed += 3
					if(MOVE_INTENT_WALK)
						mob_speed += 1
				mob_speed = BASE_MOVE_DELAY / max(1, BASE_MOVE_DELAY + mob_speed)
				speed = min(speed + inertia * mob_speed, mob_speed)
				continue
		throw_off(A)

	var/output = get_power_output()
	if(output)
		add_avail(output)
	update_icon()

/obj/machinery/power/treadmill/proc/get_power_output()
	if(speed && !machine_stat && anchored && powernet)
		return power_gen * speed / MAX_SPEED
	return 0

/obj/machinery/power/treadmill/emp_act(severity)
	..()
	if(!(machine_stat & BROKEN))
		machine_stat |= BROKEN
		spawn(100)
			machine_stat &= ~BROKEN

/obj/machinery/power/treadmill/attackby(obj/item/W, mob/user)
	if(default_unfasten_wrench(user, W, time = 60))
		if(anchored)
			connect_to_network()
		else
			disconnect_from_network()
		speed = 0
		update_icon()
		return
	..()

#undef BASE_MOVE_DELAY
#undef MAX_SPEED

#define CHARS_PER_LINE 5
#define FONT_SIZE "5pt"
#define FONT_STYLE "Small Fonts"

/obj/machinery/treadmill_monitor
	name = "монитор беговой дорожки"
	icon = 'icons/obj/status_display.dmi'
	icon_state = "frame"
	desc = "Да..."
	anchored = 1
	density = 0
	maptext_height = 26
	maptext_width = 32

	var/on = 0					// if we should be metering or not
	var/id = null				// id of treadmill
	var/obj/machinery/power/treadmill/treadmill = null
	var/total_joules = 0		// total power from prisoner
	var/J_per_ticket = 450000	// amt of power charged for a ticket
	var/line1 = ""
	var/line2 = ""
	var/frame = 0				// on 0, show labels, on 1 show numbers
	var/redeem_immediately = TRUE// redeem immediately for holding cell

/obj/machinery/treadmill_monitor/Initialize()
	. = ..()
	if(id)
		for(var/obj/machinery/power/treadmill/T in GLOB.machines)
			if(T.id == id)
				treadmill = T
				break
	if(!treadmill)
		// also simply check if treadmill at loc
		for(var/obj/machinery/power/treadmill/T in loc)
			treadmill = T
			break

/obj/machinery/treadmill_monitor/process()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(treadmill && on)
		var/output = treadmill.get_power_output()
		if(output)
			total_joules += output
		if(redeem_immediately && total_joules > J_per_ticket)
			redeem()
			total_joules = 1
	update_icon()
	frame = !frame

/obj/machinery/treadmill_monitor/power_change()
	..()
	update_icon()

/obj/machinery/treadmill_monitor/examine(mob/user)
	. = ..()
	. += "<hr>Дисплей:<div style='text-align: center'>[line1]<br>[line2]</div>"

/obj/machinery/treadmill_monitor/update_icon()
	overlays.Cut()
	if(machine_stat & NOPOWER || !total_joules || !on)
		line1 = ""
		line2 = ""
	else if(machine_stat & BROKEN)
		overlays += image('icons/obj/status_display.dmi', icon_state = "ai_bsod")
		line1 = "A@#$A"
		line2 = "729%!"
	else
		if(!frame)
			line1 = "-В/С-"
			line2 = "-ТИК-"
		else
			if(!treadmill || treadmill.machine_stat)
				line1 = "???"
			else
				line1 = "[add_zero(num2text(round(treadmill.get_power_output())), 4)]"
			if(length(line1) > CHARS_PER_LINE)
				line1 = "Ошибка"
			if(J_per_ticket)
				line2 = "[round(total_joules / J_per_ticket)]"
			if(length(line2) > CHARS_PER_LINE)
				line2 = "Ошибка"
	update_display(line1, line2)

//Checks to see if there's 1 line or 2, adds text-icons-numbers/letters over display
// Stolen from status_display
/obj/machinery/treadmill_monitor/proc/update_display(var/line1, var/line2)
	var/new_text = {"<div style="font-size:[FONT_SIZE];color:[GLOB.display_font_color];font:'[FONT_STYLE]';text-align:center;" valign="top">[line1]<br>[line2]</div>"}
	if(maptext != new_text)
		maptext = new_text

// called by brig timer when prisoner released
/obj/machinery/treadmill_monitor/proc/redeem()
	if(total_joules >= J_per_ticket && J_per_ticket)
		playsound(loc, 'sound/machines/chime.ogg', 50, 1)
		new /obj/item/stack/spacecash/c50(get_turf(src), round(total_joules / J_per_ticket))
		total_joules = 0

/obj/machinery/treadmill_monitor/emp_act(severity)
	..()
	if(!(machine_stat & BROKEN))
		machine_stat |= BROKEN
		update_icon()
		spawn(100)
			machine_stat &= ~BROKEN
			update_icon()

#undef FONT_SIZE
#undef FONT_STYLE
#undef CHARS_PER_LINE
