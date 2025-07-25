/obj/vehicle/sealed/car
	layer = ABOVE_MOB_LAYER
	move_resist = MOVE_FORCE_VERY_STRONG
	///Bitflags for special behavior such as kidnapping
	var/car_traits = NONE
	///Sound file(s) to play when we drive around
	var/engine_sound = 'sound/vehicles/carrev.ogg'
	///Set this to the length of the engine sound.
	var/engine_sound_length = 2 SECONDS
	///Time it takes to break out of the car.
	var/escape_time = 6 SECONDS
	/// How long it takes to move, cars don't use the riding component similar to mechs so we handle it ourselves
	var/vehicle_move_delay = 1
	/// How long it takes to rev (vrrm vrrm!)
	COOLDOWN_DECLARE(enginesound_cooldown)

/obj/vehicle/sealed/car/generate_actions()
	. = ..()
	initialize_controller_action_type(/datum/action/vehicle/sealed/remove_key, VEHICLE_CONTROL_DRIVE)
	if(car_traits & CAN_KIDNAP)
		initialize_controller_action_type(/datum/action/vehicle/sealed/dump_kidnapped_mobs, VEHICLE_CONTROL_DRIVE)

/obj/vehicle/sealed/car/MouseDrop_T(atom/dropping, mob/M)
	if(M.stat != CONSCIOUS || HAS_TRAIT(M, TRAIT_HANDS_BLOCKED))
		return FALSE
	if((car_traits & CAN_KIDNAP) && isliving(dropping) && M != dropping)
		var/mob/living/kidnapped = dropping
		kidnapped.visible_message(span_warning("[M] starts forcing [kidnapped] into [src]!"))
		mob_try_forced_enter(M, kidnapped)
	return ..()

/obj/vehicle/sealed/car/mob_try_exit(mob/M, mob/user, silent = FALSE)
	if(M != user || !(LAZYACCESS(occupants, M) & VEHICLE_CONTROL_KIDNAPPED))
		mob_exit(M, silent)
		return TRUE
	to_chat(user, span_notice("You push against the back of [src]'s trunk to try and get out."))
	if(!do_after(user, escape_time, target = src))
		return FALSE
	to_chat(user,span_danger("[user] gets out of [src]."))
	mob_exit(M, silent)
	return TRUE

/obj/vehicle/sealed/car/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!(car_traits & CAN_KIDNAP))
		return
	to_chat(user, span_notice("You start opening [src]'s trunk."))
	if(!do_after(user, 30))
		return
	if(return_amount_of_controllers_with_flag(VEHICLE_CONTROL_KIDNAPPED))
		to_chat(user, span_notice("The people stuck in [src]'s trunk all come tumbling out."))
		dump_specific_mobs(VEHICLE_CONTROL_KIDNAPPED)
		return
	to_chat(user, span_notice("It seems [src]'s trunk was empty."))

///attempts to force a mob into the car
/obj/vehicle/sealed/car/proc/mob_try_forced_enter(mob/forcer, mob/kidnapped, silent = FALSE)
	if(occupant_amount() >= max_occupants)
		return FALSE
	var/atom/old_loc = loc
	if(do_mob(forcer, kidnapped, get_enter_delay(kidnapped), extra_checks=CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/car, is_car_stationary), old_loc)))
		mob_forced_enter(kidnapped, silent)
		return TRUE
	return FALSE

///Callback proc to check for
/obj/vehicle/sealed/car/proc/is_car_stationary(atom/old_loc)
	return (old_loc == loc)

///Proc called when someone is forcefully stuffedd into a car
/obj/vehicle/sealed/car/proc/mob_forced_enter(mob/kidnapped, silent = FALSE)
	if(!silent)
		kidnapped.visible_message(span_warning("[kidnapped] is forced into [src]!"))
	kidnapped.forceMove(src)
	add_occupant(kidnapped, VEHICLE_CONTROL_KIDNAPPED)

/obj/vehicle/sealed/car/obj_destruction(damage_flag)
	explosion(loc, 0, 1, 2, 3, 0)
	log_message("[src] exploded due to destruction", LOG_ATTACK)
	return ..()

/obj/vehicle/sealed/car/relaymove(mob/living/user, direction)
	if(is_driver(user) && canmove && (!key_type || istype(inserted_key, key_type)))
		vehicle_move(direction)
	return TRUE

/obj/vehicle/sealed/car/vehicle_move(direction)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, vehicle_move_delay)

	if(COOLDOWN_FINISHED(src, enginesound_cooldown))
		COOLDOWN_START(src, enginesound_cooldown, engine_sound_length)
		playsound(get_turf(src), engine_sound, 100, TRUE)

	if(trailer)
		var/dir_to_move = get_dir(trailer.loc, loc)
		var/did_move = step(src, direction)
		if(did_move)
			step(trailer, dir_to_move)
		return did_move
	after_move(direction)
	return step(src, direction)
