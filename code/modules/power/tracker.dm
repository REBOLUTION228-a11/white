#define TRACKER_Y_OFFSET 13
#define TRACKER_EDGE_Y_OFFSET (TRACKER_Y_OFFSET - 2)

//Solar tracker

//Machine that tracks the sun and reports its direction to the solar controllers
//As long as this is working, solar panels on same powernet will track automatically

/obj/machinery/power/tracker
	name = "Отслеживатель солнечных лучей"
	desc = "A solar directional tracker."
	icon = 'icons/obj/solar.dmi'
	icon_state = "tracker_base"
	density = TRUE
	use_power = NO_POWER_USE
	max_integrity = 250
	integrity_failure = 0.2

	var/id = 0
	var/obj/machinery/power/solar_control/control
	var/obj/effect/overlay/tracker_dish
	var/obj/effect/overlay/tracker_dish_edge
	var/azimuth_current

/obj/machinery/power/tracker/Initialize(mapload, obj/item/solar_assembly/S)
	. = ..()

	tracker_dish_edge = add_panel_overlay("tracker_edge", TRACKER_EDGE_Y_OFFSET)
	tracker_dish = add_panel_overlay("tracker", TRACKER_Y_OFFSET)

	Make(S)
	connect_to_network()
	RegisterSignal(SSsun, COMSIG_SUN_MOVED, PROC_REF(sun_update))

/obj/machinery/power/tracker/Destroy()
	unset_control() //remove from control computer
	return ..()

/obj/machinery/power/tracker/proc/add_panel_overlay(icon_state, y_offset)
	var/obj/effect/overlay/overlay = new()
	overlay.vis_flags = VIS_INHERIT_ID | VIS_INHERIT_ICON
	overlay.appearance_flags = TILE_BOUND
	overlay.icon_state = icon_state
	overlay.layer = FLY_LAYER
	overlay.plane = ABOVE_GAME_PLANE
	overlay.pixel_y = y_offset
	vis_contents += overlay
	return overlay

/obj/machinery/power/tracker/proc/set_control(obj/machinery/power/solar_control/SC)
	unset_control()
	control = SC
	SC.connected_tracker = src

//set the control of the tracker to null and removes it from the previous control computer if needed
/obj/machinery/power/tracker/proc/unset_control()
	if(control)
		if(control.track == SOLAR_TRACK_AUTO)
			control.track = SOLAR_TRACK_OFF
		control.connected_tracker = null
		control = null

/**
 * Get the 2.5D transform for the tracker, given an angle
 * Arguments:
 * * angle - the angle the panel is facing
 */
/obj/machinery/power/tracker/proc/get_tracker_transform(angle)
	// 2.5D solar tracker works by using a magic combination of transforms
	var/matrix/turner = matrix()
	// Rotate towards sun
	turner.Turn(angle)
	// Make it skinny on the floor plane
	turner.Scale(1, 0.5)

	return turner

/obj/machinery/power/tracker/proc/visually_turn_part(part, angle)
	var/mid_azimuth = (azimuth_current + angle) / 2

	// actually flip to other direction?
	if(abs(angle - azimuth_current) > 180)
		mid_azimuth = (mid_azimuth + 180) % 360

	// Split into 2 parts so it doesn't distort on large changes
	animate(part,
		transform = get_tracker_transform(mid_azimuth),
		time = 2.5 SECONDS, easing = CUBIC_EASING|EASE_IN
	)
	animate(
		transform = get_tracker_transform(angle),
		time = 2.5 SECONDS, easing = CUBIC_EASING|EASE_OUT
	)

///Tell the controller to turn the solar panels
/obj/machinery/power/tracker/proc/sun_update(datum/source, azimuth)
	SIGNAL_HANDLER

	visually_turn_part(tracker_dish, azimuth)
	visually_turn_part(tracker_dish_edge, azimuth)
	azimuth_current = azimuth

	if(control && control.track == SOLAR_TRACK_AUTO)
		control.set_panels(azimuth)

/obj/machinery/power/tracker/proc/Make(obj/item/solar_assembly/S)
	if(!S)
		S = new /obj/item/solar_assembly(src)
		S.glass_type = /obj/item/stack/sheet/glass
		S.tracker = 1
		S.update_appearance()
		S.set_anchored(TRUE)
	S.forceMove(src)

/obj/machinery/power/tracker/crowbar_act(mob/user, obj/item/I)
	playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
	user.visible_message(span_notice("[user] начинает снимать стекло с [src].") , span_notice("Начинаю снимать стекло с [src]..."))
	if(I.use_tool(src, user, 50))
		playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
		user.visible_message(span_notice("[user] снимает стекло с [src].") , span_notice("Снимаю стекло с [src]."))
		deconstruct(TRUE)
	return TRUE

/obj/machinery/power/tracker/obj_break(damage_flag)
	. = ..()
	if(.)
		playsound(loc, 'sound/effects/glassbr3.ogg', 100, TRUE)
		unset_control()

/obj/machinery/power/tracker/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			var/obj/item/solar_assembly/S = locate() in src
			if(S)
				S.forceMove(loc)
				S.give_glass(machine_stat & BROKEN)
		else
			playsound(src, "shatter", 70, TRUE)
			new /obj/item/shard(src.loc)
			new /obj/item/shard(src.loc)
	qdel(src)

// Tracker Electronic

/obj/item/electronics/tracker
	name = "электроника отслеживателя солнечных лучей"

#undef TRACKER_Y_OFFSET
#undef TRACKER_EDGE_Y_OFFSET
