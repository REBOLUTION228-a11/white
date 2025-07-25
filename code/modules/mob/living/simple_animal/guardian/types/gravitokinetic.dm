//gravitokinetic
/mob/living/simple_animal/hostile/guardian/gravitokinetic
	melee_damage_lower = 15
	melee_damage_upper = 15
	damage_coeff = list(BRUTE = 0.75, BURN = 0.75, TOX = 0.75, CLONE = 0.75, STAMINA = 0, OXY = 0.75)
	playstyle_string = span_holoparasite("As a <b>gravitokinetic</b> type, you can alt click to make the gravity on the ground stronger, and punching applies this effect to a target.")
	magic_fluff_string = span_holoparasite("..And draw the Singularity, an anomalous force of terror.")
	tech_fluff_string = span_holoparasite("Boot sequence complete. Gravitokinetic modules loaded. Holoparasite swarm online.")
	carp_fluff_string = span_holoparasite("CARP CARP CARP! Caught one! It's a gravitokinetic carp! Now do you understand the gravity of the situation?")
	miner_fluff_string = span_holoparasite("You encounter... Bananium, a master of gravity business.")
	var/list/gravito_targets = list()
	var/gravity_power_range = 10 //how close the stand must stay to the target to keep the heavy gravity

///Removes gravity from affected mobs upon guardian death to prevent permanent effects
/mob/living/simple_animal/hostile/guardian/gravitokinetic/death()
	. = ..()
	for(var/i in gravito_targets)
		remove_gravity(i)

/mob/living/simple_animal/hostile/guardian/gravitokinetic/AttackingTarget()
	. = ..()
	if(isliving(target) && target != src && target != summoner)
		to_chat(src, "<span class='danger'><B>Your punch has applied heavy gravity to [target]!</span></B>")
		add_gravity(target, 5)
		to_chat(target, span_userdanger("Everything feels really heavy!"))

/mob/living/simple_animal/hostile/guardian/gravitokinetic/AltClickOn(atom/A)
	if(isopenturf(A) && is_deployed() && stat != DEAD && in_range(src, A) && !incapacitated())
		var/turf/T = A
		if(isspaceturf(T))
			to_chat(src, span_warning("You cannot add gravity to space!"))
			return
		visible_message(span_danger("[capitalize(src.name)] slams their fist into the [T]!") , span_notice("You modify the gravity of the [T]."))
		do_attack_animation(T)
		add_gravity(T, 3)
		return
	return ..()

/mob/living/simple_animal/hostile/guardian/gravitokinetic/Recall(forced)
	. = ..()
	to_chat(src, "<span class='danger'><B>You have released your gravitokinetic powers!</span></B>")
	for(var/i in gravito_targets)
		remove_gravity(i)

/mob/living/simple_animal/hostile/guardian/gravitokinetic/Manifest(forced)
	. = ..()
	//just make sure to reapply a gravity immunity wherever you summon. it can be overridden but not by you at least
	summoner.AddElement(/datum/element/forced_gravity, 1)
	AddElement(/datum/element/forced_gravity, 1)

/mob/living/simple_animal/hostile/guardian/gravitokinetic/Moved(oldLoc, dir)
	. = ..()
	for(var/i in gravito_targets)
		if(get_dist(src, i) > gravity_power_range)
			remove_gravity(i)

/mob/living/simple_animal/hostile/guardian/gravitokinetic/proc/add_gravity(atom/A, new_gravity = 3)
	if(gravito_targets[A])
		return
	A.AddElement(/datum/element/forced_gravity, new_gravity)
	gravito_targets[A] = new_gravity
	RegisterSignal(A, COMSIG_MOVABLE_MOVED, PROC_REF(__distance_check))
	playsound(src, 'sound/effects/gravhit.ogg', 100, TRUE)

/mob/living/simple_animal/hostile/guardian/gravitokinetic/proc/remove_gravity(atom/target)
	if(isnull(gravito_targets[target]))
		return
	UnregisterSignal(target, COMSIG_MOVABLE_MOVED)
	target.RemoveElement(/datum/element/forced_gravity, gravito_targets[target])
	gravito_targets -= target

/mob/living/simple_animal/hostile/guardian/gravitokinetic/proc/__distance_check(atom/movable/AM, OldLoc, Dir, Forced)
	if(get_dist(src, AM) > gravity_power_range)
		remove_gravity(AM)
