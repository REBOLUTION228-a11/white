//Charger
/mob/living/simple_animal/hostile/guardian/charger
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = 1 //technically
	ranged_message = "charges"
	ranged_cooldown_time = 40
	speed = -1
	damage_coeff = list(BRUTE = 0.6, BURN = 0.6, TOX = 0.6, CLONE = 0.6, STAMINA = 0, OXY = 0.6)
	playstyle_string = span_holoparasite("As a <b>charger</b> type you do medium damage, have medium damage resistance, move very fast, and can charge at a location, damaging any target hit and forcing them to drop any items they are holding.")
	magic_fluff_string = span_holoparasite("..And draw the Hunter, an alien master of rapid assault.")
	tech_fluff_string = span_holoparasite("Boot sequence complete. Charge modules loaded. Holoparasite swarm online.")
	carp_fluff_string = span_holoparasite("CARP CARP CARP! Caught one! It's a charger carp, that likes running at people. But it doesn't have any legs...")
	miner_fluff_string = span_holoparasite("You encounter... Titanium, a lightweight, agile fighter.")
	var/charging = 0
	var/atom/movable/screen/alert/chargealert

/mob/living/simple_animal/hostile/guardian/charger/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(ranged_cooldown <= world.time)
		if(!chargealert)
			chargealert = throw_alert("charge", /atom/movable/screen/alert/cancharge)
	else
		clear_alert("charge")
		chargealert = null

/mob/living/simple_animal/hostile/guardian/charger/OpenFire(atom/A)
	if(!charging)
		visible_message(span_danger("<b>[src]</b> [ranged_message] at [A]!"))
		ranged_cooldown = world.time + ranged_cooldown_time
		clear_alert("charge")
		chargealert = null
		Shoot(A)

/mob/living/simple_animal/hostile/guardian/charger/Shoot(atom/targeted_atom)
	charging = 1
	throw_at(targeted_atom, range, 1, src, FALSE, TRUE, callback = CALLBACK(src, PROC_REF(charging_end)))

/mob/living/simple_animal/hostile/guardian/charger/proc/charging_end()
	charging = 0

/mob/living/simple_animal/hostile/guardian/charger/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
	. = ..()

/mob/living/simple_animal/hostile/guardian/charger/snapback()
	if(!charging)
		..()

/mob/living/simple_animal/hostile/guardian/charger/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!charging)
		return ..()

	else if(hit_atom)
		if(isliving(hit_atom) && hit_atom != summoner)
			var/mob/living/L = hit_atom
			var/blocked = FALSE
			if(hasmatchingsummoner(hit_atom)) //if the summoner matches don't hurt them
				blocked = TRUE
			if(ishuman(hit_atom))
				var/mob/living/carbon/human/H = hit_atom
				if(H.check_shields(src, 90, "[name]", attack_type = THROWN_PROJECTILE_ATTACK))
					blocked = TRUE
			if(!blocked)
				L.drop_all_held_items()
				L.visible_message(span_danger("[capitalize(src.name)] slams into [L]!") , span_userdanger("[capitalize(src.name)] slams into you!"))
				L.apply_damage(20, BRUTE)
				playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, TRUE)
				shake_camera(L, 4, 3)
				shake_camera(src, 2, 3)

		charging = 0

