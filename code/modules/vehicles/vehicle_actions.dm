//VEHICLE DEFAULT HANDLING

/**
 * ## generate_actions
 *
 * You override this with initialize_passenger_action_type and initialize_controller_action_type calls
 * To give passengers actions when they enter the vehicle.
 * Read the documentation on the aforementioned procs to learn the difference
 */
/obj/vehicle/proc/generate_actions()
	return

/**
 * ## generate_action_type
 *
 * A small proc to properly set up each action path.
 * args:
 * * actiontype: typepath of the action the proc sets up.
 * returns created and set up action instance
 */
/obj/vehicle/proc/generate_action_type(actiontype)
	var/datum/action/vehicle/A = new actiontype
	if(!istype(A))
		return
	A.vehicle_target = src
	return A

/**
 * ## initialize_passenger_action_type
 *
 * Gives any passenger that enters the mech this action.
 * They will lose it when they disembark.
 * args:
 * * actiontype: typepath of the action you want to give occupants.
 */
/obj/vehicle/proc/initialize_passenger_action_type(actiontype)
	autogrant_actions_passenger += actiontype
	for(var/i in occupants)
		grant_passenger_actions(i)	//refresh

/**
 * ## initialize_controller_action_type
 *
 * Gives any passenger that enters the mech this action... IF they have the correct vehicle control flag.
 * This is used so passengers cannot press buttons only drivers should have, for example.
 * args:
 * * actiontype: typepath of the action you want to give occupants.
 */
/obj/vehicle/proc/initialize_controller_action_type(actiontype, control_flag)
	LAZYINITLIST(autogrant_actions_controller["[control_flag]"])
	autogrant_actions_controller["[control_flag]"] += actiontype
	for(var/i in occupants)
		grant_controller_actions(i)	//refresh

/**
 * ## grant_action_type_to_mob
 *
 * As on the tin, it does all the annoying small stuff and sanity needed
 * to GRANT an action to a mob.
 * args:
 * * actiontype: typepath of the action you want to give to grant_to.
 * * grant_to: the mob we're giving actiontype to
 * returns TRUE if successfully granted
 */
/obj/vehicle/proc/grant_action_type_to_mob(actiontype, mob/grant_to)
	if(isnull(LAZYACCESS(occupants, grant_to)) || !actiontype)
		return FALSE
	LAZYINITLIST(occupant_actions[grant_to])
	if(occupant_actions[grant_to][actiontype])
		return TRUE
	var/datum/action/action = generate_action_type(actiontype)
	action.Grant(grant_to)
	occupant_actions[grant_to][action.type] = action
	return TRUE

/**
 * ## remove_action_type_from_mob
 *
 * As on the tin, it does all the annoying small stuff and sanity needed
 * to REMOVE an action to a mob.
 * args:
 * * actiontype: typepath of the action you want to give to grant_to.
 * * take_from: the mob we're taking actiontype to
 * returns TRUE if successfully removed
 */
/obj/vehicle/proc/remove_action_type_from_mob(actiontype, mob/take_from)
	if(isnull(LAZYACCESS(occupants, take_from)) || !actiontype)
		return FALSE
	LAZYINITLIST(occupant_actions[take_from])
	if(occupant_actions[take_from][actiontype])
		var/datum/action/action = occupant_actions[take_from][actiontype]
		action.Remove(take_from)
		occupant_actions[take_from] -= actiontype
	return TRUE

/**
 * ## grant_passenger_actions
 *
 * Called on every passenger that enters the vehicle, goes through the list of actions it needs to give...
 * and does that.
 * args:
 * * grant_to: mob that needs to get every action the vehicle grants
 */
/obj/vehicle/proc/grant_passenger_actions(mob/grant_to)
	for(var/v in autogrant_actions_passenger)
		grant_action_type_to_mob(v, grant_to)

/**
 * ## remove_passenger_actions
 *
 * Called on every passenger that exits the vehicle, goes through the list of actions it needs to remove...
 * and does that.
 * args:
 * * take_from: mob that needs to get every action the vehicle grants
 */
/obj/vehicle/proc/remove_passenger_actions(mob/take_from)
	for(var/v in autogrant_actions_passenger)
		remove_action_type_from_mob(v, take_from)

/obj/vehicle/proc/grant_controller_actions(mob/M)
	if(!istype(M) || isnull(LAZYACCESS(occupants, M)))
		return FALSE
	for(var/i in GLOB.bitflags)
		if(occupants[M] & i)
			grant_controller_actions_by_flag(M, i)
	return TRUE

/obj/vehicle/proc/remove_controller_actions(mob/M)
	if(!istype(M) || isnull(LAZYACCESS(occupants, M)))
		return FALSE
	for(var/i in GLOB.bitflags)
		remove_controller_actions_by_flag(M, i)
	return TRUE

/obj/vehicle/proc/grant_controller_actions_by_flag(mob/M, flag)
	if(!istype(M))
		return FALSE
	for(var/v in autogrant_actions_controller["[flag]"])
		grant_action_type_to_mob(v, M)
	return TRUE

/obj/vehicle/proc/remove_controller_actions_by_flag(mob/M, flag)
	if(!istype(M))
		return FALSE
	for(var/v in autogrant_actions_controller["[flag]"])
		remove_action_type_from_mob(v, M)
	return TRUE

/obj/vehicle/proc/cleanup_actions_for_mob(mob/M)
	if(!istype(M))
		return FALSE
	for(var/path in occupant_actions[M])
		stack_trace("Leftover action type [path] in vehicle type [type] for mob type [M.type] - THIS SHOULD NOT BE HAPPENING!")
		var/datum/action/action = occupant_actions[M][path]
		action.Remove(M)
		occupant_actions[M] -= path
	occupant_actions -= M
	return TRUE

/***************** ACTION DATUMS *****************/

/datum/action/vehicle
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_IMMOBILE | AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_vehicle.dmi'
	button_icon_state = "vehicle_eject"
	var/obj/vehicle/vehicle_target

/datum/action/vehicle/sealed
	check_flags = AB_CHECK_IMMOBILE | AB_CHECK_CONSCIOUS
	var/obj/vehicle/sealed/vehicle_entered_target

/datum/action/vehicle/sealed/climb_out
	name = "Climb Out"
	desc = "Climb out of your vehicle!"
	button_icon_state = "car_eject"

/datum/action/vehicle/sealed/climb_out/Trigger()
	if(..() && istype(vehicle_entered_target))
		vehicle_entered_target.mob_try_exit(owner, owner)

/datum/action/vehicle/ridden
	var/obj/vehicle/ridden/vehicle_ridden_target

/datum/action/vehicle/sealed/remove_key
	name = "Remove key"
	desc = "Take your key out of the vehicle's ignition."
	button_icon_state = "car_removekey"

/datum/action/vehicle/sealed/remove_key/Trigger()
	vehicle_entered_target.remove_key(owner)

//CLOWN CAR ACTION DATUMS
/datum/action/vehicle/sealed/horn
	name = "Honk Horn"
	desc = "Honk your classy horn."
	button_icon_state = "car_horn"
	var/hornsound = 'sound/items/carhorn.ogg'

/datum/action/vehicle/sealed/horn/Trigger()
	if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_CAR_HONK))
		return
	TIMER_COOLDOWN_START(src, COOLDOWN_CAR_HONK, 2 SECONDS)
	vehicle_entered_target.visible_message(span_danger("[vehicle_entered_target] loudly honks!"))
	to_chat(owner, span_notice("You press [vehicle_entered_target]'s horn."))
	if(istype(vehicle_target.inserted_key, /obj/item/bikehorn))
		vehicle_target.inserted_key.attack_self(owner) //The bikehorn plays a sound instead
		return
	playsound(vehicle_entered_target, hornsound, 75)

/datum/action/vehicle/sealed/headlights
	name = "Toggle Headlights"
	desc = "Turn on your brights!"
	button_icon_state = "car_headlights"

/datum/action/vehicle/sealed/headlights/Trigger()
	to_chat(owner, span_notice("You flip the switch for the vehicle's headlights."))
	vehicle_entered_target.headlights_toggle = !vehicle_entered_target.headlights_toggle
	vehicle_entered_target.set_light_on(vehicle_entered_target.headlights_toggle)
	playsound(owner, vehicle_entered_target.headlights_toggle ? 'sound/weapons/magin.ogg' : 'sound/weapons/magout.ogg', 40, TRUE)

/datum/action/vehicle/sealed/dump_kidnapped_mobs
	name = "Dump Kidnapped Mobs"
	desc = "Dump all objects and people in your car on the floor."
	button_icon_state = "car_dump"

/datum/action/vehicle/sealed/dump_kidnapped_mobs/Trigger()
	vehicle_entered_target.visible_message(span_danger("[vehicle_entered_target] starts dumping the people inside of it."))
	vehicle_entered_target.dump_specific_mobs(VEHICLE_CONTROL_KIDNAPPED)


/datum/action/vehicle/sealed/roll_the_dice
	name = "Press Colorful Button"
	desc = "Press one of those colorful buttons on your display panel!"
	button_icon_state = "car_rtd"

/datum/action/vehicle/sealed/roll_the_dice/Trigger()
	if(!istype(vehicle_entered_target, /obj/vehicle/sealed/car/clowncar))
		return
	var/obj/vehicle/sealed/car/clowncar/C = vehicle_entered_target
	C.roll_the_dice(owner)

/datum/action/vehicle/sealed/cannon
	name = "Toggle Siege Mode"
	desc = "Destroy them with their own fodder!"
	button_icon_state = "car_cannon"

/datum/action/vehicle/sealed/cannon/Trigger()
	if(!istype(vehicle_entered_target, /obj/vehicle/sealed/car/clowncar))
		return
	var/obj/vehicle/sealed/car/clowncar/C = vehicle_entered_target
	C.toggle_cannon(owner)


/datum/action/vehicle/sealed/thank
	name = "Thank the Clown Car Driver"
	desc = "They're just doing their job."
	button_icon_state = "car_thanktheclown"
	COOLDOWN_DECLARE(thank_time_cooldown)


/datum/action/vehicle/sealed/thank/Trigger()
	if(!istype(vehicle_entered_target, /obj/vehicle/sealed/car/clowncar))
		return
	if(!COOLDOWN_FINISHED(src, thank_time_cooldown))
		return
	COOLDOWN_START(src, thank_time_cooldown, 6 SECONDS)
	var/obj/vehicle/sealed/car/clowncar/clown_car = vehicle_entered_target
	var/mob/living/carbon/human/clown = pick(clown_car.return_drivers())
	if(!clown)
		return
	owner.say("Thank you for the fun ride, [clown.name]!")
	clown_car.increment_thanks_counter()


/datum/action/vehicle/ridden/scooter/skateboard/ollie
	name = "Ollie"
	desc = "Get some air! Land on a table to do a gnarly grind."
	button_icon_state = "skateboard_ollie"
	///Cooldown to next jump
	var/next_ollie

/datum/action/vehicle/ridden/scooter/skateboard/ollie/Trigger()
	if(world.time > next_ollie)
		var/obj/vehicle/ridden/scooter/skateboard/vehicle = vehicle_target
		vehicle.obj_flags |= BLOCK_Z_OUT_DOWN
		if (vehicle.grinding)
			return
		var/mob/living/rider = owner
		var/turf/landing_turf = get_step(vehicle.loc, vehicle.dir)
		rider.adjustStaminaLoss(vehicle.instability*2)
		if (rider.getStaminaLoss() >= 100)
			vehicle.obj_flags &= ~CAN_BE_HIT
			playsound(src, 'sound/effects/bang.ogg', 20, TRUE)
			vehicle.unbuckle_mob(rider)
			rider.throw_at(landing_turf, 2, 2)
			rider.Paralyze(40)
			vehicle.visible_message(span_danger("[rider] misses the landing and falls on [rider.ru_ego()] face!"))
		else
			rider.spin(4, 1)
			animate(rider, pixel_y = -6, time = 4)
			animate(vehicle, pixel_y = -6, time = 3)
			playsound(vehicle, 'sound/vehicles/skateboard_ollie.ogg', 50, TRUE)
			passtable_on(rider, VEHICLE_TRAIT)
			vehicle.pass_flags |= PASSTABLE
			rider.Move(landing_turf, vehicle_target.dir)
			passtable_off(rider, VEHICLE_TRAIT)
			vehicle.pass_flags &= ~PASSTABLE
		var/turf/cur_turf = get_turf(vehicle)
		if((locate(/obj/structure/table) in cur_turf.contents) || (locate(/obj/structure/fluff/tram_rail) in cur_turf.contents))
			if(locate(/obj/structure/fluff/tram_rail) in cur_turf.contents)
				rider.client.give_award(/datum/award/achievement/misc/tram_surfer, rider)
			vehicle.grinding = TRUE
			vehicle.icon_state = "[initial(vehicle.icon_state)]-grind"
			addtimer(CALLBACK(vehicle, TYPE_PROC_REF(/obj/vehicle/ridden/scooter/skateboard, grind)), 2)
