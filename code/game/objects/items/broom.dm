/// Max number of atoms a broom can sweep at once
#define BROOM_PUSH_LIMIT 20

/obj/item/pushbroom
	name = "метла"
	desc = "This is my BROOMSTICK! Её можно использовать вручную или взяться за неё двумя руками, чтобы подметать предметы на ходу. Имеет телескопическую ручку для компактного хранения."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "broom0"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 8
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("сметает", "выметает", "долбит", "шлёпает")
	attack_verb_simple = list("сметает", "выметает", "долбит", "шлёпает")
	resistance_flags = FLAMMABLE

/obj/item/pushbroom/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/pushbroom/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=8, force_wielded=12, icon_wielded="broom1")

/obj/item/pushbroom/update_icon_state()
	icon_state = "broom0"

/**
 * Handles registering the sweep proc when the broom is wielded
 *
 * Arguments:
 * * source - The source of the on_wield proc call
 * * user - The user which is wielding the broom
 */
/obj/item/pushbroom/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	to_chat(user, span_notice("Хватаю [src.name] обеими руками и готовлюсь толкать МУСОР."))
	RegisterSignal(user, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(sweep))

/**
 * Handles unregistering the sweep proc when the broom is unwielded
 *
 * Arguments:
 * * source - The source of the on_unwield proc call
 * * user - The user which is unwielding the broom
 */
/obj/item/pushbroom/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	UnregisterSignal(user, COMSIG_MOVABLE_PRE_MOVE)

/obj/item/pushbroom/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	sweep(user, A)

/**
 * Attempts to push up to BROOM_PUSH_LIMIT atoms from a given location the user's faced direction
 *
 * Arguments:
 * * user - The user of the pushbroom
 * * A - The atom which is located at the location to push atoms from
 */
/obj/item/pushbroom/proc/sweep(mob/user, atom/A)
	SIGNAL_HANDLER

	var/turf/current_item_loc = isturf(A) ? A : A.loc
	if (!isturf(current_item_loc))
		return
	var/turf/new_item_loc = get_step(current_item_loc, user.dir)
	var/obj/machinery/disposal/bin/target_bin = locate(/obj/machinery/disposal/bin) in new_item_loc.contents
	var/i = 1
	for (var/obj/item/garbage in current_item_loc.contents)
		if (!garbage.anchored)
			if (target_bin)
				garbage.forceMove(target_bin)
			else
				garbage.Move(new_item_loc, user.dir)
			i++
		if (i > BROOM_PUSH_LIMIT)
			break
	if (i > 1)
		if (target_bin)
			target_bin.update_icon()
			to_chat(user, span_notice("Заталкиваю весь мусор в мусорку."))
		playsound(loc, 'sound/weapons/thudswoosh.ogg', 30, TRUE, -1)

/**
 * Attempts to insert the push broom into a janicart
 *
 * Arguments:
 * * user - The user of the push broom
 * * J - The janicart to insert into
 */
/obj/item/pushbroom/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J) //bless you whoever fixes this copypasta
	J.put_in_cart(src, user)
	J.mybroom=src
	J.update_icon()

/obj/item/pushbroom/cyborg
	name = "метла робота"

/obj/item/pushbroom/cyborg/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	to_chat(user, span_notice("Не получается положить [src.name] в [J.name]"))
	return FALSE
