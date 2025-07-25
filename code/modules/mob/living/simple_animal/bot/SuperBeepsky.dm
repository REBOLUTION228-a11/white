/mob/living/simple_animal/bot/secbot/grievous //This bot is powerful. If you managed to get 4 eswords somehow, you deserve this horror. Emag him for best results.
	name = "Генерал Бипски"
	desc = "Секбот с четырьмя мечами в руках...?"
	icon = 'icons/mob/aibots.dmi'
	icon_state = "grievous"
	health = 150
	maxHealth = 150
	baton_type = /obj/item/melee/energy/sword/saber
	base_speed = 4 //he's a fast fucker
	var/block_chance = 50
	weapon_force = 30


/mob/living/simple_animal/bot/secbot/grievous/toy //A toy version of general beepsky!
	name = "Геневав Бвипски"
	desc = "Очаровательно выглядящий секбот с четырьмя игрушечными мечами, привязанными к его рукам."
	health = 50
	maxHealth = 50
	baton_type = /obj/item/toy/sword
	weapon_force = 0

/mob/living/simple_animal/bot/secbot/grievous/bullet_act(obj/projectile/P)
	visible_message(span_warning("[capitalize(src.name)] отражает [P] используя энергомечи!"))
	playsound(src, 'sound/weapons/blade1.ogg', 50, TRUE)
	return BULLET_ACT_BLOCK

/mob/living/simple_animal/bot/secbot/grievous/on_entered(datum/source, atom/movable/AM)
	. = ..()
	if(ismob(AM) && AM == target)
		visible_message(span_warning("[capitalize(src.name)] сокрушает свои энергомечи в сторону [AM]!"))
		playsound(src,'sound/effects/beepskyspinsabre.ogg',100,TRUE,-1)
		INVOKE_ASYNC(src, PROC_REF(stun_attack), AM)

/mob/living/simple_animal/bot/secbot/grievous/Initialize()
	. = ..()
	INVOKE_ASYNC(weapon, TYPE_PROC_REF(/obj/item, attack_self), src)

/mob/living/simple_animal/bot/secbot/grievous/Destroy()
	QDEL_NULL(weapon)
	return ..()

/mob/living/simple_animal/bot/secbot/grievous/special_retaliate_after_attack(mob/user)
	if(mode != BOT_HUNT)
		return
	if(prob(block_chance))
		visible_message(span_warning("[capitalize(src.name)] отражает атаку [user] своими энергомечами!"))
		playsound(src, 'sound/weapons/blade1.ogg', 50, TRUE, -1)
		return TRUE

/mob/living/simple_animal/bot/secbot/grievous/stun_attack(mob/living/carbon/C) //Criminals don't deserve to live
	weapon.attack(C, src)
	playsound(src, 'sound/weapons/blade1.ogg', 50, TRUE, -1)
	if(C.stat == DEAD)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_icon)), 2)
		back_to_idle()


/mob/living/simple_animal/bot/secbot/grievous/handle_automated_action()
	if(!on)
		return
	switch(mode)
		if(BOT_IDLE)		// idle
			update_icon()
			SSmove_manager.stop_looping(src)
			look_for_perp()	// see if any criminals are in range
			if(!mode && auto_patrol)	// still idle, and set to patrol
				mode = BOT_START_PATROL	// switch to patrol mode
		if(BOT_HUNT)		// hunting for perp
			update_icon()
			playsound(src,'sound/effects/beepskyspinsabre.ogg',100,TRUE,-1)
			// general beepsky doesn't give up so easily, jedi scum
			if(frustration >= 20)
				SSmove_manager.stop_looping(src)
				back_to_idle()
				return
			if(target)		// make sure target exists
				if(Adjacent(target) && isturf(target.loc))	// if right next to perp
					target_lastloc = target.loc //stun_attack() can clear the target if they're dead, so this needs to be set first
					stun_attack(target)
					set_anchored(TRUE)
					return
				else								// not next to perp
					var/turf/olddist = get_dist(src, target)
					SSmove_manager.move_to(src, target, 1, 4)
					if((get_dist(src, target)) >= (olddist))
						frustration++
					else
						frustration = 0
			else
				back_to_idle()

		if(BOT_START_PATROL)
			look_for_perp()
			start_patrol()

		if(BOT_PATROL)
			look_for_perp()
			bot_patrol()

/mob/living/simple_animal/bot/secbot/grievous/look_for_perp()
	anchored = FALSE
	var/judgement_criteria = judgement_criteria()
	for (var/mob/living/carbon/C in view(7,src)) //Let's find us a criminal
		if((C.stat) || (C.handcuffed))
			continue

		if((C.name == oldtarget_name) && (world.time < last_found + 100))
			continue

		threatlevel = C.assess_threat(judgement_criteria, weaponcheck=CALLBACK(src, PROC_REF(check_for_weapons)))

		if(!threatlevel)
			continue

		else if(threatlevel >= 4)
			target = C
			oldtarget_name = C.name
			speak("Уровень [threatlevel], предупреждение о нарушении!")
			//playsound(src, pick('sound/voice/beepsky/criminal.ogg', 'sound/voice/beepsky/justice.ogg', 'sound/voice/beepsky/freeze.ogg'), 50, FALSE)
			playsound(loc, pick('white/valtos/sounds/beepsky_russian/criminal.ogg', 'white/valtos/sounds/beepsky_russian/justice.ogg', 'white/valtos/sounds/beepsky_russian/freeze.ogg'), 50, FALSE)
			playsound(src,'sound/weapons/saberon.ogg',50,TRUE,-1)
			visible_message(span_warning("[capitalize(src.name)] зажигает свои энергомечи!"))
			icon_state = "grievous-c"
			visible_message("<b>[capitalize(src.name)]</b> гонится за [C.name]!")
			mode = BOT_HUNT
			INVOKE_ASYNC(src, PROC_REF(handle_automated_action))
			break
		else
			continue


/mob/living/simple_animal/bot/secbot/grievous/explode()

	SSmove_manager.stop_looping(src)
	visible_message(span_boldannounce("[capitalize(src.name)] громко кашляет и взрывается!"))
	var/atom/Tsec = drop_location()

	var/obj/item/bot_assembly/secbot/Sa = new (Tsec)
	Sa.build_step = 1
	Sa.add_overlay("hs_hole")
	Sa.created_name = name
	new /obj/item/assembly/prox_sensor(Tsec)

	if(prob(50))
		drop_part(robot_arm, Tsec)

	do_sparks(3, TRUE, src)
	for(var/IS = 0 to 4)
		drop_part(baton_type, Tsec)
	new /obj/effect/decal/cleanable/oil(Tsec)
	qdel(src)
