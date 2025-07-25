#define DRAKE_SWOOP_HEIGHT 270 //how high up drakes go, in pixels
#define DRAKE_SWOOP_DIRECTION_CHANGE_RANGE 5 //the range our x has to be within to not change the direction we slam from

#define SWOOP_DAMAGEABLE 1
#define SWOOP_INVULNERABLE 2

///used whenever the drake generates a hotspot
#define DRAKE_FIRE_TEMP 500
///used whenever the drake generates a hotspot
#define DRAKE_FIRE_EXPOSURE 50

/*£
 *
 *ASH DRAKE
 *
 *Ash drakes spawn randomly wherever a lavaland creature is able to spawn. They are the draconic guardians of the Necropolis.
 *
 *It acts as a melee creature, chasing down and attacking its target while also using different attacks to augment its power that increase as it takes damage.
 *
 *Whenever possible, the drake will breathe fire directly at it's target, igniting and heavily damaging anything caught in the blast.
 *It also often causes lava to pool from the ground around you - many nearby turfs will temporarily turn into lava, dealing damage to anything on the turfs.
 *The drake also utilizes its wings to fly into the sky, flying after its target and attempting to slam down on them. Anything near when it slams down takes huge damage.
 *Sometimes it will chain these swooping attacks over and over, making swiftness a necessity.
 *Sometimes, it will encase its target in an arena of lava
 *
 *When an ash drake dies, it leaves behind a chest that can contain four things:
 *A. A spectral blade that allows its wielder to call ghosts to it, enhancing its power
 *B. A lava staff that allows its wielder to create lava
 *C. A spellbook and wand of fireballs
 *D. A bottle of dragon's blood with several effects, including turning its imbiber into a drake themselves.
 *
 *When butchered, they leave behind diamonds, sinew, bone, and ash drake hide. Ash drake hide can be used to create a hooded cloak that protects its wearer from ash storms.
 *
 *Intended Difficulty: Medium
 */

/mob/living/simple_animal/hostile/megafauna/dragon
	name = "Пепельный дракон"
	desc = "Один из стражей Некрополя."
	health = 2500
	maxHealth = 2500
	attack_verb_continuous = "грызёт"
	attack_verb_simple = "грызёт"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	icon = 'icons/mob/lavaland/64x64megafauna.dmi'
	icon_state = "dragon"
	icon_living = "dragon"
	icon_dead = "dragon_dead"
	health_doll_icon = "dragon"
	friendly_verb_continuous = "гениально смотрит на"
	friendly_verb_simple = "гениально смотрит на"
	speak_emote = list("рычит")
	armour_penetration = 40
	melee_damage_lower = 40
	melee_damage_upper = 40
	speed = 5
	move_to_delay = 5
	ranged = TRUE
	pixel_x = -16
	base_pixel_x = -16
	crusher_loot = list(/obj/structure/closet/crate/necropolis/dragon/crusher)
	loot = list(/obj/structure/closet/crate/necropolis/dragon)
	butcher_results = list(/obj/item/stack/ore/diamond = 5, /obj/item/stack/sheet/sinew = 5, /obj/item/stack/sheet/bone = 30)
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/ashdrake = 10)
	var/swooping = NONE
	var/player_cooldown = 0
	gps_name = "Огненный Сигнал"
	achievement_type = /datum/award/achievement/boss/drake_kill
	crusher_achievement_type = /datum/award/achievement/boss/drake_crusher
	score_achievement_type = /datum/award/score/drake_score
	deathmessage = "рушится в груду костей, его плоть расслаивается."
	deathsound = 'sound/magic/demon_dies.ogg'
	footstep_type = FOOTSTEP_MOB_HEAVY
	attack_action_types = list(/datum/action/innate/megafauna_attack/fire_cone,
							   /datum/action/innate/megafauna_attack/fire_cone_meteors,
							   /datum/action/innate/megafauna_attack/mass_fire,
							   /datum/action/innate/megafauna_attack/lava_swoop)
	small_sprite_type = /datum/action/small_sprite/megafauna/drake

/datum/action/innate/megafauna_attack/fire_cone
	name = "Огненный конус"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = "fireball"
	chosen_message = span_colossus("Буду дышать огнём на жертву.")
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/fire_cone_meteors
	name = "Огненный конус с метеорами"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("Буду дышать огнём на жертву призывать падающие метеоры вокруг.")
	chosen_attack_num = 2

/datum/action/innate/megafauna_attack/mass_fire
	name = "Массовая огненная атака"
	icon_icon = 'icons/effects/fire.dmi'
	button_icon_state = "1"
	chosen_message = span_colossus("Буду стрелять массовым сожжением, жаль только без газа.")
	chosen_attack_num = 3

/datum/action/innate/megafauna_attack/lava_swoop
	name = "Лавовый угар"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "lavastaff_warn"
	chosen_message = span_colossus("Буду создавать лаву пока жертва пытается убежать от меня.")
	chosen_attack_num = 4

/mob/living/simple_animal/hostile/megafauna/dragon/OpenFire()
	if(swooping)
		return

	anger_modifier = clamp(((maxHealth - health)/50),0,20)
	update_cooldowns(list(COOLDOWN_UPDATE_SET_RANGED = ranged_cooldown_time), ignore_staggered = TRUE)

	if(client)
		switch(chosen_attack)
			if(1)
				fire_cone(meteors = FALSE)
			if(2)
				fire_cone()
			if(3)
				mass_fire()
			if(4)
				lava_swoop()
		return

	if(prob(15 + anger_modifier))
		lava_swoop()

	else if(prob(10+anger_modifier))
		shoot_fire_attack()
	else
		fire_cone()

/mob/living/simple_animal/hostile/megafauna/dragon/proc/shoot_fire_attack()
	if(health < maxHealth*0.5)
		mass_fire()
	else
		fire_cone()

/mob/living/simple_animal/hostile/megafauna/dragon/proc/fire_rain()
	if(!target)
		return
	target.visible_message(span_boldwarning("Огненный дождь опускается с неба!"))
	for(var/turf/turf in range(9,get_turf(target)))
		if(prob(11))
			new /obj/effect/temp_visual/target(turf)

/mob/living/simple_animal/hostile/megafauna/dragon/proc/lava_pools(amount, delay = 0.8)
	if(!target)
		return
	target.visible_message(span_boldwarning("Лава начинает кучковаться вокруг меня!"))

	while(amount > 0)
		if(QDELETED(target))
			break
		var/turf/TT = get_turf(target)
		var/turf/T = pick(RANGE_TURFS(1,TT))
		new /obj/effect/temp_visual/lava_warning(T, 60) // longer reset time for the lava
		amount--
		SLEEP_CHECK_DEATH(delay)

/mob/living/simple_animal/hostile/megafauna/dragon/proc/lava_swoop(amount = 30)
	if(health < maxHealth * 0.5)
		return swoop_attack(lava_arena = TRUE, swoop_cooldown = 6 SECONDS)
	INVOKE_ASYNC(src, PROC_REF(lava_pools), amount)
	swoop_attack(FALSE, target, 1000) // longer cooldown until it gets reset below
	SLEEP_CHECK_DEATH(0)
	fire_cone()
	if(health < maxHealth*0.5)
		SLEEP_CHECK_DEATH(10)
		fire_cone()
		SLEEP_CHECK_DEATH(10)
		fire_cone()
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 4 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 4 SECONDS))

/mob/living/simple_animal/hostile/megafauna/dragon/proc/mass_fire(spiral_count = 12, range = 15, times = 3)
	SLEEP_CHECK_DEATH(0)
	for(var/i = 1 to times)
		update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 5 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 5 SECONDS))
		playsound(get_turf(src),'sound/magic/fireball.ogg', 200, TRUE)
		var/increment = 360 / spiral_count
		for(var/j = 1 to spiral_count)
			var/list/turfs = line_target(j * increment + i * increment / 2, range, src)
			INVOKE_ASYNC(src, PROC_REF(fire_line), turfs)
		SLEEP_CHECK_DEATH(25)
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 3 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 3 SECONDS))

/mob/living/simple_animal/hostile/megafauna/dragon/proc/lava_arena()
	if(!target)
		return
	target.visible_message(span_boldwarning("<b>[src]</b> заключает меня в огненную арену!"))
	var/amount = 3
	var/turf/center = get_turf(target)
	var/list/walled = RANGE_TURFS(3, center) - RANGE_TURFS(2, center)
	var/list/drakewalls = list()
	for(var/turf/T in walled)
		drakewalls += new /obj/effect/temp_visual/drakewall(T) // no people with lava immunity can just run away from the attack for free
	var/list/indestructible_turfs = list()
	for(var/turf/T in RANGE_TURFS(2, center))
		if(istype(T, /turf/open/indestructible))
			continue
		if(!istype(T, /turf/closed/indestructible))
			T.ChangeTurf(/turf/open/floor/plating/asteroid/basalt/lava_land_surface, flags = CHANGETURF_INHERIT_AIR)
		else
			indestructible_turfs += T
	SLEEP_CHECK_DEATH(10) // give them a bit of time to realize what attack is actually happening

	var/list/turfs = RANGE_TURFS(2, center)
	var/list/mobs_with_clients = list()
	while(amount > 0)
		var/list/empty = indestructible_turfs.Copy() // can't place safe turfs on turfs that weren't changed to be open
		var/any_attack = FALSE
		for(var/turf/T in turfs)
			for(var/mob/living/L in T.contents)
				if(L.client)
					empty += pick(((RANGE_TURFS(2, L) - RANGE_TURFS(1, L)) & turfs) - empty) // picks a turf within 2 of the creature not outside or in the shield
					any_attack = TRUE
					mobs_with_clients |= L
			for(var/obj/vehicle/sealed/mecha/M in T.contents)
				empty += pick(((RANGE_TURFS(2, M) - RANGE_TURFS(1, M)) & turfs) - empty)
				any_attack = TRUE
		if(!any_attack) // nothing to attack in the arena, time for enraged attack if we still have a cliented target.
			for(var/obj/effect/temp_visual/drakewall/D in drakewalls)
				qdel(D)
			for(var/a in mobs_with_clients)
				var/mob/living/L = a
				if(!QDELETED(L) && L.client)
					return FALSE
			return TRUE
		for(var/turf/T in turfs)
			if(!(T in empty))
				new /obj/effect/temp_visual/lava_warning(T)
			else if(!istype(T, /turf/closed/indestructible))
				new /obj/effect/temp_visual/lava_safe(T)
		amount--
		SLEEP_CHECK_DEATH(24)
	return TRUE // attack finished completely

/mob/living/simple_animal/hostile/megafauna/dragon/proc/arena_escape_enrage() // you ran somehow / teleported away from my arena attack now i'm mad fucker
	SLEEP_CHECK_DEATH(0)
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = 8 SECONDS, COOLDOWN_UPDATE_SET_RANGED = 8 SECONDS))
	visible_message(span_boldwarning("[src] starts to glow vibrantly as its wounds close up!"))
	adjustBruteLoss(-250) // yeah you're gonna pay for that, don't run nerd
	add_atom_colour(rgb(255, 255, 0), TEMPORARY_COLOUR_PRIORITY)
	move_to_delay = move_to_delay / 2
	set_light_range(10)
	SLEEP_CHECK_DEATH(10) // run.
	mass_fire(20, 15, 3)
	move_to_delay = initial(move_to_delay)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	set_light_range(initial(light_range))

/mob/living/simple_animal/hostile/megafauna/dragon/proc/fire_cone(atom/at = target, meteors = TRUE)
	playsound(get_turf(src),'sound/magic/fireball.ogg', 200, TRUE)
	SLEEP_CHECK_DEATH(0)
	if(prob(50) && meteors)
		INVOKE_ASYNC(src, PROC_REF(fire_rain))
	var/range = 15
	var/list/turfs = list()
	turfs = line_target(-40, range, at)
	INVOKE_ASYNC(src, PROC_REF(fire_line), turfs)
	turfs = line_target(0, range, at)
	INVOKE_ASYNC(src, PROC_REF(fire_line), turfs)
	turfs = line_target(40, range, at)
	INVOKE_ASYNC(src, PROC_REF(fire_line), turfs)

/mob/living/simple_animal/hostile/megafauna/dragon/proc/line_target(offset, range, atom/at = target)
	if(!at)
		return
	var/turf/T = get_ranged_target_turf_direct(src, at, range, offset)
	return (get_line(src, T) - get_turf(src))

/mob/living/simple_animal/hostile/megafauna/dragon/proc/fire_line(list/turfs)
	SLEEP_CHECK_DEATH(0)
	dragon_fire_line(src, turfs)

//fire line keeps going even if dragon is deleted
/proc/dragon_fire_line(atom/source, list/turfs)
	var/list/hit_list = list()
	for(var/turf/T in turfs)
		if(istype(T, /turf/closed))
			break
		new /obj/effect/hotspot(T)
		T.hotspot_expose(DRAKE_FIRE_TEMP,DRAKE_FIRE_EXPOSURE,1)
		for(var/mob/living/L in T.contents)
			if(L in hit_list || istype(L, source.type))
				continue
			hit_list += L
			L.adjustFireLoss(20)
			to_chat(L, span_userdanger("В меня попадает волна огня исходящая от <b>дракона</b>!"))

		// deals damage to mechs
		for(var/obj/vehicle/sealed/mecha/M in T.contents)
			if(M in hit_list)
				continue
			hit_list += M
			M.take_damage(45, BRUTE, MELEE, 1)
		sleep(1.5)

/mob/living/simple_animal/hostile/megafauna/dragon/proc/swoop_attack(lava_arena = FALSE, atom/movable/manual_target, swoop_cooldown = 30)
	if(stat || swooping)
		return
	if(manual_target)
		target = manual_target
	if(!target)
		return
	stop_automated_movement = TRUE
	swooping |= SWOOP_DAMAGEABLE
	set_density(FALSE)
	icon_state = "shadow"
	visible_message(span_boldwarning("<b>[src]</b> высоко взлетает!"))

	var/negative
	var/initial_x = x
	if(target.x < initial_x) //if the target's x is lower than ours, swoop to the left
		negative = TRUE
	else if(target.x > initial_x)
		negative = FALSE
	else if(target.x == initial_x) //if their x is the same, pick a direction
		negative = prob(50)
	var/obj/effect/temp_visual/dragon_flight/F = new /obj/effect/temp_visual/dragon_flight(loc, negative)

	negative = !negative //invert it for the swoop down later

	var/oldtransform = transform
	alpha = 255
	animate(src, alpha = 204, transform = matrix()*0.9, time = 3, easing = BOUNCE_EASING)
	for(var/i in 1 to 3)
		sleep(1)
		if(QDELETED(src) || stat == DEAD) //we got hit and died, rip us
			qdel(F)
			if(stat == DEAD)
				swooping &= ~SWOOP_DAMAGEABLE
				animate(src, alpha = 255, transform = oldtransform, time = 0, flags = ANIMATION_END_NOW) //reset immediately
			return
	animate(src, alpha = 100, transform = matrix()*0.7, time = 7)
	swooping |= SWOOP_INVULNERABLE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	SLEEP_CHECK_DEATH(7)

	while(target && loc != get_turf(target))
		forceMove(get_step(src, get_dir(src, target)))
		SLEEP_CHECK_DEATH(0.5)

	// Ash drake flies onto its target and rains fire down upon them
	var/descentTime = 10
	var/lava_success = TRUE
	if(lava_arena)
		lava_success = lava_arena()


	//ensure swoop direction continuity.
	if(negative)
		if(ISINRANGE(x, initial_x + 1, initial_x + DRAKE_SWOOP_DIRECTION_CHANGE_RANGE))
			negative = FALSE
	else
		if(ISINRANGE(x, initial_x - DRAKE_SWOOP_DIRECTION_CHANGE_RANGE, initial_x - 1))
			negative = TRUE
	new /obj/effect/temp_visual/dragon_flight/end(loc, negative)
	new /obj/effect/temp_visual/dragon_swoop(loc)
	animate(src, alpha = 255, transform = oldtransform, descentTime)
	SLEEP_CHECK_DEATH(descentTime)
	swooping &= ~SWOOP_INVULNERABLE
	mouse_opacity = initial(mouse_opacity)
	icon_state = "dragon"
	playsound(loc, 'sound/effects/meteorimpact.ogg', 200, TRUE)
	for(var/mob/living/L in orange(1, src))
		if(L.stat)
			visible_message(span_warning("<b>[src]</b> приземляется на <b>[L]</b>, раздавливая [L.ru_ego()]!"))
			L.gib()
		else
			L.adjustBruteLoss(75)
			if(L && !QDELETED(L)) // Some mobs are deleted on death
				var/throw_dir = get_dir(src, L)
				if(L.loc == loc)
					throw_dir = pick(GLOB.alldirs)
				var/throwtarget = get_edge_target_turf(src, throw_dir)
				L.throw_at(throwtarget, 3)
				visible_message(span_warning("<b>[L]</b> вылетает из под <b>дракона</b>!"))
	for(var/obj/vehicle/sealed/mecha/M in orange(1, src))
		M.take_damage(75, BRUTE, MELEE, 1)

	for(var/mob/M in range(7, src))
		shake_camera(M, 15, 1)

	set_density(TRUE)
	SLEEP_CHECK_DEATH(1)
	swooping &= ~SWOOP_DAMAGEABLE
	update_cooldowns(list(COOLDOWN_UPDATE_SET_MELEE = swoop_cooldown, COOLDOWN_UPDATE_SET_RANGED = swoop_cooldown))
	if(!lava_success)
		arena_escape_enrage()

/mob/living/simple_animal/hostile/megafauna/dragon/ex_act(severity, target)
	if(severity == EXPLODE_LIGHT)
		return
	..()

/mob/living/simple_animal/hostile/megafauna/dragon/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (swooping & SWOOP_INVULNERABLE))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/megafauna/dragon/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, visible_message_flags = NONE)
	if(swooping & SWOOP_INVULNERABLE) //to suppress attack messages without overriding every single proc that could send a message saying we got hit
		return
	return ..()

/mob/living/simple_animal/hostile/megafauna/dragon/AttackingTarget()
	if(!swooping)
		return ..()

/mob/living/simple_animal/hostile/megafauna/dragon/DestroySurroundings()
	if(!swooping)
		..()

/mob/living/simple_animal/hostile/megafauna/dragon/Move()
	if(!swooping)
		..()

/mob/living/simple_animal/hostile/megafauna/dragon/Goto(target, delay, minimum_distance)
	if(!swooping)
		..()

/obj/effect/temp_visual/lava_warning
	icon_state = "lavastaff_warn"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	light_range = 2
	duration = 13

/obj/effect/temp_visual/lava_warning/Initialize(mapload, reset_time = 10)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(fall), reset_time)
	src.alpha = 63.75
	animate(src, alpha = 255, time = duration)

/obj/effect/temp_visual/lava_warning/proc/fall(reset_time)
	var/turf/T = get_turf(src)
	playsound(T,'sound/magic/fleshtostone.ogg', 80, TRUE)
	sleep(duration)
	playsound(T,'sound/magic/fireball.ogg', 200, TRUE)

	for(var/mob/living/L in T.contents)
		if(istype(L, /mob/living/simple_animal/hostile/megafauna/dragon))
			continue
		L.adjustFireLoss(10)
		to_chat(L, span_userdanger("Падаю прямо в лужу лавы!"))

	// deals damage to mechs
	for(var/obj/vehicle/sealed/mecha/M in T.contents)
		M.take_damage(45, BRUTE, MELEE, 1)

	// changes turf to lava temporarily
	if(!istype(T, /turf/closed) && !istype(T, /turf/open/lava))
		var/lava_turf = /turf/open/lava/smooth
		var/reset_turf = T.type
		T.ChangeTurf(lava_turf, flags = CHANGETURF_INHERIT_AIR)
		addtimer(CALLBACK(T, TYPE_PROC_REF(/turf, ChangeTurf), reset_turf, null, CHANGETURF_INHERIT_AIR), reset_time, TIMER_OVERRIDE|TIMER_UNIQUE)

/obj/effect/temp_visual/drakewall
	desc = "Пепел истощает настоящее пламя."
	name = "Огненный барьер"
	icon = 'icons/effects/fire.dmi'
	icon_state = "1"
	anchored = TRUE
	opacity = FALSE
	density = TRUE
	CanAtmosPass = ATMOS_PASS_DENSITY
	duration = 82
	color = COLOR_DARK_ORANGE

/obj/effect/temp_visual/lava_safe
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "trap-earth"
	layer = BELOW_MOB_LAYER
	light_range = 2
	duration = 13

/obj/effect/temp_visual/dragon_swoop
	name = "верная смерть"
	desc = "Не стой тут, двигайся!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "landing"
	layer = BELOW_MOB_LAYER
	pixel_x = -32
	pixel_y = -32
	color = "#FF0000"
	duration = 10

/obj/effect/temp_visual/dragon_flight
	icon = 'icons/mob/lavaland/64x64megafauna.dmi'
	icon_state = "dragon"
	layer = ABOVE_ALL_MOB_LAYER
	pixel_x = -16
	duration = 10
	randomdir = FALSE

/obj/effect/temp_visual/dragon_flight/Initialize(mapload, negative)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(flight), negative)

/obj/effect/temp_visual/dragon_flight/proc/flight(negative)
	if(negative)
		animate(src, pixel_x = -DRAKE_SWOOP_HEIGHT*0.1, pixel_z = DRAKE_SWOOP_HEIGHT*0.15, time = 3, easing = BOUNCE_EASING)
	else
		animate(src, pixel_x = DRAKE_SWOOP_HEIGHT*0.1, pixel_z = DRAKE_SWOOP_HEIGHT*0.15, time = 3, easing = BOUNCE_EASING)
	sleep(3)
	icon_state = "swoop"
	if(negative)
		animate(src, pixel_x = -DRAKE_SWOOP_HEIGHT, pixel_z = DRAKE_SWOOP_HEIGHT, time = 7)
	else
		animate(src, pixel_x = DRAKE_SWOOP_HEIGHT, pixel_z = DRAKE_SWOOP_HEIGHT, time = 7)

/obj/effect/temp_visual/dragon_flight/end
	pixel_x = DRAKE_SWOOP_HEIGHT
	pixel_z = DRAKE_SWOOP_HEIGHT
	duration = 10

/obj/effect/temp_visual/dragon_flight/end/flight(negative)
	if(negative)
		pixel_x = -DRAKE_SWOOP_HEIGHT
		animate(src, pixel_x = -16, pixel_z = 0, time = 5)
	else
		animate(src, pixel_x = -16, pixel_z = 0, time = 5)

/obj/effect/temp_visual/fireball
	icon = 'icons/obj/wizard.dmi'
	icon_state = "fireball"
	name = "огненный шар"
	desc = "Ты ебанутый?"
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	randomdir = FALSE
	duration = 9
	pixel_z = 270

/obj/effect/temp_visual/fireball/Initialize()
	. = ..()
	animate(src, pixel_z = 0, time = duration)

/obj/effect/temp_visual/target
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	light_range = 2
	duration = 9

/obj/effect/temp_visual/target/Initialize(mapload, list/flame_hit)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(fall), flame_hit)

/obj/effect/temp_visual/target/proc/fall(list/flame_hit)
	var/turf/T = get_turf(src)
	playsound(T,'sound/magic/fleshtostone.ogg', 80, TRUE)
	new /obj/effect/temp_visual/fireball(T)
	sleep(duration)
	if(ismineralturf(T))
		var/turf/closed/mineral/M = T
		M.gets_drilled()
	playsound(T, "explosion", 80, TRUE)
	new /obj/effect/hotspot(T)
	T.hotspot_expose(DRAKE_FIRE_TEMP, DRAKE_FIRE_EXPOSURE, 1)
	for(var/mob/living/L in T.contents)
		if(istype(L, /mob/living/simple_animal/hostile/megafauna/dragon))
			continue
		if(islist(flame_hit) && !flame_hit[L])
			L.adjustFireLoss(40)
			to_chat(L, span_userdanger("В меня попадает волна огня исходящая от <b>дракона</b>!"))
			flame_hit[L] = TRUE
		else
			L.adjustFireLoss(10) //if we've already hit them, do way less damage

/mob/living/simple_animal/hostile/megafauna/dragon/lesser
	name = "Младший пепельный дракон"
	maxHealth = 200
	health = 200
	faction = list("neutral")
	obj_damage = 80
	melee_damage_upper = 30
	melee_damage_lower = 30
	mouse_opacity = MOUSE_OPACITY_ICON
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	loot = list()
	crusher_loot = list()
	butcher_results = list(/obj/item/stack/ore/diamond = 5, /obj/item/stack/sheet/sinew = 5, /obj/item/stack/sheet/bone = 30)
	attack_action_types = list()

/mob/living/simple_animal/hostile/megafauna/dragon/lesser/AltClickOn(atom/movable/A)
	if(!istype(A))
		return
	if(player_cooldown >= world.time)
		to_chat(src, span_warning("Хочу подождать [(player_cooldown - world.time) / 10] секунд перед прыжком!"))
		return
	swoop_attack(FALSE, A)
	lava_pools(10, 2) // less pools but longer delay before spawns
	player_cooldown = world.time + 20 SECONDS // needs seperate cooldown or cant use fire attacks

/mob/living/simple_animal/hostile/megafauna/dragon/lesser/grant_achievement(medaltype,scoretype)
	return
