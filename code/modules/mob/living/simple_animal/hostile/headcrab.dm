#define EGG_INCUBATION_TIME 4 MINUTES

/mob/living/simple_animal/hostile/headcrab
	name = "headslug"
	desc = "Absolutely not de-beaked or harmless. Keep away from corpses."
	icon_state = "headcrab"
	icon_living = "headcrab"
	icon_dead = "headcrab_dead"
	gender = NEUTER
	health = 50
	maxHealth = 50
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "кусает"
	attack_verb_simple = "кусает"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	faction = list("creature")
	robust_searching = 1
	stat_attack = DEAD
	obj_damage = 0
	gold_core_spawnable = HOSTILE_SPAWN
	environment_smash = ENVIRONMENT_SMASH_NONE
	speak_emote = list("пищит")
	ventcrawler = VENTCRAWLER_ALWAYS
	var/datum/mind/origin
	var/egg_lain = 0
	discovery_points = 2000

/mob/living/simple_animal/hostile/headcrab/proc/Infect(mob/living/carbon/victim)
	var/obj/item/organ/body_egg/changeling_egg/egg = new(victim)
	egg.Insert(victim)
	if(origin)
		egg.origin = origin
	else if(mind) // Let's make this a feature
		egg.origin = mind
	for(var/obj/item/organ/I in src)
		I.forceMove(egg)
	visible_message(span_warning("[capitalize(src.name)] plants something in [victim] flesh!") , \
					span_danger("We inject our egg into [victim] body!"))
	egg_lain = 1

/mob/living/simple_animal/hostile/headcrab/AttackingTarget()
	. = ..()
	if(. && !egg_lain && iscarbon(target) && !ismonkey(target))
		// Changeling egg can survive in aliens!
		var/mob/living/carbon/C = target
		if(C.stat == DEAD)
			if(HAS_TRAIT(C, TRAIT_XENO_HOST))
				to_chat(src, span_userdanger("A foreign presence repels us from this body. Perhaps we should try to infest another?"))
				return
			Infect(target)
			to_chat(src, span_userdanger("With our egg laid, our death approaches rapidly..."))
			addtimer(CALLBACK(src, PROC_REF(death)), 100)

/obj/item/organ/body_egg/changeling_egg
	name = "changeling egg"
	desc = "Twitching and disgusting."
	var/datum/mind/origin
	var/time = 0

/obj/item/organ/body_egg/changeling_egg/egg_process(delta_time, times_fired)
	// Changeling eggs grow in dead people
	time += delta_time * 10
	if(time >= EGG_INCUBATION_TIME)
		Pop()
		Remove(owner)
		qdel(src)

/obj/item/organ/body_egg/changeling_egg/proc/Pop()
	var/mob/living/carbon/human/M = new(owner)

	for(var/obj/item/organ/I in src)
		I.Insert(M, 1)

	if(origin && (origin.current ? (origin.current.stat == DEAD) : origin.get_ghost()))
		origin.transfer_to(M)
		var/datum/antagonist/changeling/C = origin.has_antag_datum(/datum/antagonist/changeling)
		if(!C)
			C = origin.add_antag_datum(/datum/antagonist/changeling/xenobio)
		if(C.can_absorb_dna(owner))
			C.add_new_profile(owner)

		C.regain_powers()
		M.key = origin.key
	owner.gib()

#undef EGG_INCUBATION_TIME
