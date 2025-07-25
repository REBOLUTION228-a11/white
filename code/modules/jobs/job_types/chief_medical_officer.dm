/datum/job/chief_medical_officer
	title = "Chief Medical Officer"
	ru_title = "Главный Врач"
	department_head = list("Captain")
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD
	head_announce = list(RADIO_CHANNEL_MEDICAL)
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "капитану"
	selection_color = "#ffddf0"
	req_admin_notify = 1
	minimal_player_age = 30
	exp_requirements = 7400
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_MEDICAL

	outfit = /datum/outfit/job/cmo

	skills = list(/datum/skill/surgery = SKILL_EXP_JOURNEYMAN)
	minimal_skills = list(/datum/skill/surgery = SKILL_EXP_JOURNEYMAN)

	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_MED

	liver_traits = list(TRAIT_MEDICAL_METABOLISM, TRAIT_ROYAL_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_CHIEF_MEDICAL_OFFICER
	bounty_types = CIV_JOB_MED

	mail_goodies = list(
		/obj/effect/spawner/lootdrop/organ_spawner = 10,
		/obj/effect/spawner/lootdrop/memeorgans = 8,
		/obj/effect/spawner/lootdrop/space/fancytool/advmedicalonly = 4,
		/obj/effect/spawner/lootdrop/space/fancytool/raremedicalonly = 1
	)

	rpg_title = "Высший Клерик"

/datum/job/chief_medical_officer/announce(mob/living/carbon/human/H, announce_captaincy = FALSE)
	..()
	if(announce_captaincy)
		SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(minor_announce), "Учитывая нехватку экипажа, текущим капитаном станции теперь является [H.real_name]!"))

/datum/outfit/job/cmo
	name = "Chief Medical Officer"
	jobtype = /datum/job/chief_medical_officer

	id = /obj/item/card/id/advanced/silver
	belt = /obj/item/storage/belt/medical/ems/cmo
	r_pocket = /obj/item/pda/heads/cmo
	l_pocket = /obj/item/pinpointer/crew
	ears = /obj/item/radio/headset/heads/cmo
	uniform = /obj/item/clothing/under/rank/medical/chief_medical_officer
	shoes = /obj/item/clothing/shoes/sneakers/brown
	suit = /obj/item/clothing/suit/toggle/labcoat/cmo
	l_hand = /obj/item/storage/firstaid/medical
	suit_store = /obj/item/flashlight/pen/paramedic
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/modular_computer/tablet/preset/advanced/command=1, /obj/item/card/id/departmental_budget/med=1)

	skillchips = list(/obj/item/skillchip/entrails_reader)

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	box = /obj/item/storage/box/survival/medical

	chameleon_extras = list(/obj/item/gun/syringe, /obj/item/stamp/cmo)

	id_trim = /datum/id_trim/job/chief_medical_officer

/datum/outfit/job/cmo/hardsuit
	name = "Chief Medical Officer (Hardsuit)"

	mask = /obj/item/clothing/mask/breath/medical
	suit = /obj/item/clothing/suit/space/hardsuit/medical
	suit_store = /obj/item/tank/internals/oxygen
	r_pocket = /obj/item/flashlight/pen/paramedic

