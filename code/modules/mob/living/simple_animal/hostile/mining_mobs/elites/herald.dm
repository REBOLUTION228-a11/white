#define HERALD_TRISHOT 1
#define HERALD_DIRECTIONALSHOT 2
#define HERALD_TELESHOT 3
#define HERALD_MIRROR 4

/**
 * # Herald
 *
 * A slow-moving projectile user with a few tricks up it's sleeve.  Less unga-bunga than Colossus, with more cleverness in it's fighting style.
 * As it's health gets lower, the amount of projectiles fired per-attack increases.
 * It's attacks are as follows:
 * - Fires three projectiles in a given direction.
 * - Fires a spread in every cardinal and diagonal direction at once, then does it again after a bit.
 * - Shoots a single, golden bolt.  Wherever it lands, the herald will be teleported to the location.
 * - Spawns a mirror which reflects projectiles directly at the target.
 * Herald is a more concentrated variation of the Colossus fight, having less projectiles overall, but more focused attacks.
 */

/mob/living/simple_animal/hostile/asteroid/elite/herald
	name = "herald"
	desc = "A monstrous beast which fires deadly projectiles at threats and prey."
	icon_state = "herald"
	icon_living = "herald"
	icon_aggro = "herald"
	icon_dead = "herald_dying"
	icon_gib = "syndicate_gib"
	health_doll_icon = "herald"
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_verb_continuous = "задумывается в"
	attack_verb_simple = "задумывается в"
	attack_sound = 'sound/magic/clockwork/ratvar_attack.ogg'
	throw_message = "doesn't affect the purity of"
	speed = 2
	move_to_delay = 10
	mouse_opacity = MOUSE_OPACITY_ICON
	deathsound = 'sound/magic/demon_dies.ogg'
	deathmessage = "begins to shudder as it becomes transparent..."
	loot_drop = /obj/item/clothing/neck/cloak/herald_cloak

	can_talk = 1

	attack_action_types = list(/datum/action/innate/elite_attack/herald_trishot,
								/datum/action/innate/elite_attack/herald_directionalshot,
								/datum/action/innate/elite_attack/herald_teleshot,
								/datum/action/innate/elite_attack/herald_mirror)

	var/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/my_mirror = null
	var/is_mirror = FALSE

/mob/living/simple_animal/hostile/asteroid/elite/herald/death()
	. = ..()
	if(!is_mirror)
		addtimer(CALLBACK(src, PROC_REF(become_ghost)), 8)
	if(my_mirror != null)
		qdel(my_mirror)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/become_ghost()
	icon_state = "herald_ghost"

/mob/living/simple_animal/hostile/asteroid/elite/herald/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	. = ..()
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)

/datum/action/innate/elite_attack/herald_trishot
	name = "Triple Shot"
	button_icon_state = "herald_trishot"
	chosen_message = span_boldwarning("You are now firing three shots in your chosen direction.")
	chosen_attack_num = HERALD_TRISHOT

/datum/action/innate/elite_attack/herald_directionalshot
	name = "Circular Shot"
	button_icon_state = "herald_directionalshot"
	chosen_message = span_boldwarning("You are firing projectiles in all directions.")
	chosen_attack_num = HERALD_DIRECTIONALSHOT

/datum/action/innate/elite_attack/herald_teleshot
	name = "Teleport Shot"
	button_icon_state = "herald_teleshot"
	chosen_message = span_boldwarning("You will now fire a shot which teleports you where it lands.")
	chosen_attack_num = HERALD_TELESHOT

/datum/action/innate/elite_attack/herald_mirror
	name = "Summon Mirror"
	button_icon_state = "herald_mirror"
	chosen_message = span_boldwarning("You will spawn a mirror which duplicates your attacks.")
	chosen_attack_num = HERALD_MIRROR

/mob/living/simple_animal/hostile/asteroid/elite/herald/OpenFire()
	if(client)
		switch(chosen_attack)
			if(HERALD_TRISHOT)
				herald_trishot(target)
				if(my_mirror != null)
					my_mirror.herald_trishot(target)
			if(HERALD_DIRECTIONALSHOT)
				herald_directionalshot()
				if(my_mirror != null)
					my_mirror.herald_directionalshot()
			if(HERALD_TELESHOT)
				herald_teleshot(target)
				if(my_mirror != null)
					my_mirror.herald_teleshot(target)
			if(HERALD_MIRROR)
				herald_mirror()
		return
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(HERALD_TRISHOT)
			herald_trishot(target)
			if(my_mirror != null)
				my_mirror.herald_trishot(target)
		if(HERALD_DIRECTIONALSHOT)
			herald_directionalshot()
			if(my_mirror != null)
				my_mirror.herald_directionalshot()
		if(HERALD_TELESHOT)
			herald_teleshot(target)
			if(my_mirror != null)
				my_mirror.herald_teleshot(target)
		if(HERALD_MIRROR)
			herald_mirror()

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/shoot_projectile(turf/marker, set_angle, is_teleshot, is_trishot)
	var/turf/startloc = get_turf(src)
	var/obj/projectile/herald/H = null
	if(!is_teleshot)
		H = new /obj/projectile/herald(startloc)
	else
		H = new /obj/projectile/herald/teleshot(startloc)
	H.preparePixelProjectile(marker, startloc)
	H.firer = src
	if(target)
		H.original = target
	H.fire(set_angle)
	if(is_trishot)
		shoot_projectile(marker, set_angle + 15, FALSE, FALSE)
		shoot_projectile(marker, set_angle - 15, FALSE, FALSE)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/herald_trishot(target)
	ranged_cooldown = world.time + 30
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	var/target_turf = get_turf(target)
	var/angle_to_target = get_angle(src, target_turf)
	shoot_projectile(target_turf, angle_to_target, FALSE, TRUE)
	addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 2)
	addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 4)
	if(health < maxHealth * 0.5 && !is_mirror)
		playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 10)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 12)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 14)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/herald_circleshot(offset)
	var/static/list/directional_shot_angles = list(0, 45, 90, 135, 180, 225, 270, 315)
	for(var/i in directional_shot_angles)
		shoot_projectile(get_turf(src), i + offset, FALSE, FALSE)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/unenrage()
	if(stat == DEAD || is_mirror)
		return
	icon_state = "herald"

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/herald_directionalshot()
	ranged_cooldown = world.time + 3 SECONDS
	if(!is_mirror)
		icon_state = "herald_enraged"
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	addtimer(CALLBACK(src, PROC_REF(herald_circleshot), 0), 5)
	if(health < maxHealth * 0.5 && !is_mirror)
		playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
		addtimer(CALLBACK(src, PROC_REF(herald_circleshot), 22.5), 15)
	addtimer(CALLBACK(src, PROC_REF(unenrage)), 20)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/herald_teleshot(target)
	ranged_cooldown = world.time + 30
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	var/target_turf = get_turf(target)
	var/angle_to_target = get_angle(src, target_turf)
	shoot_projectile(target_turf, angle_to_target, TRUE, FALSE)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/herald_mirror()
	ranged_cooldown = world.time + 4 SECONDS
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	if(my_mirror != null)
		qdel(my_mirror)
		my_mirror = null
	var/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/new_mirror = new /mob/living/simple_animal/hostile/asteroid/elite/herald/mirror(loc)
	my_mirror = new_mirror
	my_mirror.my_master = src
	my_mirror.faction = faction.Copy()

/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror
	name = "herald's mirror"
	desc = "This fiendish work of magic copies the herald's attacks. Seems logical to smash it."
	health = 60
	maxHealth = 60
	icon_state = "herald_mirror"
	icon_aggro = "herald_mirror"
	deathmessage = "shatters violently!"
	deathsound = 'sound/effects/glassbr1.ogg'
	del_on_death = TRUE
	is_mirror = TRUE
	var/mob/living/simple_animal/hostile/asteroid/elite/herald/my_master = null

/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/Initialize()
	. = ..()
	AddElement(/datum/element/simple_flying)
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/Destroy()
	if(my_master != null)
		my_master.my_mirror = null
	. = ..()

/obj/projectile/herald
	name ="death bolt"
	icon_state= "chronobolt"
	damage = 20
	armour_penetration = 60
	speed = 2
	eyeblur = 0
	damage_type = BRUTE
	pass_flags = PASSTABLE

/obj/projectile/herald/teleshot
	name ="golden bolt"
	damage = 0
	color = rgb(255,255,102)

/obj/projectile/herald/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(ismineralturf(target))
		var/turf/closed/mineral/M = target
		M.gets_drilled()
		return
	else if(isliving(target))
		var/mob/living/L = target
		var/mob/living/F = firer
		if(F != null && istype(F, /mob/living/simple_animal/hostile/asteroid/elite) && F.faction_check_mob(L))
			L.heal_overall_damage(damage)

/obj/projectile/herald/teleshot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	firer.forceMove(get_turf(src))

//Herald's loot: Cloak of the Prophet

/obj/item/clothing/neck/cloak/herald_cloak
	name = "cloak of the prophet"
	desc = "A cloak which protects you from the heresy of the world."
	icon = 'icons/obj/lavaland/elite_trophies.dmi'
	icon_state = "herald_cloak"
	body_parts_covered = CHEST|GROIN|ARMS
	hit_reaction_chance = 20

/obj/item/clothing/neck/cloak/herald_cloak/proc/reactionshot(mob/living/carbon/owner)
	var/static/list/directional_shot_angles = list(0, 45, 90, 135, 180, 225, 270, 315)
	for(var/i in directional_shot_angles)
		shoot_projectile(get_turf(owner), i, owner)

/obj/item/clothing/neck/cloak/herald_cloak/proc/shoot_projectile(turf/marker, set_angle, mob/living/carbon/owner)
	var/turf/startloc = get_turf(owner)
	var/obj/projectile/herald/H = null
	H = new /obj/projectile/herald(startloc)
	H.preparePixelProjectile(marker, startloc)
	H.firer = owner
	H.fire(set_angle)

/obj/item/clothing/neck/cloak/herald_cloak/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if(rand(1,100) > hit_reaction_chance)
		return
	owner.visible_message(span_danger("[owner] [src] emits a loud noise as [owner] is struck!"))
	var/static/list/directional_shot_angles = list(0, 45, 90, 135, 180, 225, 270, 315)
	playsound(get_turf(owner), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	addtimer(CALLBACK(src, PROC_REF(reactionshot), owner), 10)
