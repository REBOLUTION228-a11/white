

//TODO: Make these simple_animals

#define MIN_IMPREGNATION_TIME 100 //time it takes to impregnate someone
#define MAX_IMPREGNATION_TIME 150

#define MIN_ACTIVE_TIME 200 //time between being dropped and going idle
#define MAX_ACTIVE_TIME 400

/obj/item/clothing/mask/facehugger
	name = "alien"
	desc = "It has some sort of a tube at the end of its tail."
	icon = 'icons/mob/alien.dmi'
	icon_state = "facehugger"
	inhand_icon_state = "facehugger"
	w_class = WEIGHT_CLASS_TINY //note: can be picked up by aliens unlike most other items of w_class below 4
	clothing_flags = MASKINTERNALS
	throw_range = 5
	tint = 3
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH
	layer = MOB_LAYER
	plane = GAME_PLANE_FOV_HIDDEN
	max_integrity = 100
	item_flags = XENOMORPH_HOLDABLE
	var/stat = CONSCIOUS //UNCONSCIOUS is the idle state in this case

	var/sterile = FALSE
	var/real = TRUE //0 for the toy, 1 for real. Sure I could istype, but fuck that.
	var/strength = 5

	var/attached = 0

/obj/item/clothing/mask/facehugger/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	AddElement(/datum/element/atmos_sensitive, mapload)

/obj/item/clothing/mask/facehugger/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	..()
	if(obj_integrity < 90)
		Die()

/obj/item/clothing/mask/facehugger/attackby(obj/item/O, mob/user, params)
	return O.attack_obj(src, user)

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/clothing/mask/facehugger/attack_hand(mob/user)
	if((stat == CONSCIOUS && !sterile) && !isalien(user))
		if(Leap(user))
			return
	. = ..()

/obj/item/clothing/mask/facehugger/attack(mob/living/M, mob/user)
	..()
	if(user.transferItemToLoc(src, get_turf(M)))
		Leap(M)

/obj/item/clothing/mask/facehugger/examine(mob/user)
	. = ..()
	if(!real)//So that giant red text about probisci doesn't show up.
		return
	switch(stat)
		if(DEAD,UNCONSCIOUS)
			. += "<hr><span class='boldannounce'>[capitalize(src.name)] is not moving.</span>"
		if(CONSCIOUS)
			. += "<hr><span class='boldannounce'>[capitalize(src.name)] seems to be active!</span>"
	if (sterile)
		. += "<hr><span class='boldannounce'>It looks like the proboscis has been removed.</span>"

/obj/item/clothing/mask/facehugger/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return (exposed_temperature > 300)

/obj/item/clothing/mask/facehugger/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	Die()

/obj/item/clothing/mask/facehugger/equipped(mob/M)
	. = ..()
	Attach(M)

/obj/item/clothing/mask/facehugger/proc/on_entered(datum/source, atom/target)
	SIGNAL_HANDLER
	HasProximity(target)

/obj/item/clothing/mask/facehugger/on_found(mob/finder)
	if(stat == CONSCIOUS)
		return HasProximity(finder)

/obj/item/clothing/mask/facehugger/HasProximity(atom/movable/AM as mob|obj)
	if(CanHug(AM) && Adjacent(AM))
		return Leap(AM)

/obj/item/clothing/mask/facehugger/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, quickstart = TRUE)
	. = ..()
	if(!.)
		return
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]_thrown"
		addtimer(CALLBACK(src, PROC_REF(clear_throw_icon_state)), 15)

/obj/item/clothing/mask/facehugger/proc/clear_throw_icon_state()
	if(icon_state == "[initial(icon_state)]_thrown")
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/mask/facehugger/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	..()
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]"
		Leap(hit_atom)

/obj/item/clothing/mask/facehugger/proc/valid_to_attach(mob/living/M)
	// valid targets: carbons except aliens and devils
	// facehugger state early exit checks
	if(stat != CONSCIOUS)
		return FALSE
	if(attached)
		return FALSE
	if(iscarbon(M))
		// disallowed carbons
		if(isalien(M) || istruedevil(M))
			return FALSE
		var/mob/living/carbon/target = M
		// gotta have a head to be implanted (no changelings or sentient plants)
		if(!target.get_bodypart(BODY_ZONE_HEAD))
			return FALSE
		// gotta be able to have the xeno implanted
		if(HAS_TRAIT(M, TRAIT_XENO_IMMUNE))
			return FALSE
		// carbon, has head, not alien or devil, has no hivenode or embryo: valid
		return TRUE

	return FALSE

/obj/item/clothing/mask/facehugger/proc/Leap(mob/living/M)
	if(!valid_to_attach(M))
		return FALSE
	if(iscarbon(M))
		var/mob/living/carbon/target = M
		if(target.wear_mask && istype(target.wear_mask, /obj/item/clothing/mask/facehugger))
			return FALSE
	// passed initial checks - time to leap!
	M.visible_message(span_danger("[capitalize(src.name)] leaps at [M] face!") , \
							span_userdanger("[capitalize(src.name)] leaps at your face!"))

	// probiscis-blocker handling
	if(iscarbon(M))
		var/mob/living/carbon/target = M

		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H.is_mouth_covered(head_only = 1))
				H.visible_message(span_danger("[capitalize(src.name)] smashes against [H] [H.head]!") , \
									span_userdanger("[capitalize(src.name)] smashes against your [H.head]!"))
				Die()
				return FALSE

		if(target.wear_mask)
			var/obj/item/clothing/W = target.wear_mask
			if(target.dropItemToGround(W))
				target.visible_message(span_danger("[capitalize(src.name)] tears [W] off of [target] face!") , \
									span_userdanger("[capitalize(src.name)] tears [W] off of your face!"))
		target.equip_to_slot_if_possible(src, ITEM_SLOT_MASK, 0, 1, 1)
	return TRUE // time for a smoke

/obj/item/clothing/mask/facehugger/proc/Attach(mob/living/M)
	if(!valid_to_attach(M))
		return
	// early returns and validity checks done: attach.
	attached++
	//ensure we detach once we no longer need to be attached
	addtimer(CALLBACK(src, PROC_REF(detach)), MAX_IMPREGNATION_TIME)


	if(!sterile)
		M.take_bodypart_damage(strength,0) //done here so that humans in helmets take damage
		M.Unconscious(MAX_IMPREGNATION_TIME/0.3) //something like 25 ticks = 20 seconds with the default settings

	GoIdle() //so it doesn't jump the people that tear it off

	addtimer(CALLBACK(src, PROC_REF(Impregnate), M), rand(MIN_IMPREGNATION_TIME, MAX_IMPREGNATION_TIME))

/obj/item/clothing/mask/facehugger/proc/detach()
	attached = 0

/obj/item/clothing/mask/facehugger/proc/Impregnate(mob/living/target)
	if(!target || target.stat == DEAD) //was taken off or something
		return

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.wear_mask != src)
			return

	if(!sterile)
		target.visible_message(span_danger("[capitalize(src.name)] falls limp after violating [target] face!") , \
								span_userdanger("[capitalize(src.name)] falls limp after violating your face!"))

		Die()
		icon_state = "[initial(icon_state)]_impregnated"

		var/obj/item/bodypart/chest/LC = target.get_bodypart(BODY_ZONE_CHEST)
		if((!LC || LC.status != BODYPART_ROBOTIC) && !target.getorgan(/obj/item/organ/body_egg/alien_embryo))
			new /obj/item/organ/body_egg/alien_embryo(target)
			var/turf/T = get_turf(target)
			log_game("[key_name(target)] was impregnated by a facehugger at [loc_name(T)]")

	else
		target.visible_message(span_danger("[capitalize(src.name)] violates [target] face!") , \
								span_userdanger("[capitalize(src.name)] violates your face!"))

/obj/item/clothing/mask/facehugger/proc/GoActive()
	if(stat == DEAD || stat == CONSCIOUS)
		return

	stat = CONSCIOUS
	icon_state = "[initial(icon_state)]"

/obj/item/clothing/mask/facehugger/proc/GoIdle()
	if(stat == DEAD || stat == UNCONSCIOUS)
		return

	stat = UNCONSCIOUS
	icon_state = "[initial(icon_state)]_inactive"

	addtimer(CALLBACK(src, PROC_REF(GoActive)), rand(MIN_ACTIVE_TIME, MAX_ACTIVE_TIME))

/obj/item/clothing/mask/facehugger/proc/Die()
	if(stat == DEAD)
		return

	icon_state = "[initial(icon_state)]_dead"
	inhand_icon_state = "facehugger_inactive"
	stat = DEAD

	visible_message(span_danger("[capitalize(src.name)] curls up into a ball!"))

/proc/CanHug(mob/living/M)
	if(!istype(M))
		return FALSE
	if(M.stat == DEAD)
		return FALSE
	if(M.getorgan(/obj/item/organ/alien/hivenode))
		return FALSE
	var/mob/living/carbon/C = M
	if(ishuman(C) && !(ITEM_SLOT_MASK in C.dna.species.no_equip))
		var/mob/living/carbon/human/H = C
		if(H.is_mouth_covered(head_only = 1))
			return FALSE
		return TRUE
	return FALSE

/obj/item/clothing/mask/facehugger/lamarr
	name = "Lamarr"
	desc = "The Research Director's pet, a domesticated and debeaked xenomorph facehugger. Friendly, but may still try to couple with your head."
	sterile = TRUE

/obj/item/clothing/mask/facehugger/dead
	icon_state = "facehugger_dead"
	inhand_icon_state = "facehugger_inactive"
	worn_icon_state = "facehugger_dead"
	stat = DEAD

/obj/item/clothing/mask/facehugger/impregnated
	icon_state = "facehugger_impregnated"
	inhand_icon_state = "facehugger_impregnated"
	worn_icon_state = "facehugger_impregnated"
	stat = DEAD

/obj/item/clothing/mask/facehugger/toy
	inhand_icon_state = "facehugger_inactive"
	desc = "A toy often used to play pranks on other miners by putting it in their beds. It takes a bit to recharge after latching onto something."
	real = FALSE
	sterile = TRUE
	tint = 3 //Makes it feel more authentic when it latches on

/obj/item/clothing/mask/facehugger/toy/Die()
	return

#undef MIN_ACTIVE_TIME
#undef MAX_ACTIVE_TIME

#undef MIN_IMPREGNATION_TIME
#undef MAX_IMPREGNATION_TIME
