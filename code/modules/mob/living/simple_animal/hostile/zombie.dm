/mob/living/simple_animal/hostile/zombie
	name = "Ходячий мертвец"
	desc = "Когда в аду больше не останется места, мертвые будут ходить в открытом космосе."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "zombie"
	icon_living = "zombie"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	speak_chance = 0
	stat_attack = DEAD //braains
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 21
	melee_damage_upper = 21
	attack_verb_continuous = "кусает"
	attack_verb_simple = "кусает"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	a_intent = INTENT_HARM
	attack_vis_effect = ATTACK_EFFECT_BITE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	status_flags = CANPUSH
	del_on_death = 1
	var/zombiejob = "Medical Doctor"
	var/infection_chance = 5
	var/obj/effect/mob_spawn/human/corpse/delayed/corpse

	discovery_points = 3000

/mob/living/simple_animal/hostile/zombie/Initialize(mapload)
	. = ..()
	zombiejob = pick(list("Assistant", "Cook", "Botanist", "Medical Doctor", "Bomj", "Lawyer", "Janitor", "Cargo Technician"))
	INVOKE_ASYNC(src, PROC_REF(setup_visuals))



/mob/living/simple_animal/hostile/zombie/proc/setup_visuals()
	var/datum/preferences/dummy_prefs = new
	dummy_prefs.pref_species = new /datum/species/zombie
	dummy_prefs.randomise[RANDOM_BODY] = TRUE
	var/datum/job/J = SSjob.GetJob(zombiejob)
	var/datum/outfit/O
	if(J.outfit)
		O = new J.outfit
		//They have claws now.
		O.r_hand = null
		O.l_hand = null

	var/icon/P = get_flat_human_icon("zombie_[zombiejob]", J , dummy_prefs, "zombie", outfit_override = O)
	icon = P
	corpse = new(src)
	corpse.outfit = O
	corpse.mob_species = /datum/species/zombie
	corpse.mob_name = name

/mob/living/simple_animal/hostile/zombie/AttackingTarget()
	. = ..()
	if(. && ishuman(target) && prob(infection_chance))
		try_to_mutant_infect(target)

/mob/living/simple_animal/hostile/zombie/drop_loot()
	. = ..()
	corpse.forceMove(drop_location())
	corpse.create()


/mob/living/simple_animal/hostile/zombie/mutant
	name = "Zombie"
	desc = "This dude looks sick..."
	melee_damage_lower = 15
	melee_damage_upper = 15
	speed = 5
	attack_verb_continuous = "кусает"
	attack_verb_simple = "кусает"
	infection_chance = 20
	faction = list("skeleton")




