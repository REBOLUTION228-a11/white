
#define DUALWIELD_PENALTY_EXTRA_MULTIPLIER 1.4
#define FIRING_PIN_REMOVAL_DELAY 50

/obj/item/gun
	name = "оружие"
	desc = "Пистолет. Хотя, довольно ужасный."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "detective"
	inhand_icon_state = "gun"
	worn_icon_state = "gun"
	flags_1 =  CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	custom_materials = list(/datum/material/iron=2000)
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	force = 5
	item_flags = NEEDS_PERMIT
	attack_verb_continuous = list("ударяет", "бьёт", "колотит")
	attack_verb_simple = list("ударяет", "бьёт", "колотит")

	var/gun_flags = NONE
	var/fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	var/vary_fire_sound = TRUE
	var/fire_sound_volume = 50
	var/dry_fire_sound = 'sound/weapons/gun/general/dry_fire.ogg'
	var/suppressed = null //whether or not a message is displayed when fired
	var/can_suppress = FALSE
	var/suppressed_sound = 'sound/weapons/gun/general/heavy_shot_suppressed.ogg'
	var/suppressed_volume = 60
	var/can_unsuppress = TRUE
	var/recoil = 0 //boom boom shake the room
	var/clumsy_check = TRUE
	var/obj/item/ammo_casing/chambered = null
	trigger_guard = TRIGGER_GUARD_NORMAL //trigger guard on the weapon, hulks can't fire them with their big meaty fingers
	var/sawn_desc = null //description change if weapon is sawn-off
	var/sawn_off = FALSE
	var/burst_size = 1 //how large a burst is
	var/fire_delay = 0 //rate of fire for burst firing and semi auto
	var/firing_burst = 0 //Prevent the weapon from firing again while already firing
	var/semicd = 0 //cooldown handler
	var/weapon_weight = WEAPON_LIGHT
	var/dual_wield_spread = 24 //additional spread when dual wielding

	/// Just 'slightly' snowflakey way to modify projectile damage for projectiles fired from this gun.
	var/projectile_damage_multiplier = 1

	var/spread = 0 //Spread induced by the gun itself.
	var/randomspread = 1 //Set to 0 for shotguns. This is used for weapons that don't fire all their bullets at once.

	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'

	var/obj/item/firing_pin/pin = /obj/item/firing_pin //standard firing pin for most guns
	/// True if a gun dosen't need a pin, mostly used for abstract guns like tentacles and meathooks
	var/pinless = FALSE
	var/can_flashlight = FALSE //if a flashlight can be added or removed if it already has one.
	var/obj/item/flashlight/seclite/gun_light
	var/datum/action/item_action/toggle_gunlight/alight
	var/gunlight_state = "flight"

	var/can_bayonet = FALSE //if a bayonet can be added or removed if it already has one.
	var/obj/item/kitchen/knife/bayonet
	var/knife_x_offset = 0
	var/knife_y_offset = 0

	var/ammo_x_offset = 0 //used for positioning ammo count overlay on sprite
	var/ammo_y_offset = 0
	var/flight_x_offset = 0
	var/flight_y_offset = 0

	//Zooming
	var/zoomable = FALSE //whether the gun generates a Zoom action on creation
	var/zoomed = FALSE //Zoom toggle
	var/zoom_amt = 3 //Distance in TURFs to move the user's screen forward (the "zoom" effect)
	var/zoom_out_amt = 0
	var/datum/action/toggle_scope_zoom/azoom
	var/pb_knockback = 0
	hud_possible = list(HACKER_HUD)
	var/extra_damage = 0				//Number to add to individual bullets.
	var/extra_penetration = 0			//Number to add to armor penetration of individual bullets.

	var/custom_skin_name = null

/obj/item/gun/Initialize()
	. = ..()
	if(pin)
		pin = new pin(src)
	if(gun_light)
		alight = new(src)
	build_zooming()
	make_jamming()
	RegisterSignal(src, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(change_skin))

/obj/item/gun/Destroy()
	if(isobj(pin)) //Can still be the initial path, then we skip
		QDEL_NULL(pin)
	if(gun_light)
		QDEL_NULL(gun_light)
	if(bayonet)
		QDEL_NULL(bayonet)
	if(chambered) //Not all guns are chambered (EMP'ed energy guns etc)
		QDEL_NULL(chambered)
	if(azoom)
		QDEL_NULL(azoom)
	if(isatom(suppressed)) //SUPPRESSED IS USED AS BOTH A TRUE/FALSE AND AS A REF, WHAT THE FUCKKKKKKKKKKKKKKKKK
		QDEL_NULL(suppressed)
	return ..()

/obj/item/gun/handle_atom_del(atom/A)
	if(A == pin)
		pin = null
	if(A == chambered)
		chambered = null
		update_appearance()
	if(A == bayonet)
		clear_bayonet()
	if(A == gun_light)
		clear_gunlight()
	if(A == suppressed)
		clear_suppressor()
	return ..()

///Clears var and updates icon. In the case of ballistic weapons, also updates the gun's weight.
/obj/item/gun/proc/clear_suppressor()
	if(!can_unsuppress)
		return
	suppressed = null
	update_appearance()

/obj/item/gun/examine(mob/user)
	. = ..()
	if(!pinless)
		. += "<hr>"
		if(pin)
			. += span_info("Внутри установлен [pin] и его можно вытащить при помощи <b>инструментов</b>.")
		else
			. += span_danger("Внутри отсутствует <b>ударник</b>, поэтому огонь вести невозможно.")

	if(gun_light)
		. += "\n"
		. += span_info("На нём установлен [gun_light], который [can_flashlight ? "" : "<b>надёжно</b> "]прикручен к нему.")
	else if(can_flashlight)
		. += "\n"
		. += span_info("Здесь присутствует посадочное место для <b>фонарика</b>.")

	if(bayonet)
		. += "\n"
		. += span_info("На нём установлен [bayonet], который [can_bayonet ? "" : "<b>надёжно</b> "]прикреплён к нему.")
	else if(can_bayonet)
		. += "\n"
		. += "Сюда можно прикрепить <b>штык</b>."

/obj/item/gun/equipped(mob/living/user, slot)
	. = ..()
	if(zoomed && user.get_active_held_item() != src)
		zoom(user, user.dir, FALSE) //we can only stay zoomed in if it's in our hands //yeah and we only unzoom if we're actually zoomed using the gun!!

//called after the gun has successfully fired its chambered ammo.
/obj/item/gun/proc/process_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	handle_chamber(empty_chamber, from_firing, chamber_next_round)
	SEND_SIGNAL(src, COMSIG_GUN_CHAMBER_PROCESSED)

/obj/item/gun/proc/handle_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	return

//check if there's enough ammo/energy/whatever to shoot one time
//i.e if clicking would make it shoot
/obj/item/gun/proc/can_shoot()
	return TRUE

/obj/item/gun/proc/shoot_with_empty_chamber(mob/living/user as mob|obj)
	to_chat(user, span_danger("*щёлк*"))
	playsound(src, dry_fire_sound, 30, TRUE)


/obj/item/gun/proc/shoot_live_shot(mob/living/user, pointblank = 0, atom/pbtarget = null, message = 1)
	if(recoil)
		shake_camera(user, recoil + 1, recoil)

	if(suppressed)
		playsound(user, suppressed_sound, suppressed_volume, vary_fire_sound, ignore_walls = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	else
		playsound(user, fire_sound, fire_sound_volume, vary_fire_sound)
		if(message)
			if(pointblank)
				user.visible_message(span_danger("<b>[user]</b> стреляет из <b>[src.name]</b> <b>В УПОР</b> по <b>[pbtarget]</b>!"), \
								span_danger("Стреляю из [src.name] <b>В УПОР</b> по <b>[pbtarget]</b>!"), \
								span_hear("Слышу выстрел!"), COMBAT_MESSAGE_RANGE, pbtarget)
				to_chat(pbtarget, span_userdanger("<b>[user]</b> стреляет из <b>[src.name]</b> в меня <b>В УПОР</b>!"))
				if(pb_knockback > 0 && ismob(pbtarget))
					var/mob/PBT = pbtarget
					var/atom/throw_target = get_edge_target_turf(PBT, user.dir)
					PBT.throw_at(throw_target, pb_knockback, 2)
			else
				user.visible_message(span_danger("<b>[user]</b> стреляет из <b>[src.name]</b> в <b>[pbtarget]</b>!"), \
								span_danger("Стреляю из [src.name] в <b>[pbtarget]</b>!"), \
								span_hear("Слышу выстрел!"), COMBAT_MESSAGE_RANGE)

/obj/item/gun/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_CONTENTS))
		for(var/obj/O in contents)
			O.emp_act(severity)

/obj/item/gun/attack_secondary(mob/living/victim, mob/living/user, params)
	if (user.GetComponent(/datum/component/gunpoint))
		to_chat(user, span_warning("Уже держу кого-то на прицеле!"))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if (user == victim)
		to_chat(user,span_warning("Не могу целиться в себя!"))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	user.AddComponent(/datum/component/gunpoint, victim, src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/gun/afterattack(atom/target, mob/living/user, flag, params)
	. = ..()
	return fire_gun(target, user, flag, params)

/obj/item/gun/proc/fire_gun(atom/target, mob/living/user, flag, params)
	if(QDELETED(target))
		return
	if(firing_burst)
		return

	if(flag) //It's adjacent, is the user, or is on the user's person
		if(target in user.contents) //can't shoot stuff inside us.
			return
		if(!ismob(target) || (user.a_intent == INTENT_HARM)) //melee attack
			return
		if(target == user && user.zone_selected != BODY_ZONE_PRECISE_MOUTH) //so we can't shoot ourselves (unless mouth selected)
			return
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			for(var/i in C.all_wounds)
				var/datum/wound/W = i
				if(W.try_treating(src, user))
					return // another coward cured!

	if(istype(user))//Check if the user can use the gun, if the user isn't alive(turrets) assume it can.
		var/mob/living/L = user
		if(!can_trigger_gun(L))
			return

	if(flag)
		if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
			handle_suicide(user, target, params)
			return

	if(!can_shoot()) //Just because you can pull the trigger doesn't mean it can shoot.
		shoot_with_empty_chamber(user)
		return

	if(check_botched(user, target))
		return

	var/obj/item/bodypart/other_hand = user.has_hand_for_held_index(user.get_inactive_hand_index()) //returns non-disabled inactive hands
	if(weapon_weight == WEAPON_HEAVY && (user.get_inactive_held_item() || !other_hand))
		to_chat(user, span_warning("Надо бы держать [src.name] в обеих руках!"))
		return
	//DUAL (or more!) WIELDING
	var/bonus_spread = 0
	var/loop_counter = 0
	if(ishuman(user) && (user.a_intent == INTENT_HARM))
		var/mob/living/carbon/human/H = user
		for(var/obj/item/gun/G in H.held_items)
			if(G == src || G.weapon_weight >= WEAPON_MEDIUM)
				continue
			else if(G.can_trigger_gun(user))
				bonus_spread += dual_wield_spread
				loop_counter++
				addtimer(CALLBACK(G, TYPE_PROC_REF(/obj/item/gun, process_fire), target, user, TRUE, params, null, bonus_spread), loop_counter)

	return process_fire(target, user, TRUE, params, null, bonus_spread)

/obj/item/gun/proc/check_botched(mob/living/user, atom/target)
	if(clumsy_check)
		if(istype(user))
			if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(40))
				to_chat(user, span_userdanger("Стреляю себе в ногу из [src.name]!"))
				var/shot_leg = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				process_fire(user, user, FALSE, null, shot_leg)
				SEND_SIGNAL(user, COMSIG_MOB_CLUMSY_SHOOT_FOOT)
				user.dropItemToGround(src, TRUE)
				return TRUE

/obj/item/gun/can_trigger_gun(mob/living/user)
	. = ..()
	if(!handle_pins(user))
		return FALSE

/obj/item/gun/proc/handle_pins(mob/living/user)
	if(pinless)
		return TRUE
	if(pin)
		if(pin.pin_auth(user) || (pin.obj_flags & EMAGGED))
			return TRUE
		else
			pin.auth_fail(user)
			return FALSE
	else
		to_chat(user, span_warning("[capitalize(src.name)] курок заблокирован. У этого оружия нет бойка!"))
	return FALSE

/obj/item/gun/proc/recharge_newshot()
	return

/obj/item/gun/proc/process_burst(mob/living/user, atom/target, message = TRUE, params=null, zone_override = "", sprd = 0, randomized_gun_spread = 0, randomized_bonus_spread = 0, rand_spr = 0, iteration = 0)
	if(!user || !firing_burst)
		firing_burst = FALSE
		return FALSE
	if(!issilicon(user))
		if(iteration > 1 && !(user.is_holding(src))) //for burst firing
			firing_burst = FALSE
			return FALSE
	if(chambered?.loaded_projectile)
		if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
			if(chambered.harmful) // Is the bullet chambered harmful?
				to_chat(user, span_warning("[capitalize(src.name)] заряжен летально! Я же ведь не хочу навредить кому-то..."))
				return
		if(randomspread)
			sprd = round((rand(0, 1) - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * (randomized_gun_spread + randomized_bonus_spread))
		else //Smart spread
			sprd = round((((rand_spr/burst_size) * iteration) - (0.5 + (rand_spr * 0.25))) * (randomized_gun_spread + randomized_bonus_spread))
		before_firing(target,user)
		if(!chambered.fire_casing(target, user, params, 0, suppressed, zone_override, sprd, src, extra_damage, extra_penetration))
			shoot_with_empty_chamber(user)
			firing_burst = FALSE
			return FALSE
		else
			if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
				shoot_live_shot(user, 1, target, message)
			else
				shoot_live_shot(user, 0, target, message)
			if (iteration >= burst_size)
				firing_burst = FALSE
	else
		shoot_with_empty_chamber(user)
		firing_burst = FALSE
		return FALSE
	process_chamber()
	update_appearance()
	return TRUE

/obj/item/gun/proc/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN, src, target, params, zone_override)

	if(SEND_SIGNAL(src, COMSIG_GUN_FIRED, user, target, params, zone_override) & COMSIG_GUN_FIRED_CANCEL)
		return

	add_fingerprint(user)

	if(semicd)
		return

	//Vary by at least this much
	var/base_bonus_spread = 0
	var/sprd = 0
	var/randomized_gun_spread = 0
	var/rand_spr = rand()
	if(user && HAS_TRAIT(user, TRAIT_POOR_AIM)) //Nice job hotshot
		bonus_spread += 35
		base_bonus_spread += 10

	if(spread)
		randomized_gun_spread =	rand(0,spread)
	var/randomized_bonus_spread = rand(base_bonus_spread, bonus_spread)

	if(check_for_assblast(user, "R_U_A_WIZARD?")) //nice shootin' tex nice shootin' tex nice shootin' tex nice shootin' tex
		user.emote("spin")
		randomized_gun_spread = 360
		randomized_bonus_spread = 0

	if(burst_size > 1)
		firing_burst = TRUE
		for(var/i = 1 to burst_size)
			addtimer(CALLBACK(src, PROC_REF(process_burst), user, target, message, params, zone_override, sprd, randomized_gun_spread, randomized_bonus_spread, rand_spr, i), fire_delay * (i - 1))
	else
		if(chambered)
			if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
				if(chambered.harmful) // Is the bullet chambered harmful?
					to_chat(user, span_warning("[capitalize(src.name)] заряжен летально! Я же ведь не хочу навредить кому-то..."))
					return
			sprd = round((rand(0, 1) - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * (randomized_gun_spread + randomized_bonus_spread))
			before_firing(target,user)
			if(!chambered.fire_casing(target, user, params, 0, suppressed, zone_override, sprd, src, extra_damage, extra_penetration))
				shoot_with_empty_chamber(user)
				return
			else
				if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
					shoot_live_shot(user, 1, target, message)
				else
					shoot_live_shot(user, 0, target, message)
		else
			shoot_with_empty_chamber(user)
			return
		process_chamber()
		update_appearance()
		semicd = TRUE
		addtimer(CALLBACK(src, PROC_REF(reset_semicd)), fire_delay)

	if(user)
		user.update_inv_hands()
	SSblackbox.record_feedback("tally", "gun_fired", 1, type)
	SEND_SIGNAL(src, COMSIG_UPDATE_AMMO_HUD)

	return TRUE

/obj/item/gun/proc/reset_semicd()
	semicd = FALSE

/obj/item/gun/attack(mob/M, mob/living/user)
	if((user.a_intent == INTENT_HARM)) //Flogging
		if(bayonet)
			M.attackby(bayonet, user)
			return
		else
			return ..()
	return

/obj/item/gun/attack_obj(obj/O, mob/living/user, params)
	if((user.a_intent == INTENT_HARM))
		if(bayonet)
			O.attackby(bayonet, user)
			return
	return ..()

/obj/item/gun/attackby(obj/item/I, mob/living/user, params)
	if((user.a_intent == INTENT_HARM))
		return ..()
	else if(istype(I, /obj/item/flashlight/seclite))
		if(!can_flashlight)
			return ..()
		var/obj/item/flashlight/seclite/S = I
		if(!gun_light)
			if(!user.transferItemToLoc(I, src))
				return
			to_chat(user, span_notice("Защёлкиваю [S] прямо в слот [src]."))
			set_gun_light(S)
			update_gunlight()
			alight = new(src)
			if(loc == user)
				alight.Grant(user)
	else if(istype(I, /obj/item/kitchen/knife))
		var/obj/item/kitchen/knife/K = I
		if(!can_bayonet || !K.bayonet || bayonet) //ensure the gun has an attachment point available, and that the knife is compatible with it.
			return ..()
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, span_notice("Монтирую [K] на [src]."))
		bayonet = K
		update_appearance()

	else
		return ..()

/obj/item/gun/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if((can_flashlight && gun_light) && (can_bayonet && bayonet)) //give them a choice instead of removing both
		var/list/possible_items = list(gun_light, bayonet)
		var/obj/item/item_to_remove = input(user, "Select an attachment to remove", "Attachment Removal") as null|obj in sortNames(possible_items)
		if(!item_to_remove || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
			return
		return remove_gun_attachment(user, I, item_to_remove)

	else if(gun_light && can_flashlight) //if it has a gun_light and can_flashlight is false, the flashlight is permanently attached.
		return remove_gun_attachment(user, I, gun_light, "unscrewed")

	else if(bayonet && can_bayonet) //if it has a bayonet, and the bayonet can be removed
		return remove_gun_attachment(user, I, bayonet, "unfix")

	else if(pin && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is pried out of [src] by [user], destroying the pin in the process."),
								span_warning("You pry [pin] out with [I], destroying the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return TRUE

/obj/item/gun/welder_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(pin && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, 5, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is spliced out of [src] by [user], melting part of the pin in the process."),
								span_warning("You splice [pin] out of [src] with [I], melting part of the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return TRUE

/obj/item/gun/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(pin && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is ripped out of [src] by [user], mangling the pin in the process."),
								span_warning("You rip [pin] out of [src] with [I], mangling the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return TRUE

/obj/item/gun/proc/remove_gun_attachment(mob/living/user, obj/item/tool_item, obj/item/item_to_remove, removal_verb)
	if(tool_item)
		tool_item.play_tool_sound(src)
	to_chat(user, span_notice("You [removal_verb ? removal_verb : "remove"] [item_to_remove] from [src]."))
	item_to_remove.forceMove(drop_location())

	if(Adjacent(user) && !issilicon(user))
		user.put_in_hands(item_to_remove)

	if(item_to_remove == bayonet)
		return clear_bayonet()
	else if(item_to_remove == gun_light)
		return clear_gunlight()

/obj/item/gun/proc/clear_bayonet()
	if(!bayonet)
		return
	bayonet = null
	update_appearance()
	return TRUE

/obj/item/gun/proc/clear_gunlight()
	if(!gun_light)
		return
	var/obj/item/flashlight/seclite/removed_light = gun_light
	set_gun_light(null)
	update_gunlight()
	removed_light.update_brightness()
	QDEL_NULL(alight)
	return TRUE


/**
 * Swaps the gun's seclight, dropping the old seclight if it has not been qdel'd.
 *
 * Returns the former gun_light that has now been replaced by this proc.
 * Arguments:
 * * new_light - The new light to attach to the weapon. Can be null, which will mean the old light is removed with no replacement.
 */
/obj/item/gun/proc/set_gun_light(obj/item/flashlight/seclite/new_light)
	// Doesn't look like this should ever happen? We're replacing our old light with our old light?
	if(gun_light == new_light)
		CRASH("Tried to set a new gun light when the old gun light was also the new gun light.")

	. = gun_light

	// If there's an old gun light that isn't being QDELETED, detatch and drop it to the floor.
	if(!QDELETED(gun_light))
		gun_light.set_light_flags(gun_light.light_flags & ~LIGHT_ATTACHED)
		if(gun_light.loc == src)
			gun_light.forceMove(get_turf(src))

	// If there's a new gun light to be added, attach and move it to the gun.
	if(new_light)
		new_light.set_light_flags(new_light.light_flags | LIGHT_ATTACHED)
		if(new_light.loc != src)
			new_light.forceMove(src)

	gun_light = new_light

/obj/item/gun/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, alight))
		toggle_gunlight()
	else
		..()

/obj/item/gun/proc/toggle_gunlight()
	if(!gun_light)
		return

	var/mob/living/carbon/human/user = usr
	gun_light.on = !gun_light.on
	gun_light.update_brightness()
	to_chat(user, span_notice("You toggle the gunlight [gun_light.on ? "on":"off"]."))

	playsound(user, 'sound/weapons/empty.ogg', 100, TRUE)
	update_gunlight()

/obj/item/gun/proc/update_gunlight()
	update_appearance()
	update_action_buttons()

/obj/item/gun/pickup(mob/user)
	..()
	if(azoom)
		azoom.Grant(user)

/obj/item/gun/dropped(mob/user)
	. = ..()
	if(azoom)
		azoom.Remove(user)
	if(zoomed)
		zoom(user, user.dir, FALSE)

/obj/item/gun/update_overlays()
	. = ..()
	if(gun_light)
		var/mutable_appearance/flashlight_overlay
		var/state = "[gunlight_state][gun_light.on? "_on":""]" //Generic state.
		if(gun_light.icon_state in icon_states('icons/obj/guns/flashlights.dmi')) //Snowflake state?
			state = gun_light.icon_state
		flashlight_overlay = mutable_appearance('icons/obj/guns/flashlights.dmi', state)
		flashlight_overlay.pixel_x = flight_x_offset
		flashlight_overlay.pixel_y = flight_y_offset
		. += flashlight_overlay

	if(bayonet)
		var/mutable_appearance/knife_overlay
		var/state = "bayonet" //Generic state.
		if(bayonet.icon_state in icon_states('icons/obj/guns/bayonets.dmi')) //Snowflake state?
			state = bayonet.icon_state
		var/icon/bayonet_icons = 'icons/obj/guns/bayonets.dmi'
		knife_overlay = mutable_appearance(bayonet_icons, state)
		knife_overlay.pixel_x = knife_x_offset
		knife_overlay.pixel_y = knife_y_offset
		. += knife_overlay

/obj/item/gun/proc/handle_suicide(mob/living/carbon/human/user, mob/living/carbon/human/target, params, bypass_timer)
	if(!ishuman(user) || !ishuman(target))
		return

	if(semicd)
		return

	if(user == target)
		target.visible_message(span_warning("[user] sticks [src] in [user.p_their()] mouth, ready to pull the trigger..."), \
			span_userdanger("You stick [src] in your mouth, ready to pull the trigger..."))
	else
		target.visible_message(span_warning("[user] points [src] at [target]'s head, ready to pull the trigger..."), \
			span_userdanger("[user] points [src] at your head, ready to pull the trigger..."))

	semicd = TRUE

	if(!bypass_timer && (!do_mob(user, target, 120) || user.zone_selected != BODY_ZONE_PRECISE_MOUTH))
		if(user)
			if(user == target)
				user.visible_message(span_notice("[user] decided not to shoot."))
			else if(target?.Adjacent(user))
				target.visible_message(span_notice("[user] has decided to spare [target]"), span_notice("[user] has decided to spare your life!"))
		semicd = FALSE
		return

	semicd = FALSE

	target.visible_message(span_warning("[user] pulls the trigger!"), span_userdanger("[(user == target) ? "You pull" : "[user] pulls"] the trigger!"))

	if(chambered?.loaded_projectile)
		chambered.loaded_projectile.damage *= 5
		if(chambered.loaded_projectile.wound_bonus != CANT_WOUND)
			chambered.loaded_projectile.wound_bonus += 5 // much more dramatic on multiple pellet'd projectiles really

	var/fired = process_fire(target, user, TRUE, params, BODY_ZONE_HEAD)
	if(!fired && chambered?.loaded_projectile)
		chambered.loaded_projectile.damage /= 5
		if(chambered.loaded_projectile.wound_bonus != CANT_WOUND)
			chambered.loaded_projectile.wound_bonus -= 5

/obj/item/gun/proc/unlock() //used in summon guns and as a convience for admins
	if(pin)
		qdel(pin)
	pin = new /obj/item/firing_pin

//Happens before the actual projectile creation
/obj/item/gun/proc/before_firing(atom/target,mob/user)
	return

/////////////
// ZOOMING //
/////////////

/datum/action/toggle_scope_zoom
	name = "Toggle Scope"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	var/obj/item/gun/gun = null

/datum/action/toggle_scope_zoom/Trigger()
	. = ..()
	if(!.)
		return
	gun.zoom(owner, owner.dir)

/datum/action/toggle_scope_zoom/IsAvailable()
	. = ..()
	if(owner.get_active_held_item() != gun)
		. = FALSE
	if(!. && gun)
		gun.zoom(owner, owner.dir, FALSE)

/datum/action/toggle_scope_zoom/Remove(mob/living/L)
	gun.zoom(L, L.dir, FALSE)
	..()

/obj/item/gun/proc/rotate(atom/thing, old_dir, new_dir)
	SIGNAL_HANDLER

	if(ismob(thing))
		var/mob/lad = thing
		lad.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)

/obj/item/gun/proc/zoom(mob/living/user, direc, forced_zoom)
	if(!user || !user.client)
		return

	if(isnull(forced_zoom))
		zoomed = !zoomed
	else
		zoomed = forced_zoom

	if(zoomed)
		RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate))
		user.client.view_size.zoomOut(zoom_out_amt, zoom_amt, direc)
	else
		UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
		user.client.view_size.zoomIn()
	return zoomed

//Proc, so that gun accessories/scopes/etc. can easily add zooming.
/obj/item/gun/proc/build_zooming()
	if(azoom)
		return

	if(zoomable)
		azoom = new()
		azoom.gun = src

#undef FIRING_PIN_REMOVAL_DELAY
#undef DUALWIELD_PENALTY_EXTRA_MULTIPLIER
