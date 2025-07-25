#define BUBBLEGUM_SMASH (health <= maxHealth*0.5) // angery
#define BUBBLEGUM_CAN_ENRAGE (enrage_till + (enrage_time * 2) <= world.time)
#define BUBBLEGUM_IS_ENRAGED (enrage_till > world.time)

/*

BUBBLEGUM

Bubblegum spawns randomly wherever a lavaland creature is able to spawn. It is the most powerful slaughter demon in existence.
Bubblegum's footsteps are heralded by shaking booms, proving its tremendous size.

It acts as a melee creature, chasing down and attacking its target while also using different attacks to augment its power

It leaves blood trails behind wherever it goes, its clones do as well.
It tries to strike at its target through any bloodpools under them; if it fails to do that.
If it does warp it will enter an enraged state, becoming immune to all projectiles, becoming much faster, and dealing damage and knockback to anything that gets in the cloud around it.
It may summon clones charging from all sides, one of these charges being bubblegum himself.
It can charge at its target, and also heavily damaging anything directly hit in the charge.
If at half health it will start to charge from all sides with clones.

When Bubblegum dies, it leaves behind a H.E.C.K. mining suit as well as a chest that can contain three things:
A. A bottle that, when activated, drives everyone nearby into a frenzy
B. A contract that marks for death the chosen target
C. A spellblade that can slice off limbs at range

Difficulty: Hard

*/

/mob/living/simple_animal/hostile/megafauna/bubblegum
	name = "bubblegum"
	desc = "In what passes for a hierarchy among slaughter demons, this one is king."
	health = 2500
	maxHealth = 2500
	attack_verb_continuous = "уничтожает"
	attack_verb_simple = "уничтожает"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	icon_state = "bubblegum"
	icon_living = "bubblegum"
	icon_dead = ""
	health_doll_icon = "bubblegum"
	friendly_verb_continuous = "stares down"
	friendly_verb_simple = "stare down"
	icon = 'icons/mob/lavaland/96x96megafauna.dmi'
	speak_emote = list("булькает")
	armour_penetration = 40
	melee_damage_lower = 40
	melee_damage_upper = 40
	speed = 5
	move_to_delay = 5
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 8 // every 1/4 second
	melee_queue_distance = 20 // as far as possible really, need this because of blood warp
	ranged = TRUE
	pixel_x = -32
	base_pixel_x = -32
	del_on_death = TRUE
	crusher_loot = list(/obj/structure/closet/crate/necropolis/bubblegum/crusher)
	loot = list(/obj/structure/closet/crate/necropolis/bubblegum)
	blood_volume = BLOOD_VOLUME_MAXIMUM //BLEED FOR ME
	var/charging = FALSE
	var/enrage_till = 0
	var/enrage_time = 7 SECONDS
	var/revving_charge = FALSE
	gps_name = "Bloody Signal"
	achievement_type = /datum/award/achievement/boss/bubblegum_kill
	crusher_achievement_type = /datum/award/achievement/boss/bubblegum_crusher
	score_achievement_type = /datum/award/score/bubblegum_score

	deathmessage = "sinks into a pool of blood, fleeing the battle. You've won, for now... "
	deathsound = 'sound/magic/enter_blood.ogg'
	attack_action_types = list(/datum/action/innate/megafauna_attack/triple_charge,
							   /datum/action/innate/megafauna_attack/hallucination_charge,
							   /datum/action/innate/megafauna_attack/hallucination_surround,
							   /datum/action/innate/megafauna_attack/blood_warp)
	small_sprite_type = /datum/action/small_sprite/megafauna/bubblegum
	faction = list("mining", "boss", "hell")

/datum/action/innate/megafauna_attack/triple_charge
	name = "Triple Charge"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("You are now triple charging at the target you click on.")
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/hallucination_charge
	name = "Hallucination Charge"
	icon_icon = 'icons/effects/bubblegum.dmi'
	button_icon_state = "smack ya one"
	chosen_message = span_colossus("You are now charging with hallucinations at the target you click on.")
	chosen_attack_num = 2

/datum/action/innate/megafauna_attack/hallucination_surround
	name = "Surround Target"
	icon_icon = 'icons/turf/walls/baywall.dmi'
	button_icon_state = "wall-0"
	chosen_message = span_colossus("You are now surrounding the target you click on with hallucinations.")
	chosen_attack_num = 3

/datum/action/innate/megafauna_attack/blood_warp
	name = "Blood Warp"
	icon_icon = 'icons/effects/blood.dmi'
	button_icon_state = "floor1"
	chosen_message = span_colossus("You are now warping to blood around your clicked position.")
	chosen_attack_num = 4

/mob/living/simple_animal/hostile/megafauna/bubblegum/update_cooldowns(list/cooldown_updates, ignore_staggered = FALSE)
	. = ..()
	if(cooldown_updates[COOLDOWN_UPDATE_SET_ENRAGE])
		enrage_till = world.time + cooldown_updates[COOLDOWN_UPDATE_SET_ENRAGE]
	if(cooldown_updates[COOLDOWN_UPDATE_ADD_ENRAGE])
		enrage_till += cooldown_updates[COOLDOWN_UPDATE_ADD_ENRAGE]

/mob/living/simple_animal/hostile/megafauna/bubblegum/OpenFire()
	if(charging)
		return

	anger_modifier = clamp(((maxHealth - health)/60),0,20)
	enrage_time = initial(enrage_time) * clamp(anger_modifier / 20, 0.5, 1)
	update_cooldowns(list(COOLDOWN_UPDATE_ADD_RANGED = 5 SECONDS))

	if(client)
		switch(chosen_attack)
			if(1)
				triple_charge()
			if(2)
				hallucination_charge()
			if(3)
				surround_with_hallucinations()
			if(4)
				blood_warp()
		return

	if(!try_bloodattack() || prob(25 + anger_modifier))
		blood_warp()

	if(!BUBBLEGUM_SMASH)
		triple_charge()
	else if(prob(50 + anger_modifier))
		hallucination_charge()
	else
		surround_with_hallucinations()

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/triple_charge()
	charge(delay = 6)
	charge(delay = 4)
	charge(delay = 2)
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 1.5 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 1.5 SECONDS))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/hallucination_charge()
	if(!BUBBLEGUM_SMASH || prob(33))
		hallucination_charge_around(times = 6, delay = 8)
		update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 1 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 1 SECONDS))
	else
		hallucination_charge_around(times = 4, delay = 9)
		hallucination_charge_around(times = 4, delay = 8)
		hallucination_charge_around(times = 4, delay = 7)
		triple_charge()
		update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 2 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 2 SECONDS))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/surround_with_hallucinations()
	for(var/i = 1 to 5)
		INVOKE_ASYNC(src, PROC_REF(hallucination_charge_around), 2, 8, 2, 0, 4)
		if(ismob(target))
			charge(delay = 6)
		else
			SLEEP_CHECK_DEATH(6)
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 2 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 2 SECONDS))


/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/charge(atom/chargeat = target, delay = 3, chargepast = 2)
	if(!chargeat)
		return
	var/chargeturf = get_turf(chargeat)
	if(!chargeturf)
		return
	var/dir = get_dir(src, chargeturf)
	var/turf/T = get_ranged_target_turf(chargeturf, dir, chargepast)
	if(!T)
		return
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(T)
	charging = TRUE
	revving_charge = TRUE
	DestroySurroundings()
	SSmove_manager.stop_looping(src)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 3)
	SLEEP_CHECK_DEATH(delay)
	revving_charge = FALSE
	var/movespeed = 0.7
	walk_towards(src, T, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, T) * movespeed)
	SSmove_manager.stop_looping(src) // cancel the movement
	try_bloodattack()
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_mobs_on_blood()
	var/list/targets = ListTargets()
	. = list()
	for(var/mob/living/L in targets)
		var/list/bloodpool = get_pools(get_turf(L), 0)
		if(bloodpool.len && (!faction_check_mob(L) || L.stat == DEAD))
			. += L

/**
 * Attack by override for bubblegum
 *
 * This is used to award the frenching achievement for hitting bubblegum with a tongue
 *
 * Arguments:
 * * obj/item/W the item hitting bubblegum
 * * mob/user The user of the item
 * * params, extra parameters
 */
/mob/living/simple_animal/hostile/megafauna/bubblegum/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(istype(W, /obj/item/organ/tongue))
		user.client?.give_award(/datum/award/achievement/misc/frenching, user)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/try_bloodattack()
	var/list/targets = get_mobs_on_blood()
	if(targets.len)
		INVOKE_ASYNC(src, PROC_REF(bloodattack), targets, prob(50))
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodattack(list/targets, handedness)
	var/mob/living/target_one = pick_n_take(targets)
	var/turf/target_one_turf = get_turf(target_one)
	var/mob/living/target_two
	if(targets.len)
		target_two = pick_n_take(targets)
		var/turf/target_two_turf = get_turf(target_two)
		if(target_two.stat != CONSCIOUS || prob(10))
			bloodgrab(target_two_turf, handedness)
		else
			bloodsmack(target_two_turf, handedness)

	if(target_one)
		var/list/pools = get_pools(get_turf(target_one), 0)
		if(pools.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, !handedness)
				else
					bloodsmack(target_one_turf, !handedness)

	if(!target_two && target_one)
		var/list/poolstwo = get_pools(get_turf(target_one), 0)
		if(poolstwo.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, handedness)
				else
					bloodsmack(target_one_turf, handedness)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodsmack(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_hands/rightsmack(T)
	else
		new /obj/effect/temp_visual/bubblegum_hands/leftsmack(T)
	SLEEP_CHECK_DEATH(4)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			to_chat(L, span_userdanger("[capitalize(src.name)] rends you!"))
			playsound(T, attack_sound, 100, TRUE, -1)
			var/limb_to_hit = L.get_bodypart(pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
			L.apply_damage(10, BRUTE, limb_to_hit, L.run_armor_check(limb_to_hit, MELEE, null, null, armour_penetration), wound_bonus = CANT_WOUND)
	SLEEP_CHECK_DEATH(3)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodgrab(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_hands/rightpaw(T)
		new /obj/effect/temp_visual/bubblegum_hands/rightthumb(T)
	else
		new /obj/effect/temp_visual/bubblegum_hands/leftpaw(T)
		new /obj/effect/temp_visual/bubblegum_hands/leftthumb(T)
	SLEEP_CHECK_DEATH(6)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			if(L.stat != CONSCIOUS)
				to_chat(L, span_userdanger("[capitalize(src.name)] drags you through the blood!"))
				playsound(T, 'sound/magic/enter_blood.ogg', 100, TRUE, -1)
				var/turf/targetturf = get_step(src, dir)
				L.forceMove(targetturf)
				playsound(targetturf, 'sound/magic/exit_blood.ogg', 100, TRUE, -1)
				addtimer(CALLBACK(src, PROC_REF(devour), L), 2)
	SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_warp()
	if(Adjacent(target))
		return FALSE
	var/list/can_jaunt = get_pools(get_turf(src), 1)
	if(!can_jaunt.len)
		return FALSE

	var/list/pools = get_pools(get_turf(target), 5)
	var/list/pools_to_remove = get_pools(get_turf(target), 4)
	pools -= pools_to_remove
	if(!pools.len)
		return FALSE

	var/obj/effect/temp_visual/decoy/DA = new /obj/effect/temp_visual/decoy(loc,src)
	DA.color = "#FF0000"
	var/oldtransform = DA.transform
	DA.transform = matrix()*2
	animate(DA, alpha = 255, color = initial(DA.color), transform = oldtransform, time = 3)
	SLEEP_CHECK_DEATH(3)
	qdel(DA)

	var/obj/effect/decal/cleanable/blood/found_bloodpool
	pools = get_pools(get_turf(target), 5)
	pools_to_remove = get_pools(get_turf(target), 4)
	pools -= pools_to_remove
	if(pools.len)
		shuffle_inplace(pools)
		found_bloodpool = pick(pools)
	if(found_bloodpool)
		visible_message(span_danger("[capitalize(src.name)] sinks into the blood..."))
		playsound(get_turf(src), 'sound/magic/enter_blood.ogg', 100, TRUE, -1)
		forceMove(get_turf(found_bloodpool))
		playsound(get_turf(src), 'sound/magic/exit_blood.ogg', 100, TRUE, -1)
		visible_message(span_danger("And springs back out!"))
		blood_enrage()
		return TRUE
	return FALSE


/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/be_aggressive()
	if(BUBBLEGUM_IS_ENRAGED)
		return TRUE
	return isliving(target) && HAS_TRAIT(target, TRAIT_INCAPACITATED)


/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_retreat_distance()
	return (be_aggressive() ? null : initial(retreat_distance))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_minimum_distance()
	return (be_aggressive() ? 1 : initial(minimum_distance))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/update_approach()
	retreat_distance = get_retreat_distance()
	minimum_distance = get_minimum_distance()

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_enrage()
	if(!BUBBLEGUM_CAN_ENRAGE)
		return FALSE
	update_cooldowns(list(COOLDOWN_UPDATE_SET_ENRAGE = enrage_time))
	update_approach()
	change_move_delay(3.75)
	add_atom_colour(COLOR_BUBBLEGUM_RED, TEMPORARY_COLOUR_PRIORITY)
	var/datum/callback/cb = CALLBACK(src, PROC_REF(blood_enrage_end))
	addtimer(cb, enrage_time)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_enrage_end()
	update_approach()
	change_move_delay()
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_BUBBLEGUM_RED)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/change_move_delay(newmove = initial(move_to_delay))
	move_to_delay = newmove
	set_varspeed(move_to_delay)
	handle_automated_action() // need to recheck movement otherwise move_to_delay won't update until the next checking aka will be wrong speed for a bit

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_pools(turf/T, range)
	. = list()
	for(var/obj/effect/decal/cleanable/nearby in view(T, range))
		if(nearby.can_bloodcrawl_in())
			. += nearby

/obj/effect/decal/cleanable/blood/bubblegum
	bloodiness = 0

/obj/effect/decal/cleanable/blood/bubblegum/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/hallucination_charge_around(times = 4, delay = 6, chargepast = 0, useoriginal = 1, radius)
	var/startingangle = rand(1, 360)
	if(!target)
		return
	var/turf/chargeat = get_turf(target)
	var/srcplaced = FALSE
	if(!radius)
		radius = times
	for(var/i = 1 to times)
		var/ang = (startingangle + 360/times * i)
		if(!chargeat)
			return
		var/turf/place = locate(chargeat.x + cos(ang) * radius, chargeat.y + sin(ang) * radius, chargeat.z)
		if(!place)
			continue
		if(!nest || nest && nest.parent && get_dist(nest.parent, place) <= nest_range)
			if(!srcplaced && useoriginal)
				forceMove(place)
				srcplaced = TRUE
				continue
		var/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/B = new /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination(src.loc)
		B.forceMove(place)
		INVOKE_ASYNC(B, PROC_REF(charge), chargeat, delay, chargepast)
	if(useoriginal)
		charge(chargeat, delay, chargepast)

/mob/living/simple_animal/hostile/megafauna/bubblegum/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(. > 0 && prob(25))
		var/obj/effect/decal/cleanable/blood/gibs/bubblegum/B = new /obj/effect/decal/cleanable/blood/gibs/bubblegum(loc)
		if(prob(40))
			step(B, pick(GLOB.cardinals))
		else
			B.setDir(pick(GLOB.cardinals))

/obj/effect/decal/cleanable/blood/gibs/bubblegum
	name = "thick blood"
	desc = "Thick, splattered blood."
	random_icon_states = list("gib3", "gib5", "gib6")
	bloodiness = 20

/obj/effect/decal/cleanable/blood/gibs/bubblegum/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/grant_achievement(medaltype,scoretype)
	. = ..()
	if(!(flags_1 & ADMIN_SPAWNED_1))
		SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_BUBBLEGUM] = TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/AttackingTarget()
	if(!charging)
		. = ..()
		if(.)
			update_cooldowns(list(COOLDOWN_UPDATE_ADD_MELEE = 2 SECONDS)) // can only attack melee once every 2 seconds but rapid_melee gives higher priority

/mob/living/simple_animal/hostile/megafauna/bubblegum/bullet_act(obj/projectile/P)
	if(BUBBLEGUM_IS_ENRAGED)
		visible_message(span_danger("[capitalize(src.name)] deflects the projectile; [ru_who()] can't be hit with ranged weapons while enraged!") , span_userdanger("You deflect the projectile!"))
		playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 300, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/ex_act(severity, target)
	if(severity >= EXPLODE_LIGHT)
		return
	severity = EXPLODE_LIGHT // puny mortals
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination))
		return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/MoveToTarget(list/possible_targets)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Move()
	update_approach()
	if(revving_charge)
		return FALSE
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Moved(atom/OldLoc, Dir, Forced = FALSE)
	if(Dir)
		new /obj/effect/decal/cleanable/blood/bubblegum(src.loc)
	if(charging)
		DestroySurroundings()
	playsound(src, 'sound/effects/meteorimpact.ogg', 200, TRUE, 2, TRUE)
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Bump(atom/A)
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			if(isobj(A))
				SSexplosions.med_mov_atom += A
			else
				SSexplosions.medturf += A
		DestroySurroundings()
		if(isliving(A))
			var/mob/living/L = A
			L.visible_message(span_danger("[capitalize(src.name)] slams into [L]!") , span_userdanger("[capitalize(src.name)] tramples you into the ground!"))
			src.forceMove(get_turf(L))
			L.apply_damage(istype(src, /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination) ? 15 : 30, BRUTE, wound_bonus = CANT_WOUND)
			playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, TRUE)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)
	..()

/obj/effect/temp_visual/dragon_swoop/bubblegum
	duration = 10

/obj/effect/temp_visual/bubblegum_hands
	icon = 'icons/effects/bubblegum.dmi'
	duration = 9

/obj/effect/temp_visual/bubblegum_hands/rightthumb
	icon_state = "rightthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/leftthumb
	icon_state = "leftthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/rightpaw
	icon_state = "rightpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_hands/leftpaw
	icon_state = "leftpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_hands/rightsmack
	icon_state = "rightsmack"

/obj/effect/temp_visual/bubblegum_hands/leftsmack
	icon_state = "leftsmack"

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination
	name = "bubblegum's hallucination"
	desc = "Is that really just a hallucination?"
	health = 1
	maxHealth = 1
	alpha = 127.5
	crusher_loot = null
	loot = null
	achievement_type = null
	crusher_achievement_type = null
	score_achievement_type = null
	deathmessage = "Explodes into a pool of blood!"
	deathsound = 'sound/effects/splat.ogg'
	true_spawn = FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Initialize()
	. = ..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/charge(atom/chargeat = target, delay = 3, chargepast = 2)
	..()
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Destroy()
	new /obj/effect/decal/cleanable/blood(get_turf(src))
	. = ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum)) // hallucinations should not be stopping bubblegum or eachother
		return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Life(delta_time = SSMOBS_DT, times_fired)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/OpenFire()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/AttackingTarget()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/try_bloodattack()
	return

/obj/effect/decal/cleanable/blood/bubblegum
	bloodiness = 0

/obj/effect/decal/cleanable/blood/bubblegum/can_bloodcrawl_in()
	return TRUE

/obj/effect/decal/cleanable/blood/gibs/bubblegum
	name = "thick blood"
	desc = "Thick, splattered blood."
	random_icon_states = list("gib3", "gib5", "gib6")
	bloodiness = 20

/obj/effect/decal/cleanable/blood/gibs/bubblegum/can_bloodcrawl_in()
	return TRUE

/obj/effect/temp_visual/dragon_swoop/bubblegum
	duration = 10

/obj/effect/temp_visual/bubblegum_hands
	icon = 'icons/effects/bubblegum.dmi'
	duration = 9

/obj/effect/temp_visual/bubblegum_hands/rightthumb
	icon_state = "rightthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/leftthumb
	icon_state = "leftthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/rightpaw
	icon_state = "rightpawgrab"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE

/obj/effect/temp_visual/bubblegum_hands/leftpaw
	icon_state = "leftpawgrab"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE

/obj/effect/temp_visual/bubblegum_hands/rightsmack
	icon_state = "rightsmack"

/obj/effect/temp_visual/bubblegum_hands/leftsmack
	icon_state = "leftsmack"
