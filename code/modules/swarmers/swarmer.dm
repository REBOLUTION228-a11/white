/**
 * # Swarmer
 *
 * Tiny machines made by an ancient civilization, they seek only to consume materials and replicate.
 *
 * Tiny robots which, while not lethal, seek to destroy station components in order to recycle them into more swarmers.
 * Sentient player swarmers spawn from a beacon spawned in maintenance and they can spawn melee swarmers to protect them.
 * Swarmers have the following abilities:
 * - Can melee targets to deal stamina damage.  Stuns cyborgs.
 * - Can teleport friend and foe alike away using ctrl + click.  Applies binds to carbons, preventing them from immediate retaliation
 * - Can shoot lasers which deal stamina damage to carbons and direct damage to simple mobs
 * - Can self repair for free, completely healing themselves
 * - Can construct traps which stun targets, and walls which block non-swarmer entites and projectiles
 * - Can create swarmer drones, which lack the above abilities sans melee stunning targets.  A swarmer can order its drones around by middle-clicking a tile.
 */

/mob/living/simple_animal/hostile/swarmer
	name = "Роевик"
	icon = 'icons/mob/swarmer.dmi'
	desc = "Роботизированные конструкции неизвестного дизайна, роевики стремятся только потреблять материалы и бесконечно воспроизводить себя."
	speak_emote = list("тонирует")
	initial_language_holder = /datum/language_holder/swarmer
	bubble_icon = "swarmer"
	mob_biotypes = MOB_ROBOTIC
	health = 40
	maxHealth = 40
	status_flags = CANPUSH
	icon_state = "swarmer"
	icon_living = "swarmer"
	icon_dead = "swarmer_unactivated"
	icon_gib = null
	wander = 0
	harm_intent_damage = 5
	minbodytemp = 0
	maxbodytemp = 500
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	melee_damage_lower = 30
	melee_damage_upper = 30
	melee_damage_type = STAMINA
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	hud_possible = list(ANTAG_HUD, DIAG_STAT_HUD, DIAG_HUD)
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_verb_continuous = "шокирует"
	attack_verb_simple = "шокирует"
	attack_sound = 'sound/effects/empulse.ogg'
	friendly_verb_continuous = "тычет"
	friendly_verb_simple = "тычет"
	speed = 0
	faction = list("swarmer")
	AIStatus = AI_OFF
	pass_flags = PASSTABLE
	mob_size = MOB_SIZE_TINY
	ranged = TRUE
	projectiletype = /obj/projectile/beam/disabler/swarmer
	ranged_cooldown_time = 20
	projectilesound = 'sound/weapons/taser2.ogg'
	loot = list(/obj/effect/decal/cleanable/robot_debris, /obj/item/stack/ore/bluespace_crystal)
	del_on_death = TRUE
	deathmessage = "лопается!"
	light_system = MOVABLE_LIGHT
	light_range = 3
	light_color = LIGHT_COLOR_CYAN
	hud_type = /datum/hud/swarmer
	speech_span = SPAN_ROBOT
	///Resource points, generated by consuming metal/glass
	var/resources = 20
	///Maximum amount of resources a swarmer can store
	var/max_resources = 100
	///List used for player swarmers to keep track of their drones
	var/list/mob/living/simple_animal/hostile/swarmer/drone/dronelist
	///Bitflags to store boolean conditions, such as whether the light is on or off.
	var/swarmer_flags = NONE
	discovery_points = 1000


/mob/living/simple_animal/hostile/swarmer/Initialize()
	. = ..()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_to_hud(src)

/mob/living/simple_animal/hostile/swarmer/Move()
	. = ..()
	if(!LAZYLEN(dronelist))
		return
	for(var/d in dronelist)
		var/mob/living/simple_animal/hostile/drone = d
		if(!drone.target && !HAS_TRAIT(drone, TRAIT_IMMOBILIZED) && isturf(drone.loc))
			step_to(drone, src)

/mob/living/simple_animal/hostile/swarmer/med_hud_set_health()
	var/image/holder = hud_list[DIAG_HUD]
	var/icon/I = icon(icon, icon_state, dir)
	holder.pixel_y = I.Height() - world.icon_size
	holder.icon_state = "huddiag[RoundDiagBar(health/maxHealth)]"

/mob/living/simple_animal/hostile/swarmer/med_hud_set_status()
	var/image/holder = hud_list[DIAG_STAT_HUD]
	var/icon/I = icon(icon, icon_state, dir)
	holder.pixel_y = I.Height() - world.icon_size
	holder.icon_state = "hudstat"

/mob/living/simple_animal/hostile/swarmer/get_status_tab_items()
	. = ..()
	. += "Ресурсы: [resources]"

/mob/living/simple_animal/hostile/swarmer/emp_act()
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(health > 1)
		adjustHealth(health-1)
	else
		death()

/mob/living/simple_animal/hostile/swarmer/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/beam/disabler))//Allows for swarmers to fight as a group without wasting their shots hitting each other
		return TRUE
	else if(isswarmer(mover))
		return TRUE

////CTRL CLICK FOR SWARMERS AND SWARMER_ACT()'S////
/mob/living/simple_animal/hostile/swarmer/AttackingTarget()
	if(!isliving(target))
		return target.swarmer_act(src)
	if(iscyborg(target))
		var/mob/living/silicon/borg = target
		borg.adjustBruteLoss(melee_damage_lower)
	return ..()

/mob/living/simple_animal/hostile/swarmer/CtrlClickOn(atom/target)
	face_atom(target)
	if(!istype(target, /mob/living))
		return
	if(!isturf(loc))
		return
	if(next_move > world.time)
		return
	if(!target.Adjacent(src))
		return
	prepare_target(target)

////END CTRL CLICK FOR SWARMERS////

/**
 * Called when a swarmer creates a structure or drone
 *
 * Proc called whenever a swarmer creates a structure or drone
 * Arguments:
 * * fabrication_object - The atom to create
 * * fabrication_cost - How many resources it costs for a swarmer to create the object
 */
/mob/living/simple_animal/hostile/swarmer/proc/Fabricate(atom/fabrication_object,fabrication_cost = 0)
	if(!isturf(loc))
		to_chat(src, span_warning("Эта локация не подходит. Нужно больше места."))
		return
	if(resources < fabrication_cost)
		to_chat(src, span_warning("Недостаточно ресурсов для этого объекта."))
		return
	resources -= fabrication_cost
	return new fabrication_object(drop_location())

/**
 * Called when a swarmer attempts to consume an object
 *
 * Proc which determines interaction between a swarmer and whatever it is attempting to consume
 * Arguments:
 * * target - The material or object the swarmer is attempting to consume
 */
/mob/living/simple_animal/hostile/swarmer/proc/Integrate(obj/target)
	var/resource_gain = target.integrate_amount()
	if(resources + resource_gain > max_resources)
		to_chat(src, span_warning("Мы не можем хранить больше материалов!"))
		return TRUE
	if(!resource_gain)
		to_chat(src, span_warning("[target] не подходит нам."))
		return FALSE
	resources += resource_gain
	do_attack_animation(target)
	changeNext_move(CLICK_CD_RAPID)
	var/obj/effect/temp_visual/swarmer/integrate/I = new /obj/effect/temp_visual/swarmer/integrate(get_turf(target))
	I.pixel_x = target.pixel_x
	I.pixel_y = target.pixel_y
	I.pixel_z = target.pixel_z
	if(istype(target, /obj/item/stack))
		var/obj/item/stack/S = target
		S.use(1)
		if(S.amount)
			return TRUE
	qdel(target)
	return TRUE

/**
 * Called when a swarmer attempts to destroy a structure
 *
 * Proc which determines interaction between a swarmer and a structure it is destroying
 * Arguments:
 * * target - The material or object the swarmer is attempting to destroy
 */
/mob/living/simple_animal/hostile/swarmer/proc/dis_integrate(atom/movable/target)
	new /obj/effect/temp_visual/swarmer/disintegration(get_turf(target))
	do_attack_animation(target)
	changeNext_move(CLICK_CD_MELEE)
	SSexplosions.low_mov_atom += target

/**
 * Called when a swarmer attempts to teleport a living entity away
 *
 * Proc which finds a safe location to teleport a living entity to when a swarmer teleports it away.  Also energy handcuffs carbons.
 * Arguments:
 * * target - The entity the swarmer пытается teleport away
 */
/mob/living/simple_animal/hostile/swarmer/proc/prepare_target(mob/living/target)
	if(target == src)
		return

	if(!is_station_level(z) && !is_mining_level(z))
		to_chat(src, span_warning("Наш блюспейс-передатчик не может найти блюспейс канал для связи, телепортация будет бесполезна в этой зоне."))
		return

	to_chat(src, span_info("Пытаемся убрать это существо подальше."))

	if(!do_mob(src, target, 30))
		return

	teleport_target(target)

/mob/living/simple_animal/hostile/swarmer/proc/teleport_target(mob/living/target)
	var/turf/open/floor/safe_turf = find_safe_turf(zlevels = z, extended_safety_checks = TRUE)

	if(!safe_turf )
		return
	// If we're getting rid of a human, slap some energy cuffs on
	// them to keep them away from us a little longer

	if(ishuman(target))
		var/mob/living/carbon/human/victim = target
		if(!victim.handcuffed)
			victim.set_handcuffed(new /obj/item/restraints/handcuffs/energy/used(victim))
			victim.update_handcuffed()
			log_combat(src, victim, "handcuffed")

	var/datum/effect_system/spark_spread/sparks = new
	sparks.set_up(4,0,get_turf(target))
	sparks.start()
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	do_teleport(target, safe_turf , 0, channel = TELEPORT_CHANNEL_BLUESPACE)

/mob/living/simple_animal/hostile/swarmer/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	if(!(flags & SHOCK_TESLA))
		return FALSE
	return ..()

/**
 * Called when a swarmer attempts to disassemble a machine
 *
 * Proc called when a swarmer attempts to disassemble a machine.  Destroys the machine, and gives the swarmer metal.
 * Arguments:
 * * target - The machine the swarmer is attempting to disassemble
 */
/mob/living/simple_animal/hostile/swarmer/proc/dismantle_machine(obj/machinery/target)
	do_attack_animation(target)
	to_chat(src, span_info("Начинаем разбирать эту машину. Необходимо невмешательство."))
	var/obj/effect/temp_visual/swarmer/dismantle/dismantle_effect = new /obj/effect/temp_visual/swarmer/dismantle(get_turf(target))
	dismantle_effect.pixel_x = target.pixel_x
	dismantle_effect.pixel_y = target.pixel_y
	dismantle_effect.pixel_z = target.pixel_z
	if(do_mob(src, target, 100))
		to_chat(src, span_info("Разборка машины успешна."))
		var/atom/target_loc = target.drop_location()
		new /obj/item/stack/sheet/iron(target_loc, 5)
		for(var/p in target.component_parts)
			var/obj/item/part = p
			part.forceMove(target_loc)
		var/obj/effect/temp_visual/swarmer/disintegration/disintegration_effect = new /obj/effect/temp_visual/swarmer/disintegration(get_turf(target))
		disintegration_effect.pixel_x = target.pixel_x
		disintegration_effect.pixel_y = target.pixel_y
		disintegration_effect.pixel_z = target.pixel_z
		target.dump_contents()
		if(istype(target, /obj/machinery/computer))
			var/obj/machinery/computer/computer_target = target
			if(computer_target.circuit)
				computer_target.circuit.forceMove(target_loc)
		qdel(target)

/**
 * Called when a swarmer attempts to create a trap
 *
 * Proc used to allow a swarmer to create a trap.  Checks if a trap is on the tile, then if the swarmer can afford, and then places the trap.
 */
/mob/living/simple_animal/hostile/swarmer/proc/create_trap()
	set name = "Создать ловушку"
	set category = "Swarmer"
	set desc = "Создает простую ловушку, которая ударит током тех, кто на нее наступит, без смертельного исхода. Стоит 4 ресурса."
	if(locate(/obj/structure/swarmer/trap) in loc)
		to_chat(src, span_warning("Здесь уже есть ловушка. Прерывание."))
		return
	if(resources < 4)
		to_chat(src, span_warning("У нас нет ресурсов для этого!"))
		return
	Fabricate(/obj/structure/swarmer/trap, 4)

/**
 * Called when a swarmer attempts to create a barricade
 *
 * Proc used to allow a swarmer to create a barricade.  Checks if a barricade is on the tile, then if the swarmer can afford it, and then will attempt to create a barricade after a second delay.
 */
/mob/living/simple_animal/hostile/swarmer/proc/create_barricade()
	set name = "Создать баррикаду"
	set category = "Swarmer"
	set desc = "Создает баррикаду, которая остановит прохождение чего угодно, кроме роевиков и лучей усмирителей. Стоит 4 ресурса."
	if(locate(/obj/structure/swarmer/blockade) in loc)
		to_chat(src, span_warning("Здесь уже баррикада. Прерывание."))
		return
	if(resources < 4)
		to_chat(src, span_warning("У нас нет ресурсов для этого!"))
		return
	if(!do_mob(src, src, 1 SECONDS))
		return
	Fabricate(/obj/structure/swarmer/blockade, 4)

/**
 * Called when a swarmer attempts to create a drone
 *
 * Proc used to allow a swarmer to create a drone.  Checks if the swarmer can afford the drone, then creates it after 5 seconds, and also registers it to the creating swarmer so it can command it
 */
/mob/living/simple_animal/hostile/swarmer/proc/create_swarmer()
	set name = "Репликация"
	set category = "Swarmer"
	set desc = "Создает дубликат нас самих, способный защитить нас, пока мы добиваемся своих целей."
	to_chat(src, span_info("Мы пытаемся копировать самих себя. Нам нужно будет стоять на месте, пока процесс не завершится."))
	if(resources < 20)
		to_chat(src, span_warning("У нас нет ресурсов для этого!"))
		return
	if(!isturf(loc))
		to_chat(src, span_warning("Это не подходящее место для самовоспроизведения. Нам нужно больше места."))
		return
	if(!do_mob(src, src, 5 SECONDS))
		return
	var/createtype = swarmer_type_to_create()
	if(!createtype)
		return
	var/mob/newswarmer = Fabricate(createtype, 20)
	add_drone(newswarmer)
	playsound(loc,'sound/items/poster_being_created.ogg', 20, TRUE, -1)

/**
 * Used to determine what type of swarmer a swarmer should create
 *
 * Returns the type of the swarmer to be created
 */
/mob/living/simple_animal/hostile/swarmer/proc/swarmer_type_to_create()
	return /mob/living/simple_animal/hostile/swarmer/drone

/**
 * Called when a swarmer attempts to repair itself
 *
 * Proc used to allow a swarmer self-repair.  If the swarmer does not move after a period of time, then it will heal fully
 */
/mob/living/simple_animal/hostile/swarmer/proc/repair_self()
	if(!isturf(loc))
		return
	to_chat(src, span_info("Пытаемся восстановить повреждение нашего тела, ожидание..."))
	if(!do_mob(src, src, 10 SECONDS))
		return
	adjustHealth(-maxHealth)
	to_chat(src, span_info("Мы успешно отремонтировали нас."))

/**
 * Called when a swarmer toggles its light
 *
 * Proc used to allow a swarmer to toggle its  light on and off.  If a swarmer has any drones, change their light settings to match their master's.
 */
/mob/living/simple_animal/hostile/swarmer/proc/toggle_light()
	if(swarmer_flags & SWARMER_LIGHT_ON)
		swarmer_flags = ~SWARMER_LIGHT_ON
		set_light_on(FALSE)
		if(!mind)
			return
		for(var/d in dronelist)
			var/mob/living/simple_animal/hostile/swarmer/drone/drone = d
			drone.swarmer_flags = ~SWARMER_LIGHT_ON
			drone.set_light_on(FALSE)
		return
	swarmer_flags |= SWARMER_LIGHT_ON
	set_light_on(TRUE)
	if(!mind)
		return
	for(var/d in dronelist)
		var/mob/living/simple_animal/hostile/swarmer/drone/drone = d
		drone.swarmer_flags |= SWARMER_LIGHT_ON
		drone.set_light_on(TRUE)


/**
 * Proc which is used for swarmer comms
 *
 * Proc called which sends a message to all other swarmers.
 * Arugments:
 * * msg - The message the swarmer is sending, gotten from ContactSwarmers()
 */
/mob/living/simple_animal/hostile/swarmer/proc/swarmer_chat(msg)
	var/rendered = "<B>Общение роя - [src]</b> [say_quote(msg)]"
	for(var/i in GLOB.mob_list)
		var/mob/listener = i
		if(isswarmer(listener))
			to_chat(listener, rendered)
		else if(isobserver(listener))
			var/link = FOLLOW_LINK(listener, src)
			to_chat(listener, "[link] [rendered]")

/**
 * Proc which is used for inputting a swarmer message
 *
 * Proc which is used for a swarmer to input a message on a pop-up box, then attempt to send that message to the other swarmers
 */
/mob/living/simple_animal/hostile/swarmer/proc/contact_swarmers()
	var/message = stripped_input(src, "Объявить другим роевикам", "Общение роя")
	// TODO get swarmers their own colour rather than just boldtext
	if(message)
		swarmer_chat(message)


///Adds a drone to the swarmer list and keeps track of it in case it's deleted and requires cleanup.
/mob/living/simple_animal/hostile/swarmer/proc/add_drone(mob/newswarmer)
	LAZYADD(dronelist, newswarmer)
	RegisterSignal(newswarmer, COMSIG_PARENT_QDELETING, PROC_REF(remove_drone), newswarmer)


/**
 * Removes a drone from the swarmer's list.
 *
 * Removes the drone from our list.
 * Called specifically when a drone is about to be destroyed, so we don't have any null references.
 * Arguments:
 * * mob/drone - The drone to be removed from the list.
 */
/mob/living/simple_animal/hostile/swarmer/proc/remove_drone(mob/drone, force)
	SIGNAL_HANDLER

	UnregisterSignal(drone, COMSIG_PARENT_QDELETING)
	dronelist -= drone

/**
 * # Swarmer Drone
 *
 * AI subtype of swarmers, always AI-controlled under normal circumstances.  Automatically attacks nearby threats.
 */
/mob/living/simple_animal/hostile/swarmer/drone
	icon_state = "swarmer_melee"
	icon_living = "swarmer_melee"
	AIStatus = AI_ON

/obj/projectile/beam/disabler/swarmer/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!.)
		return
	if((!isanimal(target) && !ishuman(target)) || isswarmer(target))
		return
	if(ishuman(target))
		var/mob/living/carbon/human/possibleHulk = target
		if(!possibleHulk.dna || !possibleHulk.dna.check_mutation(HULK))
			return
	var/mob/living/simple_animal/hostile/swarmer/swarmer = firer
	swarmer.teleport_target(target)
