/datum/job/mime
	title = "Mime"
	ru_title = "Мим"
	department_head = list("Head of Personnel")
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "главе персонала"
	selection_color = "#bbe291"

	outfit = /datum/outfit/job/mime

	paycheck = PAYCHECK_MINIMAL
	paycheck_department = ACCOUNT_SRV

	display_order = JOB_DISPLAY_ORDER_MIME

	mail_goodies = list(
		/obj/item/food/baguette = 15,
		/obj/item/food/cheesewheel = 10,
		/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing = 10,
		/obj/item/book/mimery = 1,
	)

	rpg_title = "Шут"

/datum/job/mime/after_spawn(mob/living/carbon/human/H, mob/M)
	. = ..()
	H.apply_pref_name("mime", M.client)

/datum/outfit/job/mime
	name = "Mime"
	jobtype = /datum/job/mime

	belt = /obj/item/pda/mime
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/mime
	mask = /obj/item/clothing/mask/gas/mime
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/white
	head = /obj/item/clothing/head/frenchberet
	suit = /obj/item/clothing/suit/toggle/suspenders
	backpack_contents = list(
		/obj/item/modular_computer/tablet/preset/cheap=1,
		/obj/item/stamp/mime = 1,
		/obj/item/book/mimery = 1,
		/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing = 1
		)

	backpack = /obj/item/storage/backpack/mime
	satchel = /obj/item/storage/backpack/mime

	chameleon_extras = /obj/item/stamp/mime

	id_trim = /datum/id_trim/job/mime

/datum/outfit/job/mime/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()

	if(visualsOnly)
		return

	if(H.mind)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/mime/speak(null))
		H.mind.miming = TRUE

	var/datum/atom_hud/fan = GLOB.huds[DATA_HUD_FAN]
	fan.add_hud_to(H)

/obj/item/book/mimery
	name = "Guide to Dank Mimery"
	desc = "Teaches one of three classic pantomime routines, allowing a practiced mime to conjure invisible objects into corporeal existence. One use only."
	icon_state = "bookmime"

/obj/item/book/mimery/attack_self(mob/user)
	var/list/spell_icons = list(
		"Invisible Wall" = image(icon = 'icons/mob/actions/actions_mime.dmi', icon_state = "invisible_wall"),
		"Invisible Chair" = image(icon = 'icons/mob/actions/actions_mime.dmi', icon_state = "invisible_chair"),
		"Invisible Box" = image(icon = 'icons/mob/actions/actions_mime.dmi', icon_state = "invisible_box")
		)
	var/picked_spell = show_radial_menu(user, src, spell_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE)
	switch(picked_spell)
		if("Invisible Wall")
			user.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/conjure/mime_wall(null))
		if("Invisible Chair")
			user.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/conjure/mime_chair(null))
		if("Invisible Box")
			user.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/conjure/mime_box(null))
		else
			return
	to_chat(user, span_warning("The book disappears into thin air."))
	qdel(src)

/**
 * Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The human mob interacting with the menu
 */
/obj/item/book/mimery/proc/check_menu(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	if(!user.is_holding(src))
		return FALSE
	if(user.incapacitated())
		return FALSE
	if(!user.mind)
		return FALSE
	return TRUE
