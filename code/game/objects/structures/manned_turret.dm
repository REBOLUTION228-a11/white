/////// MANNED TURRET ////////

/obj/machinery/manned_turret
	name = "пулемётная турель"
	desc = "Враги начинают танцевать, когда нажат курок. Попробуй!"
	icon = 'white/valtos/icons/eris_turret.dmi'
	icon_state = "turret_gun"
	can_buckle = TRUE
	anchored = FALSE
	density = TRUE
	max_integrity = 100
	buckle_lying = 0
	layer = ABOVE_MOB_LAYER
	var/view_range = 1
	var/cooldown = 0
	var/projectile_type = /obj/projectile/bullet/manned_turret
	var/rate_of_fire = 1
	var/number_of_shots = 40
	var/cooldown_duration = 90
	var/atom/target
	var/turf/target_turf
	var/warned = FALSE
	var/list/calculated_projectile_vars

/obj/machinery/manned_turret/Initialize()
	. = ..()
	underlays += mutable_appearance(icon, "turret_legs")

/obj/machinery/manned_turret/Destroy()
	target = null
	target_turf = null
	..()

//BUCKLE HOOKS

/obj/machinery/manned_turret/unbuckle_mob(mob/living/buckled_mob,force = FALSE)
	playsound(src,'sound/mecha/mechmove01.ogg', 50, TRUE)
	for(var/obj/item/I in buckled_mob.held_items)
		if(istype(I, /obj/item/gun_control))
			qdel(I)
	if(istype(buckled_mob))
		buckled_mob.pixel_x = buckled_mob.base_pixel_x
		buckled_mob.pixel_y = buckled_mob.base_pixel_y
		if(buckled_mob.client)
			buckled_mob.client.view_size.resetToDefault()
	anchored = FALSE
	. = ..()

/obj/machinery/manned_turret/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSfastprocess, src)

/obj/machinery/manned_turret/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(user.incapacitated() || !istype(user))
		return
	M.forceMove(get_turf(src))
	. = ..()

/obj/machinery/manned_turret/post_buckle_mob(mob/living/M)
	for(var/V in M.held_items)
		var/obj/item/I = V
		if(istype(I))
			if(M.dropItemToGround(I))
				var/obj/item/gun_control/TC = new(src)
				M.put_in_hands(TC)
		else	//Entries in the list should only ever be items or null, so if it's not an item, we can assume it's an empty hand
			var/obj/item/gun_control/TC = new(src)
			M.put_in_hands(TC)
	M.pixel_y = 14
	layer = ABOVE_MOB_LAYER
	setDir(SOUTH)
	playsound(src,'sound/mecha/mechmove01.ogg', 50, TRUE)
	anchored = TRUE
	if(M.client)
		M.client.view_size.setTo(view_range)
	START_PROCESSING(SSfastprocess, src)

/obj/machinery/manned_turret/process()
	if (!update_positioning())
		return PROCESS_KILL

/obj/machinery/manned_turret/proc/update_positioning()
	if (!LAZYLEN(buckled_mobs))
		return FALSE
	var/mob/living/controller = buckled_mobs[1]
	if(!istype(controller))
		return FALSE
	var/client/C = controller.client
	if(C)
		var/atom/A = C.mouseObject
		var/turf/T = get_turf(A)
		if(istype(T))	//They're hovering over something in the map.
			direction_track(controller, T)
			calculated_projectile_vars = calculate_projectile_angle_and_pixel_offsets(controller, T, C.mouseParams)

/obj/machinery/manned_turret/proc/direction_track(mob/user, atom/targeted)
	if(user.incapacitated())
		return
	setDir(get_dir(src,targeted))
	user.setDir(dir)
	switch(dir)
		if(NORTH)
			layer = BELOW_MOB_LAYER
			user.pixel_x = 0
			user.pixel_y = -14
		if(NORTHEAST)
			layer = BELOW_MOB_LAYER
			user.pixel_x = -8
			user.pixel_y = -4
		if(EAST)
			layer = ABOVE_MOB_LAYER
			user.pixel_x = -14
			user.pixel_y = 0
		if(SOUTHEAST)
			layer = BELOW_MOB_LAYER
			user.pixel_x = -8
			user.pixel_y = 4
		if(SOUTH)
			layer = ABOVE_MOB_LAYER
			user.pixel_x = 0
			user.pixel_y = 14
		if(SOUTHWEST)
			layer = BELOW_MOB_LAYER
			user.pixel_x = 8
			user.pixel_y = 4
		if(WEST)
			layer = ABOVE_MOB_LAYER
			user.pixel_x = 14
			user.pixel_y = 0
		if(NORTHWEST)
			layer = BELOW_MOB_LAYER
			user.pixel_x = 8
			user.pixel_y = -4

/obj/machinery/manned_turret/proc/checkfire(atom/targeted_atom, mob/user)
	target = targeted_atom
	if(target == user || user.incapacitated() || target == get_turf(src))
		return
	if(world.time < cooldown)
		if(!warned && world.time > (cooldown - cooldown_duration + rate_of_fire*number_of_shots)) // To capture the window where one is done firing
			warned = TRUE
			playsound(src, 'sound/weapons/sear.ogg', 100, TRUE)
		return
	else
		cooldown = world.time + cooldown_duration
		warned = FALSE
		volley(user)

/obj/machinery/manned_turret/proc/volley(mob/user)
	target_turf = get_turf(target)
	for(var/i in 1 to number_of_shots)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/machinery/manned_turret, fire_helper), user), i*rate_of_fire)

/obj/machinery/manned_turret/proc/fire_helper(mob/user)
	if(user.incapacitated() || !(user in buckled_mobs))
		return
	update_positioning()						//REFRESH MOUSE TRACKING!!
	var/turf/targets_from = get_turf(src)
	if(QDELETED(target))
		target = target_turf
	var/obj/projectile/P = new projectile_type(targets_from)
	P.starting = targets_from
	P.firer = user
	P.original = target
	playsound(src, 'sound/weapons/gun/smg/shot.ogg', 75, TRUE)
	P.xo = target.x - targets_from.x
	P.yo = target.y - targets_from.y
	P.Angle = calculated_projectile_vars[1] + rand(-9, 9)
	P.p_x = calculated_projectile_vars[2]
	P.p_y = calculated_projectile_vars[3]
	P.fire()

/obj/machinery/manned_turret/ultimate  // Admin-only proof of concept for autoclicker automatics
	name = "Ультратурель"
	view_range = 5
	projectile_type = /obj/projectile/bullet/manned_turret

/obj/machinery/manned_turret/ultimate/checkfire(atom/targeted_atom, mob/user)
	target = targeted_atom
	if(target == user || target == get_turf(src))
		return
	target_turf = get_turf(target)
	fire_helper(user)

/obj/item/gun_control
	name = "Контроллер турели"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "offhand"
	w_class = WEIGHT_CLASS_HUGE
	item_flags = ABSTRACT | NOBLUDGEON | DROPDEL
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/obj/machinery/manned_turret/turret

/obj/item/gun_control/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
	turret = loc
	if(!istype(turret))
		return INITIALIZE_HINT_QDEL

/obj/item/gun_control/Destroy()
	turret = null
	..()

/obj/item/gun_control/CanItemAutoclick()
	return TRUE

/obj/item/gun_control/attack_obj(obj/O, mob/living/user)
	user.changeNext_move(CLICK_CD_MELEE)
	O.attacked_by(src, user)

/obj/item/gun_control/attack(mob/living/M, mob/living/user)
//	M.lastattacker = user.real_name
//	M.lastattackerckey = user.ckey
	M.attacked_by(src, user)
	add_fingerprint(user)

/obj/item/gun_control/afterattack(atom/targeted_atom, mob/user, flag, params)
	. = ..()
	var/obj/machinery/manned_turret/E = user.buckled
	E.calculated_projectile_vars = calculate_projectile_angle_and_pixel_offsets(user, targeted_atom, params)
	E.direction_track(user, targeted_atom)
	E.checkfire(targeted_atom, user)
