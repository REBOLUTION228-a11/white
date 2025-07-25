/obj/item/shield
	name = "щит"
	icon = 'icons/obj/shields.dmi'
	block_chance = 75
	armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 0, BOMB = 30, BIO = 0, RAD = 0, FIRE = 80, ACID = 70)
	var/transparent = FALSE	// makes beam projectiles pass through the shield
	block_sounds = list('white/valtos/sounds/shieldhit1.wav', 'white/valtos/sounds/shieldhit2.wav')

/obj/item/shield/proc/on_shield_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", damage = 0, attack_type = MELEE_ATTACK)
	if(damage)
		owner.adjustStaminaLoss(damage/2)
	return TRUE

/obj/item/shield/riot
	name = "защитный щит"
	desc = "Щит умеет блокировать тупые предметы от соединения с туловищем владельца щита."
	icon_state = "riot"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	slot_flags = ITEM_SLOT_BACK
	force = 10
	throwforce = 5
	throw_speed = 2
	throw_range = 3
	w_class = WEIGHT_CLASS_BULKY
	custom_materials = list(/datum/material/glass=7500, /datum/material/iron=1000)
	attack_verb_continuous = list("толкает", "бьёт")
	attack_verb_simple = list("толкает", "бьёт")
	var/cooldown = 0 //shield bash cooldown. based on world.time
	transparent = TRUE
	max_integrity = 75
	material_flags = MATERIAL_NO_EFFECTS

/obj/item/shield/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(transparent && (hitby.pass_flags & PASSGLASS))
		return FALSE
	if(isprojectile(hitby))
		var/obj/projectile/P = hitby
		if(!defense_check(get_turf(owner), get_turf(P?.fired_from), owner?.dir))
			return FALSE
	else if(!defense_check(get_turf(owner), get_turf(hitby), owner?.dir))
		return FALSE
	if(attack_type == THROWN_PROJECTILE_ATTACK)
		final_block_chance += 30
	if(attack_type == LEAP_ATTACK)
		final_block_chance = 100
	. = ..()
	if(.)
		on_shield_block(owner, hitby, attack_text, damage, attack_type)

/obj/item/shield/proc/defense_check(turf/aloc, turf/bloc, mobdir)
	. = FALSE
	switch(mobdir)
		if (1)
			if(abs(aloc.x - bloc.x) <= (aloc.y - bloc.y) * -2)
				. = TRUE
		if (2)
			if(abs(aloc.x - bloc.x) <= (aloc.y - bloc.y) * 2)
				. = TRUE
		if (4)
			if(abs(aloc.y - bloc.y) <= (aloc.x - bloc.x) * -2)
				. = TRUE
		if (8)
			if(abs(aloc.y - bloc.y) <= (aloc.x - bloc.x) * 2)
				. = TRUE
	return

/obj/item/shield/riot/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/melee/baton))
		if(cooldown < world.time - 25)
			user.visible_message(span_warning("<b>[user]</b> бьёт <b>[src.name]</b> используя [W]!"))
			playsound(user.loc, 'sound/effects/shieldbash.ogg', 50, TRUE)
			cooldown = world.time
	else if(istype(W, /obj/item/stack/sheet/mineral/titanium))
		if (obj_integrity >= max_integrity)
			to_chat(user, span_warning("<b>[src.name]</b> уже в превосходном состоянии."))
		else
			var/obj/item/stack/sheet/mineral/titanium/T = W
			T.use(1)
			obj_integrity = max_integrity
			to_chat(user, span_notice("Чиню <b>[src.name]</b> используя <b>[T]</b>."))
	else
		return ..()

/obj/item/shield/riot/examine(mob/user)
	. = ..()
	var/healthpercent = round((obj_integrity/max_integrity) * 100, 1)
	switch(healthpercent)
		if(50 to 99)
			. += "<hr><span class='info'>Виднеются небольшие царапины.</span>"
		if(25 to 50)
			. += "<hr><span class='info'>Выглядит серьёзно повреждённым.</span>"
		if(0 to 25)
			. += "<hr><span class='warning'>Вот-вот развалится!</span>"

/obj/item/shield/riot/proc/shatter(mob/living/carbon/human/owner)
	playsound(owner, 'sound/effects/glassbr3.ogg', 100)
	new /obj/item/shard((get_turf(src)))

/obj/item/shield/riot/on_shield_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", damage = 0, attack_type = MELEE_ATTACK)
	if (obj_integrity <= damage)
		var/turf/T = get_turf(owner)
		T.visible_message(span_warning("<b>[capitalize(hitby.name)]</b> уничтожает <b>[src.name]</b>!"))
		shatter(owner)
		qdel(src)
		return FALSE
	take_damage(damage)
	return ..()

/obj/item/shield/riot/military
	name = "титановый щит"
	desc = "Очень крепкий и очень тяжёлый. Используется для самых тактичных тактических операций."
	slot_flags = NONE
	force = 15
	block_chance = 90
	transparent = FALSE
	max_integrity = 400
	custom_materials = list(/datum/material/titanium = 10000)
	icon_state = "ops_shield"
	inhand_icon_state = "ops_shield"
	icon = 'white/valtos/icons/objects.dmi'
	lefthand_file = 'white/valtos/icons/lefthand.dmi'
	righthand_file = 'white/valtos/icons/righthand.dmi'

/obj/item/shield/riot/military/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/obj/item/shield/riot/military/pickup(mob/user)
	. = ..()
	if(isliving(user))
		var/mob/living/L = user
		L.add_movespeed_modifier(/datum/movespeed_modifier/heavy_shield)

/obj/item/shield/riot/military/dropped(mob/user, silent)
	. = ..()
	if(isliving(user))
		var/mob/living/L = user
		//if we're not holding object of type /obj/item/shield/riot/military in any of our two available hands,
		if(!istype(L.held_items[1], /obj/item/shield/riot/military) && !istype(L.held_items[2], /obj/item/shield/riot/military))
			//remove the slowdown.
			L.remove_movespeed_modifier(/datum/movespeed_modifier/heavy_shield)
			//yes, this is a crutch. fite me
/datum/movespeed_modifier/heavy_shield
	multiplicative_slowdown = 1

/obj/item/shield/riot/kevlar
	name = "кевларовый щит"
	desc = "Крепкий и достаточно лёгкий."
	force = 8
	block_chance = 80
	transparent = FALSE
	max_integrity = 250
	icon_state = "kevlarshield"
	inhand_icon_state = "kevlarshield"
	worn_icon_state = "kevlarshield"
	custom_materials = list(/datum/material/iron = 7500, /datum/material/plastic = 2500)
	icon = 'white/valtos/icons/objects.dmi'
	worn_icon = 'white/valtos/icons/weapons/mob/back.dmi'
	lefthand_file = 'white/valtos/icons/lefthand.dmi'
	righthand_file = 'white/valtos/icons/righthand.dmi'

/obj/item/shield/riot/roman
	name = "Римский щит"
	desc = "На внутренней стороне надпись: <i>\"Romanes venio domus\"</i>."
	icon_state = "roman_shield"
	inhand_icon_state = "roman_shield"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	transparent = FALSE
	custom_materials = list(/datum/material/iron=8500)
	max_integrity = 65

/obj/item/shield/riot/roman/fake
	desc = "На внутренней стороне надпись: <i>\"Romanes venio domus\"</i>. Это кажется немного хрупким."
	block_chance = 0
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	max_integrity = 30

/obj/item/shield/riot/roman/shatter(mob/living/carbon/human/owner)
	playsound(owner, 'sound/effects/grillehit.ogg', 100)
	new /obj/item/stack/sheet/iron(get_turf(src))

/obj/item/shield/riot/buckler
	name = "деревянный баклер"
	desc = "Средневековый деревянный баклер."
	icon_state = "buckler"
	inhand_icon_state = "buckler"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	custom_materials = list(/datum/material/wood = MINERAL_MATERIAL_AMOUNT * 10)
	resistance_flags = FLAMMABLE
	block_chance = 60
	transparent = FALSE
	max_integrity = 55
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/shield/riot/buckler/shatter(mob/living/carbon/human/owner)
	playsound(owner, 'sound/effects/bang.ogg', 50)
	new /obj/item/stack/sheet/mineral/wood(get_turf(src))

/obj/item/shield/riot/flash
	name = "ослепляющий щит"
	desc = "Щит со встроенным высокоинтенсивным светом, способным ослеплять и дезориентировать подозреваемых. Принимает обычные ручные флэшки в виде лампочек."
	icon_state = "flashshield"
	inhand_icon_state = "flashshield"
	var/obj/item/assembly/flash/handheld/embedded_flash

/obj/item/shield/riot/flash/Initialize()
	. = ..()
	embedded_flash = new(src)

/obj/item/shield/riot/flash/ComponentInitialize()
	. = .. ()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/shield/riot/flash/attack(mob/living/M, mob/user)
	. =  embedded_flash.attack(M, user)
	update_icon()

/obj/item/shield/riot/flash/attack_self(mob/living/carbon/user)
	. = embedded_flash.attack_self(user)
	update_icon()

/obj/item/shield/riot/flash/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if (. && !embedded_flash.burnt_out)
		embedded_flash.activate()
		update_icon()


/obj/item/shield/riot/flash/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/assembly/flash/handheld))
		var/obj/item/assembly/flash/handheld/flash = W
		if(flash.burnt_out)
			to_chat(user, span_warning("Нет смысла заменять её сломанной лампочкой!"))
			return
		else
			to_chat(user, span_notice("Начинаю заменять лампочку..."))
			if(do_after(user, 20, target = user))
				if(flash.burnt_out || !flash || QDELETED(flash))
					return
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				qdel(embedded_flash)
				embedded_flash = flash
				flash.forceMove(src)
				update_icon()
				return
	..()

/obj/item/shield/riot/flash/emp_act(severity)
	. = ..()
	embedded_flash.emp_act(severity)
	update_icon()

/obj/item/shield/riot/flash/update_icon_state()
	if(!embedded_flash || embedded_flash.burnt_out)
		icon_state = "riot"
		inhand_icon_state = "riot"
	else
		icon_state = "flashshield"
		inhand_icon_state = "flashshield"

/obj/item/shield/riot/flash/examine(mob/user)
	. = ..()
	if (embedded_flash?.burnt_out)
		. += "<hr><span class='info'>Установленная лампа перегорела. Стоит попробовать заменить её на новую.</span>"

/obj/item/shield/energy
	name = "энергетический боевой щит"
	desc = "Щит, который отражает все энергетические снаряды, но бесполезен против физических атак. Его можно убирать, расширять и хранить где угодно."
	icon_state = "eshield"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	attack_verb_continuous = list("толкает", "бьёт")
	attack_verb_simple = list("толкает", "бьёт")
	throw_range = 5
	force = 3
	throwforce = 3
	throw_speed = 3

	/// Whether the shield is currently extended and protecting the user.
	var/enabled = FALSE
	/// Force of the shield when active.
	var/active_force = 10
	/// Throwforce of the shield when active.
	var/active_throwforce = 8
	/// Throwspeed of ethe shield when active.
	var/active_throw_speed = 2
	/// Whether clumsy people can transform this without side effects.
	var/can_clumsy_use = FALSE

/obj/item/shield/energy/Initialize()
	. = ..()
	AddComponent(/datum/component/transforming, \
		force_on = active_force, \
		throwforce_on = active_throwforce, \
		throw_speed_on = active_throw_speed, \
		hitsound_on = hitsound, \
		clumsy_check = !can_clumsy_use)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/shield/energy/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	return FALSE

/obj/item/shield/energy/IsReflect()
	return enabled

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 */
/obj/item/shield/energy/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	enabled = active

	balloon_alert(user, "[name] [active ? "activated":"deactivated"]")
	playsound(user ? user : src, active ? 'sound/weapons/saberon.ogg' : 'sound/weapons/saberoff.ogg', 35, TRUE)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/shield/riot/tele
	name = "telescopic shield"
	desc = "An advanced riot shield made of lightweight materials that collapses for easy storage."
	icon_state = "teleriot"
	worn_icon_state = "teleriot"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	custom_materials = list(/datum/material/iron = 3600, /datum/material/glass = 3600, /datum/material/silver = 270, /datum/material/titanium = 180)
	slot_flags = null
	force = 3
	throwforce = 3
	throw_speed = 3
	throw_range = 4
	w_class = WEIGHT_CLASS_NORMAL
	/// Whether the shield is extended and protecting the user..
	var/extended = FALSE

/obj/item/shield/riot/tele/Initialize()
	. = ..()
	AddComponent(/datum/component/transforming, \
		force_on = 8, \
		throwforce_on = 5, \
		throw_speed_on = 2, \
		hitsound_on = hitsound, \
		w_class_on = WEIGHT_CLASS_NORMAL, \
		attack_verb_continuous_on = list("smacks", "strikes", "cracks", "beats"), \
		attack_verb_simple_on = list("smack", "strike", "crack", "beat"))
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/shield/riot/tele/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(extended)
		return ..()
	return FALSE

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Allows it to be placed on back slot when active.
 */
/obj/item/shield/riot/tele/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	extended = active
	slot_flags = active ? ITEM_SLOT_BACK : null
	playsound(user ? user : src, 'sound/weapons/batonextend.ogg', 50, TRUE)
	balloon_alert(user, "[active ? "extended" : "collapsed"] [src]")
	return COMPONENT_NO_DEFAULT_MESSAGE
