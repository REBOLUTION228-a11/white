/mob/living/carbon/human/Initialize()
	add_verb(src, /mob/living/proc/mob_sleep)
	add_verb(src, /mob/living/proc/toggle_resting)

	icon_state = ""		//Remove the inherent human icon that is visible on the map editor. We're rendering ourselves limb by limb, having it still be there results in a bug where the basic human icon appears below as south in all directions and generally looks nasty.

	//initialize limbs first
	create_bodyparts()

	setup_human_dna()

	if(dna.species)
		INVOKE_ASYNC(src, PROC_REF(set_species), dna.species.type)


	//initialise organs
	create_internal_organs() //most of it is done in set_species now, this is only for parent call
	physiology = new()

	. = ..()

	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_FACE_ACT, PROC_REF(clean_face))
	AddComponent(/datum/component/personal_crafting)
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_HUMAN, 1, -6)
	AddComponent(/datum/component/bloodysoles/feet)
	AddElement(/datum/element/ridable, /datum/component/riding/creature/human)
	AddElement(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human, should_strip))
	GLOB.human_list += src
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/carbon/human/proc/setup_human_dna()
	//initialize dna. for spawned humans; overwritten by other code
	create_dna(src)
	randomize_human(src)
	dna.initialize_dna()

/mob/living/carbon/human/ComponentInitialize()
	. = ..()
	if(!CONFIG_GET(flag/disable_human_mood))
		AddComponent(/datum/component/mood)

/mob/living/carbon/human/Destroy()
	QDEL_NULL(physiology)
	QDEL_LIST(bioware)
	GLOB.human_list -= src
	return ..()

/mob/living/carbon/human/ZImpactDamage(turf/T, levels)
	if(!HAS_TRAIT(src, TRAIT_FREERUNNING) || levels > 1) // falling off one level
		return ..()
	if(isfelinid(src))
		var/obj/item/bodypart/left_leg = get_bodypart(BODY_ZONE_L_LEG)
		var/obj/item/bodypart/right_leg = get_bodypart(BODY_ZONE_R_LEG)
		if(!left_leg || !right_leg || left_leg.bodypart_disabled || right_leg.bodypart_disabled)
			return ..()
		visible_message(span_notice("[capitalize(src.name)] ловко приземляется на [T]!") , \
			span_warning("Лечу вниз на [levels] уров[levels > 1 ? "ней" : "ень"] прямо в [T] мягко приземляясь при этом!"))
	else
		visible_message(span_danger("[capitalize(src.name)] влетает в [T], но остаётся в целости.") , \
						span_userdanger("Падаю... и влетаю в [T], но остаюсь в целости."))
		Knockdown(levels * 50)

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...sec hud images...
	sec_hud_set_ID()
	sec_hud_set_implants()
	sec_hud_set_security_status()
	//...fan gear
	fan_hud_set_fandom()
	//...and display them.
	add_to_all_human_data_huds()

/mob/living/carbon/human/get_status_tab_items()
	. = ..()
	. += "Взаимодействие: [a_intent]"
	. += "Режим перемещения: [m_intent]"
	if (internal)
		if (!internal.air_contents)
			qdel(internal)
		else
			. += ""
			. += "Источник: [internal.name]"
			. += "Давление: [internal.air_contents.return_pressure()]"
			. += "Подача: [internal.distribute_pressure]"
	if(istype(wear_suit, /obj/item/clothing/suit/space))
		var/obj/item/clothing/suit/space/S = wear_suit
		. += "Терморегулятор: [S.thermal_on ? "ВКЛ" : "ВЫКЛ"]"
		. += "Заряд батареи: [S.cell ? "[round(S.cell.percent(), 0.1)]%" : "!ОШИБКА!"]"
	if(mind)
		var/datum/antagonist/changeling/changeling = mind.has_antag_datum(/datum/antagonist/changeling)
		if(changeling)
			. += ""
			. += "Химикаты: [changeling.chem_charges]/[changeling.chem_storage]"
			. += "Поглощено ДНК: [changeling.absorbedcount]"

// called when something steps onto a human
/mob/living/carbon/human/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	spreadFire(AM)

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["item"]) //canUseTopic check for this is handled by mob/Topic()
		var/slot = text2num(href_list["item"])
		if(check_obscured_slots(TRUE) & slot)
			to_chat(usr, span_warning("Не могу достать! Что-то мешает доступу к этому."))
			return

///////HUDs///////
	if(href_list["hud"])
		if(!ishuman(usr))
			return
		var/mob/living/carbon/human/H = usr
		var/perpname = get_face_name(get_id_name(""))
		if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD) && !HAS_TRAIT(H, TRAIT_MEDICAL_HUD))
			return
		var/datum/data/record/R = find_record("name", perpname, GLOB.data_core.general)
		if(href_list["photo_front"] || href_list["photo_side"])
			if(!R)
				return
			if(!H.canUseHUD())
				return
			if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD) && !HAS_TRAIT(H, TRAIT_MEDICAL_HUD))
				return
			var/obj/item/photo/P = null
			if(href_list["photo_front"])
				P = R.fields["photo_front"]
			else if(href_list["photo_side"])
				P = R.fields["photo_side"]
			if(P)
				P.show(H)
			return

		if(href_list["hud"] == "m")
			if(!HAS_TRAIT(H, TRAIT_MEDICAL_HUD))
				return
			if(href_list["evaluation"])
				if(!getBruteLoss() && !getFireLoss() && !getOxyLoss() && getToxLoss() < 20)
					to_chat(usr, "<span class='notice'>Не обнаружено внешних травм.</span><br>")
					return
				var/span = "notice"
				var/status = ""
				if(getBruteLoss())
					to_chat(usr, "<b>Анализ физических травм:</b>")
					for(var/X in bodyparts)
						var/obj/item/bodypart/BP = X
						var/brutedamage = BP.brute_dam
						if(brutedamage > 0)
							status = "незначительные физические травмы."
							span = "notice"
						if(brutedamage > 20)
							status = "серьезные физические травмы."
							span = "danger"
						if(brutedamage > 40)
							status = "ужасные физические травмы!"
							span = "userdanger"
						if(brutedamage)
							to_chat(usr, "<span class='[span]'>[BP] имеет [status]</span>")
				if(getFireLoss())
					to_chat(usr, "<b>Анализ кожного покрова:</b>")
					for(var/X in bodyparts)
						var/obj/item/bodypart/BP = X
						var/burndamage = BP.burn_dam
						if(burndamage > 0)
							status = "признаки незначительных ожогов."
							span = "notice"
						if(burndamage > 20)
							status = "серьезные ожоги."
							span = "danger"
						if(burndamage > 40)
							status = "сильные ожоги!"
							span = "userdanger"
						if(burndamage)
							to_chat(usr, "<span class='[span]'>[BP] имеет [status]</span>")
				if(getOxyLoss())
					to_chat(usr, span_danger("Пациент имеет признаки удушья, может потребоваться экстренное лечение!"))
				if(getToxLoss() > 20)
					to_chat(usr, span_danger("Собранные данные не соответствуют анализу, возможная причина: отравление."))
			if(!H.wear_id) //You require access from here on out.
				to_chat(H, span_warning("ERROR: Нет доступа"))
				return
			var/list/access = H.wear_id.GetAccess()
			if(!(ACCESS_MEDICAL in access))
				to_chat(H, span_warning("ERROR: Нет доступа"))
				return
			if(href_list["p_stat"])
				var/health_status = input(usr, "Укажите новый физический статус для этого человека.", "Medical HUD", R.fields["p_stat"]) in list("Active", "Physically Unfit", "*Unconscious*", "*Deceased*", "Cancel")
				if(!R)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_MEDICAL_HUD))
					return
				if(health_status && health_status != "Cancel")
					R.fields["p_stat"] = health_status
				return
			if(href_list["m_stat"])
				var/health_status = input(usr, "Укажите новый психический статус для этого человека.", "Medical HUD", R.fields["m_stat"]) in list("Stable", "*Watch*", "*Unstable*", "*Insane*", "Cancel")
				if(!R)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_MEDICAL_HUD))
					return
				if(health_status && health_status != "Cancel")
					R.fields["m_stat"] = health_status
				return
			if(href_list["quirk"])
				var/quirkstring = get_quirk_string(TRUE, CAT_QUIRK_ALL)
				if(quirkstring)
					to_chat(usr, "<span class='notice ml-1'>Detected physiological traits:\n</span><span class='notice ml-2'>[quirkstring]</span>")
				else
					to_chat(usr, "<span class='notice ml-1'>No physiological traits found.</span>")
			return //Medical HUD ends here.

		if(href_list["hud"] == "s")
			if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
				return
			if(usr.stat || usr == src) //|| !usr.canmove || usr.restrained()) Fluff: Sechuds have eye-tracking technology and sets 'arrest' to people that the wearer looks and blinks at.
				return													  //Non-fluff: This allows sec to set people to arrest as they get disarmed or beaten
			// Checks the user has security clearence before allowing them to change arrest status via hud, comment out to enable all access
			var/allowed_access = null
			var/obj/item/clothing/glasses/hud/security/G = H.glasses
			if(istype(G) && (G.obj_flags & EMAGGED))
				allowed_access = "@%&ERROR_%$*"
			else //Implant and standard glasses check access
				if(H.wear_id)
					var/list/access = H.wear_id.GetAccess()
					if(ACCESS_SECURITY in access)
						allowed_access = H.get_authentification_name()

			if(!allowed_access)
				to_chat(H, span_warning("ERROR: Нет доступа."))
				return

			if(!perpname)
				to_chat(H, span_warning("ERROR: Не могу идентифицировать цель."))
				return
			R = find_record("name", perpname, GLOB.data_core.security)
			if(!R)
				to_chat(usr, span_warning("ERROR: Невозможно найти запись ядра данных для цели."))
				return
			if(href_list["status"])
				var/setcriminal = input(usr, "Укажите новый преступный статус для этого человека.", "Security HUD", R.fields["criminal"]) in list("None", "*Arrest*", "Incarcerated", "Paroled", "Discharged", "Отмена")
				if(setcriminal != "Отмена")
					if(!R)
						return
					if(!H.canUseHUD())
						return
					if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
						return
					investigate_log("[key_name(src)] has been set from [R.fields["criminal"]] to [setcriminal] by [key_name(usr)].", INVESTIGATE_RECORDS)
					R.fields["criminal"] = setcriminal
					sec_hud_set_security_status()
				return

			if(href_list["view"])
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				to_chat(usr, "<b>Имя:</b> [R.fields["name"]]	<b>Статус:</b> [R.fields["criminal"]]")
				for(var/datum/data/crime/c in R.fields["crim"])
					to_chat(usr, "<b>Преступление:</b> [c.crimeName]")
					if (c.crimeDetails)
						to_chat(usr, "<b>Детали:</b> [c.crimeDetails]")
					else
						to_chat(usr, "<b>Детали:</b> <A href='?src=[REF(src)];hud=s;add_details=1;cdataid=[c.dataId]'>\[Добавить]</A>")
					to_chat(usr, "Добавлено [c.author] в [c.time]")
					to_chat(usr, "----------")
				to_chat(usr, "<b>Заметки:</b> [R.fields["notes"]]")
				return

			if(href_list["add_citation"])
				var/maxFine = CONFIG_GET(number/maxfine)
				var/t1 = stripped_input("Please input citation crime:", "Security HUD", "", null)
				var/fine = FLOOR(input("Please input citation fine, up to [maxFine]:", "Security HUD", 50) as num|null, 1)
				if(!R || !t1 || !fine || !allowed_access)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				if(fine < 0)
					to_chat(usr, span_warning("You're pretty sure that's not how money works."))
					return
				fine = min(fine, maxFine)

				var/crime = GLOB.data_core.createCrimeEntry(t1, "", allowed_access, station_time_timestamp(), fine)
				for (var/obj/item/pda/P in GLOB.PDAs)
					if(P.owner == R.fields["name"])
						var/message = "You have been fined [fine] credits for '[t1]'. Fines may be paid at security."
						var/datum/signal/subspace/messaging/pda/signal = new(src, list(
							"name" = "Security Citation",
							"job" = "Citation Server",
							"message" = message,
							"targets" = list("[P.owner] ([P.ownjob])"),
							"automated" = 1
						))
						signal.send_to_receivers()
						usr.log_message("(PDA: Citation Server) sent \"[message]\" to [signal.format_target()]", LOG_PDA)
				GLOB.data_core.addCitation(R.fields["id"], crime)
				investigate_log("New Citation: <strong>[t1]</strong> Fine: [fine] | Added to [R.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
				return

			if(href_list["add_crime"])
				var/t1 = stripped_input("Введите название преступления:", "Security HUD", "", null)
				if(!R || !t1 || !allowed_access)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				var/crime = GLOB.data_core.createCrimeEntry(t1, null, allowed_access, station_time_timestamp())
				GLOB.data_core.addCrime(R.fields["id"], crime)
				investigate_log("New Crime: <strong>[t1]</strong> | Added to [R.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
				to_chat(usr, span_notice("Успешно добавили преступление."))
				return

			if(href_list["add_details"])
				var/t1 = stripped_input(usr, "Пожалуйста, введите основные детали преступлений:", "Secure. records", "", null)
				if(!R || !t1 || !allowed_access)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				if(href_list["cdataid"])
					GLOB.data_core.addCrimeDetails(R.fields["id"], href_list["cdataid"], t1)
					investigate_log("New Crime details: [t1] | Added to [R.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
					to_chat(usr, span_notice("Успешно добавлены детали."))
				return

			if(href_list["view_comment"])
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				to_chat(usr, "<b>Комментарии/Логи:</b>")
				var/counter = 1
				while(R.fields[text("com_[]", counter)])
					to_chat(usr, R.fields[text("com_[]", counter)])
					to_chat(usr, "----------")
					counter++
				return

			if(href_list["add_comment"])
				var/t1 = stripped_multiline_input("Добавить комментарий:", "Secure. records", null, null)
				if (!R || !t1 || !allowed_access)
					return
				if(!H.canUseHUD())
					return
				if(!HAS_TRAIT(H, TRAIT_SECURITY_HUD))
					return
				var/counter = 1
				while(R.fields[text("com_[]", counter)])
					counter++
				R.fields[text("com_[]", counter)] = text("Сделано [] в [] [], []<BR>[]", allowed_access, station_time_timestamp(), time2text(world.realtime, "MMM DD"), GLOB.year_integer+540, t1)
				to_chat(usr, span_notice("Успешно добавили комментарий."))
				return

	..() //end of this massive fucking chain. TODO: make the hud chain not spooky. - Yeah, great job doing that.


/mob/living/carbon/human/proc/canUseHUD()
	return (mobility_flags & MOBILITY_USE)

/mob/living/carbon/human/can_inject(mob/user, target_zone, injection_flags)
	. = TRUE // Default to returning true.
	if(user && !target_zone)
		target_zone = user.zone_selected
	// we may choose to ignore species trait pierce immunity in case we still want to check skellies for thick clothing without insta failing them (wounds)
	if(injection_flags & INJECT_CHECK_IGNORE_SPECIES)
		if(HAS_TRAIT_NOT_FROM(src, TRAIT_PIERCEIMMUNE, SPECIES_TRAIT))
			. = FALSE
	else if(HAS_TRAIT(src, TRAIT_PIERCEIMMUNE))
		. = FALSE
	var/obj/item/bodypart/the_part = get_bodypart(target_zone) || get_bodypart(BODY_ZONE_CHEST)
	// Loop through the clothing covering this bodypart and see if there's any thiccmaterials
	if(!(injection_flags & INJECT_CHECK_PENETRATE_THICK))
		for(var/obj/item/clothing/iter_clothing in clothingonpart(the_part))
			if(iter_clothing.clothing_flags & THICKMATERIAL)
				. = FALSE
				break

/mob/living/carbon/human/try_inject(mob/user, target_zone, injection_flags)
	. = ..()
	if(!. && (injection_flags & INJECT_TRY_SHOW_ERROR_MESSAGE) && user)
		var/obj/item/bodypart/the_part = get_bodypart(target_zone) || get_bodypart(BODY_ZONE_CHEST)

		to_chat(user, span_alert("Нет открытой плоти или тонкого материала на [ru_gde_zone(the_part.name)]."))

/mob/living/carbon/human/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null)
	if(judgement_criteria & JUDGE_EMAGGED)
		return 10 //Everyone is a criminal!

	var/threatcount = 0

	//Lasertag bullshit
	if(lasercolor)
		if(lasercolor == "b")//Lasertag turrets target the opposing team, how great is that? -Sieve
			if(istype(wear_suit, /obj/item/clothing/suit/redtag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/redtag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/redtag))
				threatcount += 2

		if(lasercolor == "r")
			if(istype(wear_suit, /obj/item/clothing/suit/bluetag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/bluetag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/bluetag))
				threatcount += 2

		return threatcount

	//Check for ID
	var/obj/item/card/id/idcard = get_idcard(FALSE)
	if( (judgement_criteria & JUDGE_IDCHECK) && !idcard && name=="Неизвестный")
		threatcount += 4

	//Check for weapons
	if( (judgement_criteria & JUDGE_WEAPONCHECK) && weaponcheck)
		if(!idcard || !(ACCESS_WEAPONS in idcard.access))
			for(var/obj/item/I in held_items) //if they're holding a gun
				if(weaponcheck.Invoke(I))
					threatcount += 4
			if(weaponcheck.Invoke(belt) || weaponcheck.Invoke(back)) //if a weapon is present in the belt or back slot
				threatcount += 2 //not enough to trigger look_for_perp() on it's own unless they also have criminal status.

	//Check for arrest warrant
	if(judgement_criteria & JUDGE_RECORDCHECK)
		var/perpname = get_face_name(get_id_name())
		var/datum/data/record/R = find_record("name", perpname, GLOB.data_core.security)
		if(R?.fields["criminal"])
			switch(R.fields["criminal"])
				if("*Arrest*")
					threatcount += 5
				if("Incarcerated")
					threatcount += 2
				if("Paroled")
					threatcount += 2

	//Check for dresscode violations
	if(istype(head, /obj/item/clothing/head/wizard) || istype(head, /obj/item/clothing/head/helmet/space/hardsuit/wizard))
		threatcount += 2

	//mindshield implants imply trustworthyness
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		threatcount -= 1

	return threatcount


//Used for new human mobs created by cloning/goleming/podding
/mob/living/carbon/human/proc/set_cloned_appearance()
	if(gender == MALE)
		facial_hairstyle = "Full Beard"
	else
		facial_hairstyle = "Shaved"
	hairstyle = pick("Bedhead", "Bedhead 2", "Bedhead 3")
	underwear = "Nude"
	update_body()
	update_hair()

/mob/living/carbon/human/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_THREE)
		for(var/obj/item/hand in held_items)
			if(prob(current_size * 5) && hand.w_class >= ((11-current_size)/2)  && dropItemToGround(hand))
				step_towards(hand, src)
				to_chat(src, span_warning("Невероятно, но [S] вытягивает [hand] из моей руки!"))
	rad_act(current_size * 3)

#define CPR_PANIC_SPEED (0.8 SECONDS)

/// Performs CPR on the target after a delay.
/mob/living/carbon/human/proc/do_cpr(mob/living/carbon/target)
	if(target == src)
		return

	var/panicking = FALSE

	do
		CHECK_DNA_AND_SPECIES(target)

		if (DOING_INTERACTION_WITH_TARGET(src,target))
			return FALSE

		if (target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH))
			to_chat(src, span_warning("[target.name] мертво!"))
			return FALSE

		if (is_mouth_covered())
			to_chat(src, span_warning("Надо бы маску снять!"))
			return FALSE

		if (target.is_mouth_covered())
			to_chat(src, span_warning("Снять бы с н[ru_ego()] маску сначала!"))
			return FALSE

		if (!getorganslot(ORGAN_SLOT_LUNGS))
			to_chat(src, span_warning("У меня нет лёгких для проведения данной процедуры!"))
			return FALSE

		if (HAS_TRAIT(src, TRAIT_NOBREATH))
			to_chat(src, span_warning("А я дышать то не умею. Как?"))
			return FALSE

		visible_message(span_notice("[capitalize(src.name)] делает сердечно-легочную реанимацию [target.name]!") , \
						span_notice("Делаю сердечно-легочную реанимацию [target.name]... Надо потерпеть!"))

		if (!do_mob(src, target, time = panicking ? CPR_PANIC_SPEED : (3 SECONDS)))
			to_chat(src, span_warning("У меня не вышло сделать сердечно-легочную реанимацию [target]!"))
			return FALSE

		if (target.health > target.crit_threshold)
			return FALSE

		visible_message(span_notice("[capitalize(src.name)] производит сердечно-легочную реанимацию [target.name]!") , span_notice("Произвожу сердечно-легочную реанимацию [target.name]."))
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "saved_life", /datum/mood_event/saved_life)
		log_combat(src, target, "CPRed")

		if (HAS_TRAIT(target, TRAIT_NOBREATH))
			to_chat(target, span_unconscious("Чувствую, как глоток свежего воздуха входит в мои легкие..."))
		else if (!target.getorganslot(ORGAN_SLOT_LUNGS))
			to_chat(target, span_unconscious("Чувствую глоток свежего воздуха... но мне не лучше..."))
		else
			target.adjustOxyLoss(-min(target.getOxyLoss(), 7))
			to_chat(target, span_unconscious("Чувствую глоток свежего воздуха... мне лучше..."))

		if (target.health <= target.crit_threshold)
			if (!panicking)
				to_chat(src, span_warning("[target] всё ещё лежит! Нужно попробовать ещё!"))
			panicking = TRUE
		else
			panicking = FALSE
	while (panicking)

#undef CPR_PANIC_SPEED

/mob/living/carbon/human/cuff_resist(obj/item/I)
	if(dna?.check_mutation(HULK) || istype(mind.martial_art, /datum/martial_art/nanosuit))
		say(pick(";РАААААААААРГ!", ";ХНННННННГГГГГГГ!", ";ГВААААРРХХ!", "ННННННГГГГГГХ!", ";ААААААРРГГ!" ), forced = "hulk")
		if(..(I, cuff_break = FAST_CUFFBREAK))
			dropItemToGround(I)
	else
		if(..())
			dropItemToGround(I)

/**
 * Wash the hands, cleaning either the gloves if equipped and not obscured, otherwise the hands themselves if they're not obscured.
 *
 * Returns false if we couldn't wash our hands due to them being obscured, otherwise true
 */
/mob/living/carbon/human/proc/wash_hands(clean_types)
	var/obscured = check_obscured_slots()
	if(obscured & ITEM_SLOT_GLOVES)
		return FALSE

	if(gloves)
		if(gloves.wash(clean_types))
			update_inv_gloves()
	else if((clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0)
		blood_in_hands = 0
		update_inv_gloves()

	return TRUE

/**
 * Cleans the lips of any lipstick. Returns TRUE if the lips had any lipstick and was thus cleaned
 */
/mob/living/carbon/human/proc/clean_lips()
	if(isnull(lip_style) && lip_color == initial(lip_color))
		return FALSE
	lip_style = null
	lip_color = initial(lip_color)
	update_body()
	return TRUE

/**
 * Called on the COMSIG_COMPONENT_CLEAN_FACE_ACT signal
 */
/mob/living/carbon/human/proc/clean_face(datum/source, clean_types)
	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	if(glasses && is_eyes_covered(FALSE, TRUE, TRUE) && glasses.wash(clean_types))
		update_inv_glasses()
		. = TRUE

	var/obscured = check_obscured_slots()
	if(wear_mask && !(obscured & ITEM_SLOT_MASK) && wear_mask.wash(clean_types))
		update_inv_wear_mask()
		. = TRUE

/**
 * Called when this human should be washed
 */
/mob/living/carbon/human/wash(clean_types)
	. = ..()

	// Wash equipped stuff that cannot be covered
	if(wear_suit?.wash(clean_types))
		update_inv_wear_suit()
		. = TRUE

	if(belt?.wash(clean_types))
		update_inv_belt()
		. = TRUE

	// Check and wash stuff that can be covered
	var/obscured = check_obscured_slots()

	if(w_uniform && !(obscured & ITEM_SLOT_ICLOTHING) && w_uniform.wash(clean_types))
		update_inv_w_uniform()
		. = TRUE

	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	// Wash hands if exposed
	if(!gloves && (clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0 && !(obscured & ITEM_SLOT_GLOVES))
		blood_in_hands = 0
		update_inv_gloves()
		. = TRUE

//Turns a mob black, flashes a skeleton overlay
//Just like a cartoon!
/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	//Handle mutant parts if possible
	if(dna?.species)
		add_atom_colour("#000000", TEMPORARY_COLOUR_PRIORITY)
		var/static/mutable_appearance/electrocution_skeleton_anim
		if(!electrocution_skeleton_anim)
			electrocution_skeleton_anim = mutable_appearance(icon, "electrocuted_base")
			electrocution_skeleton_anim.appearance_flags |= RESET_COLOR|KEEP_APART
		add_overlay(electrocution_skeleton_anim)
		addtimer(CALLBACK(src, PROC_REF(end_electrocution_animation), electrocution_skeleton_anim), anim_duration)

	else //or just do a generic animation
		flick_overlay_view(image(icon,src,"electrocuted_generic",ABOVE_MOB_LAYER), src, anim_duration)

/mob/living/carbon/human/proc/end_electrocution_animation(mutable_appearance/MA)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#000000")
	cut_overlay(MA)

/mob/living/carbon/human/resist_restraints()
	if(wear_suit?.breakoutchance)
		changeNext_move(CLICK_CD_BREAKOUT)
		last_special = world.time + CLICK_CD_BREAKOUT
		cuff_resist(wear_suit)
	else
		..()

/mob/living/carbon/human/clear_cuffs(obj/item/I, cuff_break)
	. = ..()
	if(.)
		return
	if(!I.loc || buckled)
		return FALSE
	if(I == wear_suit)
		visible_message(span_danger("[capitalize(src.name)] manages to [cuff_break ? "break" : "remove"] [I]!"))
		to_chat(src, span_notice("You successfully [cuff_break ? "break" : "remove"] [I]."))
		return TRUE

/mob/living/carbon/human/replace_records_name(oldname,newname) // Only humans have records right now, move this up if changed.
	for(var/list/L in list(GLOB.data_core.general,GLOB.data_core.medical,GLOB.data_core.security,GLOB.data_core.locked))
		var/datum/data/record/R = find_record("name", oldname, L)
		if(R)
			R.fields["name"] = newname

/mob/living/carbon/human/get_total_tint()
	. = ..()
	if(glasses)
		. += glasses.tint

/mob/living/carbon/human/update_health_hud()
	if(!client || !hud_used)
		return
	if(dna.species.update_health_hud())
		return
	else
		if(hud_used.healths)
			if(..()) //not dead
				switch(hal_screwyhud)
					if(SCREWYHUD_CRIT)
						hud_used.healths.icon_state = "health6"
					if(SCREWYHUD_DEAD)
						hud_used.healths.icon_state = "health7"
					if(SCREWYHUD_HEALTHY)
						hud_used.healths.icon_state = "health0"
		if(hud_used.healthdoll)
			hud_used.healthdoll.cut_overlays()
			if(stat != DEAD)
				hud_used.healthdoll.icon_state = "healthdoll_OVERLAY"
				for(var/obj/item/bodypart/body_part as anything in bodyparts)
					var/icon_num = 0
					//Hallucinations
					if(body_part.type in hal_screwydoll)
						icon_num = hal_screwydoll[body_part.type]
						hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[body_part.body_zone][icon_num]"))
						continue
					//Not hallucinating
					var/damage = body_part.burn_dam + body_part.brute_dam
					var/comparison = (body_part.max_damage/5)
					if(damage)
						icon_num = 1
					if(damage > (comparison))
						icon_num = 2
					if(damage > (comparison*2))
						icon_num = 3
					if(damage > (comparison*3))
						icon_num = 4
					if(damage > (comparison*4))
						icon_num = 5
					if(hal_screwyhud == SCREWYHUD_HEALTHY)
						icon_num = 0
					if(icon_num)
						hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[body_part.body_zone][icon_num]"))
				for(var/t in get_missing_limbs()) //Missing limbs
					hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[t]6"))
				for(var/t in get_disabled_limbs()) //Disabled limbs
					hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[t]7"))
			else
				hud_used.healthdoll.icon_state = "healthdoll_DEAD"

/mob/living/carbon/human/fully_heal(admin_revive = FALSE)
	dna?.species.spec_fully_heal(src)
	if(admin_revive)
		regenerate_limbs()
		regenerate_organs()
	remove_all_embedded_objects()
	set_heartattack(FALSE)
	drunkenness = 0
	for(var/datum/mutation/human/HM in dna.mutations)
		if(HM.quality != POSITIVE)
			dna.remove_mutation(HM.name)
	coretemperature = get_body_temp_normal(apply_change=FALSE)
	heat_exposure_stacks = 0
	return ..()

/mob/living/carbon/human/check_weakness(obj/item/weapon, mob/living/attacker)
	. = ..()
	if (dna && dna.species)
		. *= dna.species.check_species_weakness(weapon, attacker)

/mob/living/carbon/human/is_literate()
	return TRUE

/mob/living/carbon/human/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if(blood && (NOBLOOD in dna.species.species_traits) && !HAS_TRAIT(src, TRAIT_TOXINLOVER))
		if(message)
			visible_message(span_warning("[capitalize(src.name)] рыгает!") , \
							span_userdanger("Ты пытаешься вырвать, но в твоем желудке нет ничего!"))
		if(stun)
			Paralyze(200)
		return 1
	..()

/mob/living/carbon/human/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_COPY_OUTFIT, "Copy Outfit")
	VV_DROPDOWN_OPTION(VV_HK_MOD_MUTATIONS, "Add/Remove Mutation")
	VV_DROPDOWN_OPTION(VV_HK_MOD_QUIRKS, "Add/Remove Quirks")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_MONKEY, "Make Monkey")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_CYBORG, "Make Cyborg")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_SLIME, "Make Slime")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_ALIEN, "Make Alien")
	VV_DROPDOWN_OPTION(VV_HK_SET_SPECIES, "Set Species")
	VV_DROPDOWN_OPTION(VV_HK_PURRBATION, "Toggle Purrbation")

/mob/living/carbon/human/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_COPY_OUTFIT])
		if(!check_rights(R_SPAWN))
			return
		copy_outfit()
	if(href_list[VV_HK_MOD_MUTATIONS])
		if(!check_rights(R_SPAWN))
			return

		var/list/options = list("Clear"="Clear")
		for(var/x in subtypesof(/datum/mutation/human))
			var/datum/mutation/human/mut = x
			var/name = initial(mut.name)
			options[dna.check_mutation(mut) ? "[name] (Remove)" : "[name] (Add)"] = mut

		var/result = input(usr, "Choose mutation to add/remove","Mutation Mod") as null|anything in sort_list(options)
		if(result)
			if(result == "Clear")
				dna.remove_all_mutations()
			else
				var/mut = options[result]
				if(dna.check_mutation(mut))
					dna.remove_mutation(mut)
				else
					dna.add_mutation(mut)
	if(href_list[VV_HK_MOD_QUIRKS])
		if(!check_rights(R_SPAWN))
			return

		var/list/options = list("Clear"="Clear")
		for(var/x in subtypesof(/datum/quirk))
			var/datum/quirk/T = x
			var/qname = initial(T.name)
			options[has_quirk(T) ? "[qname] (Remove)" : "[qname] (Add)"] = T

		var/result = input(usr, "Choose quirk to add/remove","Quirk Mod") as null|anything in sort_list(options)
		if(result)
			if(result == "Clear")
				for(var/datum/quirk/q in roundstart_quirks)
					remove_quirk(q.type)
			else
				var/T = options[result]
				if(has_quirk(T))
					remove_quirk(T)
				else
					add_quirk(T,TRUE)
	if(href_list[VV_HK_MAKE_MONKEY])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("monkeyone"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_CYBORG])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makerobot"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_ALIEN])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makealien"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_SLIME])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makeslime"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_SET_SPECIES])
		if(!check_rights(R_SPAWN))
			return

		var/result = input(usr, "Please choose a new species","Species") as null|anything in GLOB.species_list
		if(result)
			var/newtype = GLOB.species_list[result]
			admin_ticket_log("[key_name_admin(usr)] has modified the bodyparts of [src] to [result]")
			set_species(newtype)
	if(href_list[VV_HK_PURRBATION])
		if(!check_rights(R_SPAWN))
			return

		if(!ishumanbasic(src))
			to_chat(usr, "This can only be done to the basic human species at the moment.")
			return
		var/success = purrbation_toggle(src)
		if(success)
			to_chat(usr, "Put [src] on purrbation.")
			log_admin("[key_name(usr)] has put [key_name(src)] on purrbation.")
			var/msg = span_notice("[key_name_admin(usr)] has put [key_name(src)] on purrbation.")
			message_admins(msg)
			admin_ticket_log(src, msg)

		else
			to_chat(usr, "Removed [src] from purrbation.")
			log_admin("[key_name(usr)] has removed [key_name(src)] from purrbation.")
			var/msg = span_notice("[key_name_admin(usr)] has removed [key_name(src)] from purrbation.")
			message_admins(msg)
			admin_ticket_log(src, msg)

/mob/living/carbon/human/limb_attack_self()
	var/obj/item/bodypart/arm = hand_bodyparts[active_hand_index]
	if(arm)
		arm.attack_self(src)
	return ..()

/mob/living/carbon/human/mouse_buckle_handling(mob/living/M, mob/living/user)
	if(pulling != M || grab_state != GRAB_AGGRESSIVE || stat != CONSCIOUS || a_intent != INTENT_GRAB)
		return FALSE

	//If they dragged themselves to you and you're currently aggressively grabbing them try to piggyback
	if(user == M && can_piggyback(M))
		piggyback(M)
		return TRUE

	//If you dragged them to you and you're aggressively grabbing try to fireman carry them
	if(can_be_firemanned(M))
		fireman_carry(M)
		return TRUE

//src is the user that will be carrying, target is the mob to be carried
/mob/living/carbon/human/proc/can_piggyback(mob/living/carbon/target)
	return (istype(target) && target.stat == CONSCIOUS)

/mob/living/carbon/human/proc/can_be_firemanned(mob/living/carbon/target)
	return ishuman(target) && target.body_position == LYING_DOWN

/mob/living/carbon/human/proc/fireman_carry(mob/living/carbon/target)
	if(!can_be_firemanned(target) || incapacitated(IGNORE_GRAB))
		to_chat(src, span_warning("You can't fireman carry [target] while [target.p_they()] [target.p_are()] standing!"))
		return

	var/carrydelay = 5 SECONDS //if you have latex you are faster at grabbing
	var/skills_space = "" //cobby told me to do this
	if(HAS_TRAIT(src, TRAIT_QUICKER_CARRY))
		carrydelay = 3 SECONDS
		skills_space = " экспертно"
	else if(HAS_TRAIT(src, TRAIT_QUICK_CARRY))
		carrydelay = 4 SECONDS
		skills_space = " быстро"

	visible_message(span_notice("<b>[src]</b> начинает[skills_space] поднимать <b>[target]</b> на свою спину...") ,
	//Joe Medic starts quickly/expertly lifting Grey Tider onto their back..
	span_notice("[carrydelay < 3.5 SECONDS ? "Используя наночипы в своих перчатках начинаю" : "Начинаю"][skills_space] поднимать [target] на свою спину[carrydelay == 4 SECONDS ? ", пока мне помогают наночипы в моих перчатках..." : "..."]"))
	//(Using your gloves' nanochips, you/You) ( /quickly/expertly) start to lift Grey Tider onto your back(, while assisted by the nanochips in your gloves../...)
	if(!do_after(src, carrydelay, target))
		visible_message(span_warning("<b>[src]</b> проваливает попытку поднять <b>[target]</b>!"))
		return

	//Second check to make sure they're still valid to be carried
	if(!can_be_firemanned(target) || incapacitated(IGNORE_GRAB) || target.buckled)
		visible_message(span_warning("<b>[src]</b> проваливает попытку поднять <b>[target]</b>!"))
		return

	if(target.loc != loc)
		var/old_density = density
		density = FALSE // Hacky and doesn't use set_density()
		step_towards(target, loc)
		density = old_density // Avoid changing density directly in normal circumstances, without the setter.

	if(target.loc == loc)
		return buckle_mob(target, TRUE, TRUE, CARRIER_NEEDS_ARM)

/mob/living/carbon/human/proc/piggyback(mob/living/carbon/target)
	if(!can_piggyback(target))
		to_chat(target, span_warning("Не хочу взбираться на <b>[src]</b>!"))
		return

	visible_message(span_notice("<b>[target]</b> начинает залезать на <b>[src]</b>..."))
	if(!do_after(target, 1.5 SECONDS, target = src) || !can_piggyback(target))
		visible_message(span_warning("<b>[target]</b> не может залезть на <b>[src]</b>!"))
		return

	if(target.incapacitated(IGNORE_GRAB) || incapacitated(IGNORE_GRAB))
		target.visible_message(span_warning("<b>[target]</b> не может залезть на <b>[src]</b>"))
		return

	return buckle_mob(target, TRUE, TRUE, RIDER_NEEDS_ARMS)

/mob/living/carbon/human/buckle_mob(mob/living/target, force = FALSE, check_loc = TRUE, buckle_mob_flags= NONE)
	if(!is_type_in_typecache(target, can_ride_typecache))
		target.visible_message(span_warning("<b>[target]</b> не понимает как взобраться на <b>[src]</b>..."))
		return

	if(!force)//humans are only meant to be ridden through piggybacking and special cases
		return

	return ..()

/mob/living/carbon/human/updatehealth()
	. = ..()
	dna?.species.spec_updatehealth(src)
	if(HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)
		return
	var/health_deficiency = max((maxHealth - health), staminaloss)
	if(health_deficiency >= 40)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, multiplicative_slowdown = health_deficiency / 75)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying, TRUE, multiplicative_slowdown = health_deficiency / 25)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)

/mob/living/carbon/human/adjust_nutrition(change) //Honestly FUCK the oldcoders for putting nutrition on /mob someone else can move it up because holy hell I'd have to fix SO many typechecks
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	if((NOBLOOD in dna.species.species_traits))
		nutrition = NUTRITION_LEVEL_FED
		return FALSE
	return ..()

/mob/living/carbon/human/set_nutrition(change) //Seriously fuck you oldcoders.
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return ..()

/mob/living/carbon/human/is_bleeding()
	if(NOBLOOD in dna.species.species_traits)
		return FALSE
	return ..()

/mob/living/carbon/human/get_total_bleed_rate()
	if(NOBLOOD in dna.species.species_traits)
		return FALSE
	return ..()

/mob/living/carbon/human/monkeybrain
	ai_controller = /datum/ai_controller/monkey

/mob/living/carbon/human/species
	var/race = null
	var/use_random_name = TRUE

/mob/living/carbon/human/species/Initialize()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(set_species), race)

/mob/living/carbon/human/species/set_species(datum/species/mrace, icon_update, pref_load)
	. = ..()
	if(use_random_name)
		fully_replace_character_name(real_name, dna.species.random_name())

/mob/living/carbon/human/species/abductor
	race = /datum/species/abductor

/mob/living/carbon/human/species/android
	race = /datum/species/android

/mob/living/carbon/human/species/dullahan
	race = /datum/species/dullahan

/mob/living/carbon/human/species/felinid
	race = /datum/species/human/felinid

/mob/living/carbon/human/species/fly
	race = /datum/species/fly

/mob/living/carbon/human/species/golem
	race = /datum/species/golem

/mob/living/carbon/human/species/golem/random
	race = /datum/species/golem/random

/mob/living/carbon/human/species/golem/adamantine
	race = /datum/species/golem/adamantine

/mob/living/carbon/human/species/golem/plasma
	race = /datum/species/golem/plasma

/mob/living/carbon/human/species/golem/diamond
	race = /datum/species/golem/diamond

/mob/living/carbon/human/species/golem/gold
	race = /datum/species/golem/gold

/mob/living/carbon/human/species/golem/silver
	race = /datum/species/golem/silver

/mob/living/carbon/human/species/golem/plasteel
	race = /datum/species/golem/plasteel

/mob/living/carbon/human/species/golem/titanium
	race = /datum/species/golem/titanium

/mob/living/carbon/human/species/golem/plastitanium
	race = /datum/species/golem/plastitanium

/mob/living/carbon/human/species/golem/alien_alloy
	race = /datum/species/golem/alloy

/mob/living/carbon/human/species/golem/wood
	race = /datum/species/golem/wood

/mob/living/carbon/human/species/golem/uranium
	race = /datum/species/golem/uranium

/mob/living/carbon/human/species/golem/sand
	race = /datum/species/golem/sand

/mob/living/carbon/human/species/golem/glass
	race = /datum/species/golem/glass

/mob/living/carbon/human/species/golem/bluespace
	race = /datum/species/golem/bluespace

/mob/living/carbon/human/species/golem/bananium
	race = /datum/species/golem/bananium

/mob/living/carbon/human/species/golem/blood_cult
	race = /datum/species/golem/runic

/mob/living/carbon/human/species/golem/cloth
	race = /datum/species/golem/cloth

/mob/living/carbon/human/species/golem/plastic
	race = /datum/species/golem/plastic

/mob/living/carbon/human/species/golem/bronze
	race = /datum/species/golem/bronze

/mob/living/carbon/human/species/golem/cardboard
	race = /datum/species/golem/cardboard

/mob/living/carbon/human/species/golem/leather
	race = /datum/species/golem/leather

/mob/living/carbon/human/species/golem/bone
	race = /datum/species/golem/bone

/mob/living/carbon/human/species/golem/durathread
	race = /datum/species/golem/durathread

/mob/living/carbon/human/species/golem/snow
	race = /datum/species/golem/snow

/mob/living/carbon/human/species/jelly
	race = /datum/species/jelly

/mob/living/carbon/human/species/jelly/slime
	race = /datum/species/jelly/slime

/mob/living/carbon/human/species/jelly/stargazer
	race = /datum/species/jelly/stargazer

/mob/living/carbon/human/species/jelly/luminescent
	race = /datum/species/jelly/luminescent

/mob/living/carbon/human/species/lizard
	race = /datum/species/lizard

/mob/living/carbon/human/species/lizard/ashwalker
	race = /datum/species/lizard/ashwalker

/mob/living/carbon/human/species/lizard/silverscale
	race = /datum/species/lizard/silverscale

/mob/living/carbon/human/species/ethereal
	race = /datum/species/ethereal

/mob/living/carbon/human/species/lizard/ashwalker
	race = /datum/species/lizard/ashwalker

/mob/living/carbon/human/species/moth
	race = /datum/species/moth

/mob/living/carbon/human/species/mush
	race = /datum/species/mush

/mob/living/carbon/human/species/plasma
	race = /datum/species/plasmaman

/mob/living/carbon/human/species/pod
	race = /datum/species/pod

/mob/living/carbon/human/species/shadow
	race = /datum/species/shadow

/mob/living/carbon/human/species/shadow/nightmare
	race = /datum/species/shadow/nightmare

/mob/living/carbon/human/species/skeleton
	race = /datum/species/skeleton

/mob/living/carbon/human/species/snail
	race = /datum/species/snail

/mob/living/carbon/human/species/synth
	race = /datum/species/synth

/mob/living/carbon/human/species/synth/military
	race = /datum/species/synth/military

/mob/living/carbon/human/species/vampire
	race = /datum/species/vampire

/mob/living/carbon/human/species/zombie
	race = /datum/species/zombie

/mob/living/carbon/human/species/zombie/infectious
	race = /datum/species/zombie/infectious

/mob/living/carbon/human/species/zombie/krokodil_addict
	race = /datum/species/krokodil_addict
