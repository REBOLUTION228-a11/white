#define MOTH_EATING_CLOTHING_DAMAGE 15

/obj/item/clothing
	name = "кусок ткани"
	resistance_flags = FLAMMABLE
	max_integrity = 200
	integrity_failure = 0.4
	var/damaged_clothes = CLOTHING_PRISTINE //similar to machine's BROKEN stat and structure's broken var

	///What level of bright light protection item has.
	var/flash_protect = FLASH_PROTECTION_NONE
	var/tint = 0				//Sets the item's level of visual impairment tint, normally set to the same as flash_protect
	var/up = 0					//but separated to allow items to protect but not impair vision, like space helmets
	var/visor_flags = 0			//flags that are added/removed when an item is adjusted up/down
	var/visor_flags_inv = 0		//same as visor_flags, but for flags_inv
	var/visor_flags_cover = 0	//same as above, but for flags_cover
//what to toggle when toggled with weldingvisortoggle()
	var/visor_vars_to_toggle = VISOR_FLASHPROTECT | VISOR_TINT | VISOR_VISIONFLAGS | VISOR_DARKNESSVIEW | VISOR_INVISVIEW
	lefthand_file = 'icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing_righthand.dmi'
	var/alt_desc = null
	var/toggle_message = null
	var/alt_toggle_message = null
	var/toggle_cooldown = null
	var/cooldown = 0

	var/clothing_flags = NONE

	var/can_be_bloody = TRUE

	/// What items can be consumed to repair this clothing (must by an /obj/item/stack)
	var/repairable_by = /obj/item/stack/sheet/cloth

	//Var modification - PLEASE be careful with this I know who you are and where you live
	var/list/user_vars_to_edit //VARNAME = VARVALUE eg: "name" = "butts"
	var/list/user_vars_remembered //Auto built by the above + dropped() + equipped()

	/// Trait modification, lazylist of traits to add/take away, on equipment/drop in the correct slot
	var/list/clothing_traits

	var/pocket_storage_component_path

	//These allow head/mask items to dynamically alter the user's hair
	// and facial hair, checking hair_extensions.dmi and facialhair_extensions.dmi
	// for a state matching hair_state+dynamic_hair_suffix
	// THESE OVERRIDE THE HIDEHAIR FLAGS
	var/dynamic_hair_suffix = ""//head > mask for head hair
	var/dynamic_fhair_suffix = ""//mask > head for facial hair

	///These are armor values that protect the wearer, taken from the clothing's armor datum. List updates on examine because it's currently only used to print armor ratings to chat in Topic().
	var/list/armor_list = list()
	///These are armor values that protect the clothing, taken from its armor datum. List updates on examine because it's currently only used to print armor ratings to chat in Topic().
	var/list/durability_list = list()

	/// How much clothing damage has been dealt to each of the limbs of the clothing, assuming it covers more than one limb
	var/list/damage_by_parts
	/// How much integrity is in a specific limb before that limb is disabled (for use in [/obj/item/clothing/proc/take_damage_zone], and only if we cover multiple zones.) Set to 0 to disable shredding.
	var/limb_integrity = 0
	/// How many zones (body parts, not precise) we have disabled so far, for naming purposes
	var/zones_disabled

	/// A lazily initiated "food" version of the clothing for moths
	var/obj/item/food/clothing/moth_snack

/obj/item/clothing/Initialize()
	if((clothing_flags & VOICEBOX_TOGGLABLE))
		actions_types += /datum/action/item_action/toggle_voice_box
	. = ..()
	if(ispath(pocket_storage_component_path))
		LoadComponent(pocket_storage_component_path)
	if(can_be_bloody && ((body_parts_covered & FEET) || (flags_inv & HIDESHOES)))
		LoadComponent(/datum/component/bloodysoles)
	if(!icon_state)
		item_flags |= ABSTRACT

/obj/item/clothing/MouseDrop(atom/over_object)
	. = ..()
	var/mob/M = usr

	if(ismecha(M.loc)) // stops inventory actions in a mech
		return

	if(!M.incapacitated() && loc == M && istype(over_object, /atom/movable/screen/inventory/hand))
		var/atom/movable/screen/inventory/hand/H = over_object
		if(M.putItemFromInventoryInHandIfPossible(src, H.held_index))
			add_fingerprint(usr)

//This code is cursed, moths are cursed, and someday I will destroy it. but today is not that day.
/obj/item/food/clothing
	name = "temporary moth clothing snack item"
	desc = "If you're reading this it means I messed up. This is related to moths eating clothes and I didn't know a better way to do it than making a new food object. <--- stinky idiot wrote this"
	bite_consumption = 1
	// sigh, ok, so it's not ACTUALLY infinite nutrition. this is so you can eat clothes more than...once.
	// bite_consumption limits how much you actually get, and the take_damage in after eat makes sure you can't abuse this.
	// ...maybe this was a mistake after all.
	food_reagents = list(/datum/reagent/consumable/nutriment = INFINITY)
	tastes = list("пыль" = 1, "волокна" = 1)
	foodtypes = CLOTH

	/// A weak reference to the clothing that created us
	var/datum/weakref/clothing

/obj/item/food/clothing/MakeEdible()
	AddComponent(/datum/component/edible,\
		initial_reagents = food_reagents,\
		food_flags = food_flags,\
		foodtypes = foodtypes,\
		volume = max_volume,\
		eat_time = eat_time,\
		tastes = tastes,\
		eatverbs = eatverbs,\
		bite_consumption = bite_consumption,\
		microwaved_type = microwaved_type,\
		junkiness = junkiness,\
		after_eat = CALLBACK(src, PROC_REF(after_eat)))

/obj/item/food/clothing/proc/after_eat(mob/eater)
	var/obj/item/clothing/resolved_clothing = clothing.resolve()
	if (resolved_clothing)
		resolved_clothing.take_damage(MOTH_EATING_CLOTHING_DAMAGE, sound_effect = FALSE, damage_flag = CONSUME)
	else
		qdel(src)

/obj/item/clothing/attack(mob/attacker, mob/user, def_zone)
	if(user.a_intent != INTENT_HARM && ismoth(attacker))
		if (isnull(moth_snack))
			moth_snack = new
			moth_snack.name = name
			moth_snack.clothing = WEAKREF(src)
		moth_snack.attack(attacker, user, def_zone)
	else
		return ..()

/obj/item/clothing/attackby(obj/item/W, mob/user, params)
	if(!istype(W, repairable_by))
		return ..()

	switch(damaged_clothes)
		if(CLOTHING_PRISTINE)
			return..()
		if(CLOTHING_DAMAGED)
			var/obj/item/stack/cloth_repair = W
			cloth_repair.use(1)
			repair(user, params)
			return TRUE
		if(CLOTHING_SHREDDED)
			var/obj/item/stack/cloth_repair = W
			if(cloth_repair.amount < 3)
				to_chat(user, span_warning("Мне потребуется 3 единицы [W.name] для починки [src.name]."))
				return TRUE
			to_chat(user, span_notice("Начинаю чинить повреждения [src.name] используя [cloth_repair]..."))
			if(!do_after(user, 6 SECONDS, src) || !cloth_repair.use(3))
				return TRUE
			repair(user, params)
			return TRUE

	return ..()

/// Set the clothing's integrity back to 100%, remove all damage to bodyparts, and generally fix it up
/obj/item/clothing/proc/repair(mob/user, params)
	update_clothes_damaged_state(CLOTHING_PRISTINE)
	obj_integrity = max_integrity
	name = initial(name) // remove "tattered" or "shredded" if there's a prefix
	body_parts_covered = initial(body_parts_covered)
	slot_flags = initial(slot_flags)
	damage_by_parts = null
	if(user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		to_chat(user, span_notice("Чиню повреждения [src]."))

/**
 * take_damage_zone() is used for dealing damage to specific bodyparts on a worn piece of clothing, meant to be called from [/obj/item/bodypart/proc/check_woundings_mods]
 *
 *	This proc only matters when a bodypart that this clothing is covering is harmed by a direct attack (being on fire or in space need not apply), and only if this clothing covers
 * more than one bodypart to begin with. No point in tracking damage by zone for a hat, and I'm not cruel enough to let you fully break them in a few shots.
 * Also if limb_integrity is 0, then this clothing doesn't have bodypart damage enabled so skip it.
 *
 * Arguments:
 * * def_zone: The bodypart zone in question
 * * damage_amount: Incoming damage
 * * damage_type: BRUTE or BURN
 * * armour_penetration: If the attack had armour_penetration
 */
/obj/item/clothing/proc/take_damage_zone(def_zone, damage_amount, damage_type, armour_penetration)
	if(!def_zone || !limb_integrity || (initial(body_parts_covered) in GLOB.bitflags)) // the second check sees if we only cover one bodypart anyway and don't need to bother with this
		return
	var/list/covered_limbs = body_parts_covered2organ_names(body_parts_covered) // what do we actually cover?
	if(!(def_zone in covered_limbs))
		return

	var/damage_dealt = take_damage(damage_amount * 0.1, damage_type, armour_penetration, FALSE) * 10 // only deal 10% of the damage to the general integrity damage, then multiply it by 10 so we know how much to deal to limb
	LAZYINITLIST(damage_by_parts)
	damage_by_parts[def_zone] += damage_dealt
	if(damage_by_parts[def_zone] > limb_integrity)
		disable_zone(def_zone, damage_type)

/**
 * disable_zone() is used to disable a given bodypart's protection on our clothing item, mainly from [/obj/item/clothing/proc/take_damage_zone]
 *
 * This proc disables all protection on the specified bodypart for this piece of clothing: it'll be as if it doesn't cover it at all anymore (because it won't!)
 * If every possible bodypart has been disabled on the clothing, we put it out of commission entirely and mark it as shredded, whereby it will have to be repaired in
 * order to equip it again. Also note we only consider it damaged if there's more than one bodypart disabled.
 *
 * Arguments:
 * * def_zone: The bodypart zone we're disabling
 * * damage_type: Only really relevant for the verb for describing the breaking, and maybe obj_destruction()
 */
/obj/item/clothing/proc/disable_zone(def_zone, damage_type)
	var/list/covered_limbs = body_parts_covered2organ_names(body_parts_covered)
	if(!(def_zone in covered_limbs))
		return

	var/zone_name = parse_zone(def_zone)
	var/break_verb = ((damage_type == BRUTE) ? "отрывается" : "сгорает")

	if(iscarbon(loc))
		var/mob/living/carbon/C = loc
		C.visible_message(span_danger("[capitalize(zone_name)] [src.name] на [C] [break_verb]!"), span_userdanger("[capitalize(zone_name)] [src.name] [break_verb]!"), vision_distance = COMBAT_MESSAGE_RANGE)
		RegisterSignal(C, COMSIG_MOVABLE_MOVED, PROC_REF(bristle), override = TRUE)

	zones_disabled++
	for(var/i in zone2body_parts_covered(def_zone))
		body_parts_covered &= ~i

	if(body_parts_covered == NONE) // if there are no more parts to break then the whole thing is kaput
		obj_destruction((damage_type == BRUTE ? MELEE : LASER)) // melee/laser is good enough since this only procs from direct attacks anyway and not from fire/bombs
		return

	switch(zones_disabled)
		if(1)
			name = "поврежденный [initial(name)]"
		if(2)
			name = "облезший [initial(name)]"
		if(3 to INFINITY) // take better care of your shit, dude
			name = "рваный [initial(name)]"

	update_clothes_damaged_state(CLOTHING_DAMAGED)

/obj/item/clothing/Destroy()
	user_vars_remembered = null //Oh god somebody put REFERENCES in here? not to worry, we'll clean it up
	QDEL_NULL(moth_snack)
	return ..()

/obj/item/clothing/dropped(mob/living/user)
	..()
	if(!istype(user))
		return
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	for(var/trait in clothing_traits)
		REMOVE_TRAIT(user, trait, "[CLOTHING_TRAIT] [REF(src)]")

	if(LAZYLEN(user_vars_remembered))
		for(var/variable in user_vars_remembered)
			if(variable in user.vars)
				if(user.vars[variable] == user_vars_to_edit[variable]) //Is it still what we set it to? (if not we best not change it)
					user.vars[variable] = user_vars_remembered[variable]
		user_vars_remembered = initial(user_vars_remembered) // Effectively this sets it to null.

/obj/item/clothing/equipped(mob/living/user, slot)
	. = ..()
	if (!istype(user))
		return
	if(slot_flags & slot) //Was equipped to a valid slot for this item?
		if(iscarbon(user) && LAZYLEN(zones_disabled))
			RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(bristle), override = TRUE)
		for(var/trait in clothing_traits)
			ADD_TRAIT(user, trait, "[CLOTHING_TRAIT] [REF(src)]")
		if (LAZYLEN(user_vars_to_edit))
			for(var/variable in user_vars_to_edit)
				if(variable in user.vars)
					LAZYSET(user_vars_remembered, variable, user.vars[variable])
					user.vv_edit_var(variable, user_vars_to_edit[variable])

/obj/item/clothing/examine(mob/user)
	. = ..()

	. += "<hr>"

	if(damaged_clothes == CLOTHING_SHREDDED)
		. += span_warning("<b>Полностью разорвано и требует починки!</b>")
		return

	switch (max_heat_protection_temperature)
		if (400 to 1000)
			. += span_smallnotice("[capitalize(src.name)] немного защищает от огня.")
		if (1001 to 1600)
			. += span_notice("[capitalize(src.name)] может защитить от огня.")
		if (1601 to 35000)
			. += span_smalldanger("[capitalize(src.name)] неплохо защищает от огня.")

	for(var/zone in damage_by_parts)
		var/pct_damage_part = damage_by_parts[zone] / limb_integrity * 100
		var/zone_name = parse_zone(zone)
		switch(pct_damage_part)
			if(100 to INFINITY)
				. += span_smalldanger(span_warning("<b>[capitalize(zone_name)] [src.name] разорвана в клочья!</b>"))
			if(60 to 99)
				. += span_notice(span_warning("[capitalize(zone_name)] [src.name] сильно потрёпана!"))
			if(30 to 59)
				. += span_smallnotice(span_danger("[capitalize(zone_name)] [src.name] немного порвана."))

	var/datum/component/storage/pockets = GetComponent(/datum/component/storage)
	if(pockets)
		var/list/how_cool_are_your_threads = list("<hr><span class='notice'>")
		if(pockets.attack_hand_interact)
			how_cool_are_your_threads += "[capitalize(src.name)] показывает хранилище при клике.\n"
		else
			how_cool_are_your_threads += "[capitalize(src.name)] показывает хранилище при перетягивании на себя.\n"
		if (pockets.can_hold?.len) // If pocket type can hold anything, vs only specific items
			how_cool_are_your_threads += "[capitalize(src.name)] может хранить [pockets.max_items] <a href='?src=[REF(src)];show_valid_pocket_items=1'>предметов</a>.\n"
		else
			how_cool_are_your_threads += "[capitalize(src.name)] может хранить [pockets.max_items] [weightclass2text(pockets.max_w_class)] размера или меньше.\n"
		if(pockets.quickdraw)
			how_cool_are_your_threads += "Могу быстро вытащить предмет из [src] используя ПКМ.\n"
		if(pockets.silent)
			how_cool_are_your_threads += "Добавление или изъятие предметов из [src] не издаёт шума.\n"
		how_cool_are_your_threads += "</span>"
		. += how_cool_are_your_threads.Join()

	if(LAZYLEN(armor_list))
		armor_list.Cut()
	if(armor.bio)
		armor_list += list("ТОКСИНЫ" = armor.bio)
	if(armor.bomb)
		armor_list += list("ВЗРЫВЫ" = armor.bomb)
	if(armor.bullet)
		armor_list += list("ПУЛИ" = armor.bullet)
	if(armor.energy)
		armor_list += list("ЭНЕРГЕТИЧЕСКОЕ" = armor.energy)
	if(armor.laser)
		armor_list += list("ЛАЗЕР" = armor.laser)
	if(armor.magic)
		armor_list += list("МАГИЯ" = armor.magic)
	if(armor.melee)
		armor_list += list("УДАРЫ" = armor.melee)
	if(armor.rad)
		armor_list += list("РАДИАЦИЯ" = armor.rad)

	if(LAZYLEN(durability_list))
		durability_list.Cut()
	if(armor.fire)
		durability_list += list("ОГОНЬ" = armor.fire)
	if(armor.acid)
		durability_list += list("КИСЛОТА" = armor.acid)

	if(LAZYLEN(armor_list) || LAZYLEN(durability_list))
		. += "<hr><span class='notice'>Здесь есть <a href='?src=[REF(src)];list_armor=1'>бирка</a> с описанием защитных свойств.</span>"

/obj/item/clothing/Topic(href, href_list)
	. = ..()

	if(href_list["list_armor"])
		var/list/readout = list("<table class='examine_block'><tr><td><span class='notice'><u><b>ЗАЩИТНЫЕ КЛАССЫ (I-X)</u></b></span></td></tr>")
		if(LAZYLEN(armor_list))
			readout += "<tr><td><b>БРОНЯ:</b></td></tr>"
			for(var/dam_type in armor_list)
				var/armor_amount = armor_list[dam_type]
				readout += "<tr><td>\t[dam_type]</td><td>[armor_to_protection_class(armor_amount)]</td></tr>" //e.g. BOMB IV
		if(LAZYLEN(durability_list))
			readout += "<tr><td><b>СТОЙКОСТЬ:</b></td></tr>"
			for(var/dam_type in durability_list)
				var/durability_amount = durability_list[dam_type]
				readout += "<tr><td>\t[dam_type]</td><td>[armor_to_protection_class(durability_amount)]</td></tr>" //e.g. FIRE II
		readout += "</span></table>"

		to_chat(usr, "[readout.Join()]")

/**
 * Rounds armor_value to nearest 10, divides it by 10 and then expresses it in roman numerals up to 10
 *
 * Rounds armor_value to nearest 10, divides it by 10
 * and then expresses it in roman numerals up to 10
 * Arguments:
 * * armor_value - Number we're converting
 */
/obj/item/clothing/proc/armor_to_protection_class(armor_value)
	armor_value = round(armor_value,10) / 10
	switch (armor_value)
		if (1)
			. = "I"
		if (2)
			. = "II"
		if (3)
			. = "III"
		if (4)
			. = "IV"
		if (5)
			. = "V"
		if (6)
			. = "VI"
		if (7)
			. = "VII"
		if (8)
			. = "VIII"
		if (9)
			. = "IX"
		if (10 to INFINITY)
			. = "X"
	return .

/obj/item/clothing/obj_break(damage_flag)
	update_clothes_damaged_state(CLOTHING_DAMAGED)

	if(isliving(loc)) //It's not important enough to warrant a message if it's not on someone
		var/mob/living/M = loc
		if(src in M.get_equipped_items(FALSE))
			to_chat(M, span_warning("Мой [name] начинает распадаться на части!"))
		else
			to_chat(M, span_warning("[capitalize(src.name)] начинает распадаться на части!"))

//This mostly exists so subtypes can call appriopriate update icon calls on the wearer.
/obj/item/clothing/proc/update_clothes_damaged_state(damaged_state = CLOTHING_DAMAGED)
	damaged_clothes = damaged_state

/obj/item/clothing/update_overlays()
	. = ..()
	if(damaged_clothes)
		var/index = "[REF(icon)]-[icon_state]"
		var/static/list/damaged_clothes_icons = list()
		var/icon/damaged_clothes_icon = damaged_clothes_icons[index]
		if(!damaged_clothes_icon)
			damaged_clothes_icon = icon(icon, icon_state, , 1)
			damaged_clothes_icon.Blend("#fff", ICON_ADD) 	//fills the icon_state with white (except where it's transparent)
			damaged_clothes_icon.Blend(icon('icons/effects/item_damage.dmi', "itemdamaged"), ICON_MULTIPLY) //adds damage effect and the remaining white areas become transparant
			damaged_clothes_icon = fcopy_rsc(damaged_clothes_icon)
			damaged_clothes_icons[index] = damaged_clothes_icon
		. += damaged_clothes_icon

/*
SEE_SELF  // can see self, no matter what
SEE_MOBS  // can see all mobs, no matter what
SEE_OBJS  // can see all objs, no matter what
SEE_TURFS // can see all turfs (and areas), no matter what
SEE_PIXELS// if an object is located on an unlit area, but some of its pixels are
		// in a lit area (via pixel_x,y or smooth movement), can see those pixels
BLIND     // can't see anything
*/

/proc/generate_female_clothing(index, t_color, icon, type)
	var/icon/female_clothing_icon	= icon("icon"=icon, "icon_state"=t_color)
	var/icon/female_s				= icon("icon"='icons/mob/clothing/under/masking_helpers.dmi', "icon_state"="[(type == FEMALE_UNIFORM_FULL) ? "female_full" : "female_top"]")
	female_clothing_icon.Blend(female_s, ICON_MULTIPLY)
	female_clothing_icon 			= fcopy_rsc(female_clothing_icon)
	GLOB.female_clothing_icons[index] = female_clothing_icon

/obj/item/clothing/proc/weldingvisortoggle(mob/user) //proc to toggle welding visors on helmets, masks, goggles, etc.
	if(!can_use(user))
		return FALSE

	visor_toggling()

	to_chat(user, span_notice("[up ? "Поднимаю" : "Опускаю"] забрало [src]."))

	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.head_update(src, forced = 1)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()
	return TRUE

/obj/item/clothing/proc/visor_toggling() //handles all the actual toggling of flags
	up = !up
	SEND_SIGNAL(src, COMSIG_CLOTHING_VISOR_TOGGLE, up)
	clothing_flags ^= visor_flags
	flags_inv ^= visor_flags_inv
	flags_cover ^= initial(flags_cover)
	icon_state = "[initial(icon_state)][up ? "up" : ""]"
	if(visor_vars_to_toggle & VISOR_FLASHPROTECT)
		flash_protect ^= initial(flash_protect)
	if(visor_vars_to_toggle & VISOR_TINT)
		tint ^= initial(tint)

/obj/item/clothing/head/helmet/space/plasmaman/visor_toggling() //handles all the actual toggling of flags
	up = !up
	SEND_SIGNAL(src, COMSIG_CLOTHING_VISOR_TOGGLE, up)
	clothing_flags ^= visor_flags
	flags_inv ^= visor_flags_inv
	icon_state = "[initial(icon_state)]"
	if(visor_vars_to_toggle & VISOR_FLASHPROTECT)
		flash_protect ^= initial(flash_protect)
	if(visor_vars_to_toggle & VISOR_TINT)
		tint ^= initial(tint)

/obj/item/clothing/proc/can_use(mob/user)
	if(user && ismob(user))
		if(!user.incapacitated())
			return 1
	return 0

/obj/item/clothing/proc/_spawn_shreds()
	new /obj/effect/decal/cleanable/shreds(get_turf(src), name)

/obj/item/clothing/obj_destruction(damage_flag)
	if(damage_flag == BOMB)
		//so the shred survives potential turf change from the explosion.
		addtimer(CALLBACK(src, PROC_REF(_spawn_shreds)), 1)
		deconstruct(FALSE)
	if(damage_flag == CONSUME) //This allows for moths to fully consume clothing, rather than damaging it like other sources like brute
		var/turf/current_position = get_turf(src)
		new /obj/effect/decal/cleanable/shreds(current_position, name)
		if(isliving(loc))
			var/mob/living/possessing_mob = loc
			possessing_mob.visible_message(span_danger("[src] is consumed until naught but shreds remains!"), span_boldwarning("[src] falls apart into little bits!"))
		deconstruct(FALSE)
	else if(!(damage_flag in list(ACID, FIRE)))
		body_parts_covered = NONE
		slot_flags = NONE
		update_clothes_damaged_state(CLOTHING_SHREDDED)
		if(isliving(loc))
			var/mob/living/M = loc
			if(src in M.get_equipped_items(FALSE)) //make sure they were wearing it and not attacking the item in their hands / eating it if they were a moth.
				M.visible_message(span_danger("[capitalize(src.name)] [M] распадается на части!"), span_warning("<b>[capitalize(src.name)] распадается на части!</b>"), vision_distance = COMBAT_MESSAGE_RANGE)
				M.dropItemToGround(src)
			else
				M.visible_message(span_danger("[capitalize(src.name)] распадается на части!"), vision_distance = COMBAT_MESSAGE_RANGE)
		name = "изорванный [initial(name)]" // change the name -after- the message, not before.
	else
		..()

/// If we're a clothing with at least 1 shredded/disabled zone, give the wearer a periodic heads up letting them know their clothes are damaged
/obj/item/clothing/proc/bristle(mob/living/L)
	SIGNAL_HANDLER

	if(!istype(L))
		return
	if(prob(0.2))
		to_chat(L, span_warning("Порванные нитки на [src.name] шевелятся!"))

#undef MOTH_EATING_CLOTHING_DAMAGE
