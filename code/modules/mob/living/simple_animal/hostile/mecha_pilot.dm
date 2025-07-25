
/**
 * Mecha Pilots!
 * By Remie Richards
 *
 * Mecha pilot mobs are able to pilot Mecha to a rudimentary level
 * this allows for certain mobs to be more of a threat (Because they're in a MECH)
 *
 * Mecha Pilots can either spawn with one, or steal one!
 *
 * Inherits from syndicate just to avoid copy-paste)
 *
 * Featuring:
 * * Mecha piloting skills
 * * Uses Mecha equipment
 * * Uses Mecha special abilities in specific situations
 * * Pure Evil Incarnate
 */
/mob/living/simple_animal/hostile/syndicate/mecha_pilot
	name = "Syndicate Mecha Pilot"
	desc = "Death to Nanotrasen. This variant comes in MECHA DEATH flavour."
	wanted_objects = list()
	search_objects = 0
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID

	var/spawn_mecha_type = /obj/vehicle/sealed/mecha/combat/marauder/mauler/loaded
	var/obj/vehicle/sealed/mecha/mecha //Ref to pilot's mecha instance
	var/required_mecha_charge = 7500 //If the pilot doesn't have a mecha, what charge does a potential Grand Theft Mecha need? (Defaults to half a battery)
	var/mecha_charge_evacuate = 50 //Amount of charge at which the pilot tries to abandon the mecha

	//Vars that control when the pilot uses their mecha's abilities (if the mecha has that ability)
	var/threat_use_mecha_smoke = 5 //5 mobs is enough to engage crowd control
	var/defense_mode_chance = 35 //Chance to engage Defense mode when damaged
	var/smoke_chance = 20 //Chance to deploy smoke for crowd control
	var/retreat_chance = 40 //Chance to run away

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/no_mech
	spawn_mecha_type = null
	search_objects = 2

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/no_mech/Initialize()
	. = ..()
	wanted_objects = typecacheof(/obj/vehicle/sealed/mecha/combat, TRUE)

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/nanotrasen //nanotrasen are syndies! no it's just a weird path.
	name = "\improper Nanotrasen Mecha Pilot"
	desc = "Death to the Syndicate. This variant comes in MECHA DEATH flavour."
	icon_living = "nanotrasen"
	icon_state = "nanotrasen"
	faction = list("nanotrasen")
	spawn_mecha_type = /obj/vehicle/sealed/mecha/combat/marauder/loaded

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/no_mech/nanotrasen
	name = "\improper Nanotrasen Mecha Pilot"
	desc = "Death to the Syndicate. This variant comes in MECHA DEATH flavour."
	icon_living = "nanotrasen"
	icon_state = "nanotrasen"
	faction = list("nanotrasen")


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/Initialize()
	. = ..()
	if(spawn_mecha_type)
		var/obj/vehicle/sealed/mecha/M = new spawn_mecha_type (get_turf(src))
		if(istype(M))
			INVOKE_ASYNC(src, PROC_REF(enter_mecha), M)


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/enter_mecha(obj/vehicle/sealed/mecha/M)
	if(!M)
		return 0
	target = null //Target was our mecha, so null it out
	M.aimob_enter_mech(src)
	targets_from = WEAKREF(M)
	allow_movement_on_non_turfs = TRUE //duh
	var/do_ranged = 0
	for(var/equip in mecha.flat_equipment)
		var/obj/item/mecha_parts/mecha_equipment/ME = equip
		if(ME.range & MECHA_RANGED)
			do_ranged = 1
			break
	if(do_ranged)
		minimum_distance = 5
		ranged = 1
	else
		minimum_distance = 1
		ranged = 0
	wanted_objects = list()
	search_objects = 0
	if(LAZYACCESSASSOC(mecha.occupant_actions, src, /datum/action/vehicle/sealed/mecha/mech_defense_mode) && !mecha.defense_mode)
		var/datum/action/action = mecha.occupant_actions[src][/datum/action/vehicle/sealed/mecha/mech_defense_mode]
		action.Trigger(TRUE)

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/exit_mecha(obj/vehicle/sealed/mecha/M)
	if(!M)
		return 0

	mecha.aimob_exit_mech(src)
	allow_movement_on_non_turfs = FALSE
	targets_from = null

	//Find a new mecha
	wanted_objects = typecacheof(/obj/vehicle/sealed/mecha/combat, TRUE)
	var/search_aggressiveness = 2
	for(var/obj/vehicle/sealed/mecha/combat/C in range(vision_range,src))
		if(is_valid_mecha(C))
			target = C
			search_aggressiveness = 3 //We can see a mech? RUN FOR IT, IGNORE MOBS!
			break
	search_objects = search_aggressiveness
	ranged = 0
	minimum_distance = 1

	SSmove_manager.stop_looping(src)//end any lingering movement loops, to prevent the haunted mecha bug

//Checks if a mecha is valid for theft
/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/is_valid_mecha(obj/vehicle/sealed/mecha/M)
	if(!M)
		return FALSE
	if(LAZYLEN(M.occupants))
		return FALSE
	if(!M.has_charge(required_mecha_charge))
		return FALSE
	if(M.obj_integrity < M.max_integrity*0.5)
		return FALSE
	return TRUE


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/mecha_face_target(atom/A)
	if(mecha)
		var/dirto = get_dir(mecha,A)
		if(mecha.dir != dirto) //checking, because otherwise the mecha makes too many turn noises
			mecha.vehicle_move(dirto, TRUE)



/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/mecha_reload()
	if(mecha)
		for(var/equip in mecha.flat_equipment)
			var/obj/item/mecha_parts/mecha_equipment/ME = equip
			if(ME.needs_rearm())
				ME.rearm()


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/proc/get_mecha_equip_by_flag(flag = MECHA_RANGED)
	. = list()
	if(mecha)
		for(var/equip in mecha.flat_equipment)
			var/obj/item/mecha_parts/mecha_equipment/ME = equip
			if((ME.range & flag) && ME.action_checks(ME)) //this looks weird, but action_checks() just needs any atom, so I spoofed it here
				. += ME



//Pick a ranged weapon/tool
//Fire it
/mob/living/simple_animal/hostile/syndicate/mecha_pilot/OpenFire(atom/A)
	if(mecha)
		mecha_reload()
		mecha_face_target(A)
		var/list/possible_weapons = get_mecha_equip_by_flag(MECHA_RANGED)
		if(possible_weapons.len)
			var/obj/item/mecha_parts/mecha_equipment/ME = pick(possible_weapons) //so we don't favor mecha.equipment[1] forever
			if(ME.action(src,A))
				return

	else
		..()


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/AttackingTarget()
	if(mecha)
		var/list/possible_weapons = get_mecha_equip_by_flag(MECHA_MELEE)
		if(possible_weapons.len)
			var/obj/item/mecha_parts/mecha_equipment/ME = pick(possible_weapons)
			mecha_face_target(target)
			if(ME.action(src,target))
				return

		if(!TIMER_COOLDOWN_CHECK(mecha, COOLDOWN_MECHA_MELEE_ATTACK))
			mecha_face_target(target)
			target.mech_melee_attack(mecha, src)
	else
		if(ismecha(target))
			var/obj/vehicle/sealed/mecha/M = target
			if(is_valid_mecha(M))
				enter_mecha(M)
				return
			else
				if(!CanAttack(M))
					target = null
					return

		return target.attack_animal(src)


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/handle_automated_action()
	. = ..()
	if(!.)
		return
	if(!mecha)
		for(var/obj/vehicle/sealed/mecha/combat/mecha_in_range in range(src,vision_range))
			if(is_valid_mecha(mecha_in_range))
				target = mecha_in_range //Let's nab it!
				minimum_distance = 1
				ranged = 0
				break
	if(mecha)
		var/list/L = PossibleThreats()
		var/threat_count = L.len

		//Low Charge - Eject
		if(!mecha.has_charge(mecha_charge_evacuate))
			exit_mecha(mecha)
			return

			//Too Much Damage - Eject
		if(mecha.obj_integrity < mecha.max_integrity*0.1)
			exit_mecha(mecha)
			return

		//Smoke if there's too many targets	- Smoke Power
		if(threat_count >= threat_use_mecha_smoke && prob(smoke_chance))
			if(LAZYACCESSASSOC(mecha.occupant_actions, src, /datum/action/vehicle/sealed/mecha/mech_smoke) && !mecha.smoke_charges)
				var/datum/action/action = mecha.occupant_actions[src][/datum/action/vehicle/sealed/mecha/mech_smoke]
				action.Trigger()

		//Heavy damage - Defense Power or Retreat
		if(mecha.obj_integrity < mecha.max_integrity*0.25)
			if(prob(defense_mode_chance))
				if(LAZYACCESSASSOC(mecha.occupant_actions, src, /datum/action/vehicle/sealed/mecha/mech_defense_mode) && !mecha.defense_mode)
					var/datum/action/action = mecha.occupant_actions[src][/datum/action/vehicle/sealed/mecha/mech_defense_mode]
					action.Trigger(TRUE)
					addtimer(CALLBACK(action, TYPE_PROC_REF(/datum/action/vehicle/sealed/mecha/mech_defense_mode, Trigger), FALSE), 100) //10 seconds of defense, then toggle off

			else if(prob(retreat_chance))
				//Speed boost if possible
				if(LAZYACCESSASSOC(mecha.occupant_actions, src, /datum/action/vehicle/sealed/mecha/mech_overload_mode) && !mecha.leg_overload_mode)
					var/datum/action/action = mecha.occupant_actions[src][/datum/action/vehicle/sealed/mecha/mech_overload_mode]
					mecha.leg_overload_mode = FALSE
					action.Trigger(TRUE)
					addtimer(CALLBACK(action, TYPE_PROC_REF(/datum/action/vehicle/sealed/mecha/mech_overload_mode, Trigger), FALSE), 100) //10 seconds of speeeeed, then toggle off

				retreat_distance = 50
				addtimer(VARSET_CALLBACK(src, retreat_distance, 0), 10 SECONDS)



/mob/living/simple_animal/hostile/syndicate/mecha_pilot/death(gibbed)
	if(mecha)
		mecha.aimob_exit_mech(src)
	..()

/mob/living/simple_animal/hostile/syndicate/mecha_pilot/gib()
	if(mecha)
		mecha.aimob_exit_mech(src)
	..()


//Yes they actually try and pull this shit
//~simple animals~
/mob/living/simple_animal/hostile/syndicate/mecha_pilot/CanAttack(atom/the_target)
	if(ismecha(the_target))
		var/obj/vehicle/sealed/mecha/M = the_target
		if(mecha)
			if(M == mecha)	//Dont kill yourself
				return FALSE
		else //we're not in a mecha, so we check if we can steal it instead.
			if(is_valid_mecha(M))
				return TRUE
			for(var/occupant in M.occupants)
				if(CanAttack(occupant))
					return TRUE
			return FALSE

	. = ..()


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/EscapeConfinement()
	if(mecha && loc == mecha)
		return 0
	..()


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/Move(NewLoc,Dir=0,step_x=0,step_y=0)
	if(mecha && loc == mecha)
		return mecha.relaymove(src, Dir)
	return ..()


/mob/living/simple_animal/hostile/syndicate/mecha_pilot/Goto(target, delay, minimum_distance)
	if(mecha)
		SSmove_manager.move_to(mecha, target, minimum_distance, mecha.movedelay)
	else
		..()
