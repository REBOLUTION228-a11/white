
/obj/machinery/food_cart
	name = "food cart"
	desc = "A compact unpackable mobile cooking stand. Wow! When unpacked, it reminds you of those greasy gamer setups some people on NTNet have."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "foodcart"
	density = TRUE
	anchored = FALSE
	use_power = NO_POWER_USE
	req_access = list(ACCESS_KITCHEN)
	flags_1 = NODECONSTRUCT_1
	var/unpacked = FALSE
	var/obj/machinery/griddle/stand/cart_griddle
	var/obj/machinery/smartfridge/food/cart_smartfridge
	var/obj/structure/table/reinforced/cart_table
	var/obj/effect/food_cart_stand/cart_tent
	var/list/packed_things

/obj/machinery/food_cart/Initialize()
	. = ..()
	cart_griddle = new(src)
	cart_smartfridge = new(src)
	cart_table = new(src)
	cart_tent = new(src)
	packed_things = list(cart_table, cart_smartfridge, cart_tent, cart_griddle) //middle, left, left, right
	RegisterSignal(cart_griddle, COMSIG_PARENT_QDELETING, PROC_REF(lost_part))
	RegisterSignal(cart_smartfridge, COMSIG_PARENT_QDELETING, PROC_REF(lost_part))
	RegisterSignal(cart_table, COMSIG_PARENT_QDELETING, PROC_REF(lost_part))
	RegisterSignal(cart_tent, COMSIG_PARENT_QDELETING, PROC_REF(lost_part))

/obj/machinery/food_cart/Destroy()
	/*
	if(cart_griddle)
		QDEL_NULL(cart_griddle)
	if(cart_smartfridge)
		QDEL_NULL(cart_smartfridge)
	if(cart_table)
		QDEL_NULL(cart_table)
	if(cart_tent)
		QDEL_NULL(cart_tent)
	packed_things.Cut()
	*/
	return ..()

/obj/machinery/food_cart/examine(mob/user)
	. = ..()
	if(!(machine_stat & BROKEN))
		if(cart_griddle.machine_stat & BROKEN)
			. += "<hr><span class='warning'>The stand's <b>griddle</b> is completely broken!</span>"
		else
			. += "<hr><span class='notice'>The stand's <b>griddle</b> is intact.</span>"
		. += "\n<span class='notice'>The stand's <b>fridge</b> seems fine.</span>" //weirdly enough, these fridges don't break
		. += "\n<span class='notice'>The stand's <b>table</b> seems fine.</span>"

/obj/machinery/food_cart/proc/pack_up()
	if(!unpacked)
		return
	visible_message(span_notice("[src] retracts all of it's unpacked components."))
	for(var/o in packed_things)
		var/obj/object = o
		UnregisterSignal(object, COMSIG_MOVABLE_MOVED)
		object.forceMove(src)
	anchored = FALSE
	unpacked = FALSE

/obj/machinery/food_cart/proc/unpack(mob/user)
	if(unpacked)
		return
	if(!check_setup_place())
		to_chat(user, span_warning("There isn't enough room to unpack here! Bad spaces were marked in red."))
		return
	visible_message(span_notice("[src] expands into a full stand."))
	anchored = TRUE
	var/iteration = 1
	var/turf/grabbed_turf = get_step(get_turf(src), EAST)
	for(var/angle in list(0, -45, -45, 45))
		var/turf/T = get_step(grabbed_turf, turn(SOUTH, angle))
		var/obj/thing = packed_things[iteration]
		thing.forceMove(T)
		RegisterSignal(thing, COMSIG_MOVABLE_MOVED, PROC_REF(lost_part))
		iteration++
	unpacked = TRUE

/obj/machinery/food_cart/attack_hand(mob/living/user)
	. = ..()
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("[src] is completely busted."))
		return
	var/obj/item/card/id/id_card = user.get_idcard(hand_first = TRUE)
	if(!check_access(id_card))
		playsound(src, 'white/valtos/sounds/error1.ogg', 30, TRUE)
		return
	to_chat(user, span_notice("You attempt to [unpacked ? "pack up" :"unpack"] [src]..."))
	if(!do_after(user, 5 SECONDS, src))
		to_chat(user, span_warning("Your [unpacked ? "" :"un"]packing of [src] was interrupted!"))
		return
	if(unpacked)
		pack_up()
	else
		unpack(user)

/obj/machinery/food_cart/proc/check_setup_place()
	var/has_space = TRUE
	var/turf/grabbed_turf = get_step(get_turf(src), EAST)
	for(var/angle in list(0, -45, 45))
		var/turf/T = get_step(grabbed_turf, turn(SOUTH, angle))
		if(T && !T.density)
			new /obj/effect/temp_visual/cart_space(T)
		else
			has_space = FALSE
			new /obj/effect/temp_visual/cart_space/bad(T)
	return has_space

/obj/machinery/food_cart/proc/lost_part(atom/movable/source, force)
	SIGNAL_HANDLER

	//okay, so it's deleting the fridge or griddle which are more important. We're gonna break the machine then
	UnregisterSignal(cart_griddle, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	UnregisterSignal(cart_smartfridge, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	UnregisterSignal(cart_table, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	UnregisterSignal(cart_tent, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	obj_break()

/obj/machinery/food_cart/obj_break(damage_flag)
	. = ..()
	pack_up()
	if(cart_griddle)
		QDEL_NULL(cart_griddle)
	if(cart_smartfridge)
		QDEL_NULL(cart_smartfridge)
	if(cart_table)
		QDEL_NULL(cart_table)
	QDEL_NULL(cart_tent)

/obj/effect/food_cart_stand
	name = "food cart tent"
	desc = "Something to battle the sun, for there are no breaks for the burger flippers."
	icon = 'icons/obj/3x3.dmi'
	icon_state = "stand"
	layer = ABOVE_MOB_LAYER//big mobs will still go over the tent, this is fine and cool
	plane = GAME_PLANE_UPPER
