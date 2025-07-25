/datum/antagonist/heretic
	name = "Heretic"
	roundend_category = "Heretics"
	antagpanel_category = "Heretic"
	antag_moodlet = /datum/mood_event/heretics
	job_rank = ROLE_HERETIC
	antag_hud_type = ANTAG_HUD_HERETIC
	antag_hud_name = "heretic"
	hijack_speed = 0.5
	var/give_equipment = TRUE
	var/list/researched_knowledge = list()
	var/total_sacrifices = 0
	var/ascended = FALSE
	greentext_reward = 35

/datum/antagonist/heretic/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = FALSE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has heresized [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has heresized [key_name(new_owner)].")

/datum/antagonist/heretic/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ecult_op.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)//subject to change
	to_chat(owner, "<span class='boldannounce'>Да я же Еретик!</span><br>\
	<B>Древние Боги дали мне эти задания:</B>")
	owner.announce_objectives()
	to_chat(owner, "<span class='cult'>Меня пробил холодный пот, в моей голове зашумел гул, я чувствую, как древние, запретные знания охватывают мой разум. Книга тихо шепчет мне, что тайны, которые она в себе хранит, будут править этим местом. Древние Боги благословили меня знаниями, я должен выполнить их желания!<br>\
	Ваша книга позволяет вам исследовать способности. Прочтите это очень внимательно, потому что вы не можете отменить то, что было изучено!<br>\
	Вы получаете заряды, либо собирая разломы в реальности, либо принося людей в жертву Древним Богам. Живое сердце может помочь в поиске жертвы.<br> \
	Базовое руководство по ссылке : https://wiki.station13.ru/Heretic </span>")

/datum/antagonist/heretic/on_gain()
	var/mob/living/current = owner.current
	if(ishuman(current))
		forge_primary_objectives()
		for(var/eldritch_knowledge in GLOB.heretic_start_knowledge)
			gain_knowledge(eldritch_knowledge)
	current.log_message("has renounced the cult of the old ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.Generate()
	START_PROCESSING(SSprocessing,src)
	RegisterSignal(owner.current,COMSIG_LIVING_DEATH,PROC_REF(on_death))
	if(give_equipment)
		equip_cultist()
	return ..()

/datum/antagonist/heretic/on_removal()

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_lose(owner.current)

	if(!silent)
		to_chat(owner.current, span_userdanger("Your mind begins to flare as the otherwordly knowledge escapes your grasp!"))
		owner.current.log_message("has been converted to the cult of the forgotten ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.targets--
	STOP_PROCESSING(SSprocessing,src)

	on_death()

	return ..()


/datum/antagonist/heretic/proc/equip_cultist()
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	. += ecult_give_item(/obj/item/forbidden_book, H)
	. += ecult_give_item(/obj/item/living_heart, H)

/datum/antagonist/heretic/proc/ecult_give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where = H.equip_in_one_of_slots(T, slots)
	if(!where)
		to_chat(H, span_userdanger("Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1)."))
		return FALSE
	else
		to_chat(H, span_danger("You have a [item_name] in your [where]."))
		if(where == "backpack")
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)
		return TRUE

/datum/antagonist/heretic/process()

	if(owner?.current?.stat == DEAD)
		return

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_life(owner.current)

///What happens to the heretic once he dies, used to remove any custom perks
/datum/antagonist/heretic/proc/on_death()

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_death(owner.current)

/datum/antagonist/heretic/proc/forge_primary_objectives()
	var/list/assasination = list()
	var/list/protection = list()

	var/choose_list_begin = list("assassinate","protect")
	var/choose_list_end = list("assassinate","hijack","protect","glory")

	var/pck1 = pick(choose_list_begin)
	var/pck2 = pick(choose_list_end)

	forge_objective(pck1,assasination,protection)
	forge_objective(pck2,assasination,protection)

	var/datum/objective/sacrifice_ecult/SE = new
	SE.owner = owner
	SE.update_explanation_text()
	objectives += SE

/datum/antagonist/heretic/proc/forge_objective(string,assasination,protection)
	switch(string)
		if("assassinate")
			var/datum/objective/assassinate/A = new
			A.owner = owner
			var/list/owners = A.get_owners()
			A.find_target(owners,protection)
			assasination += A.target
			objectives += A
		if("hijack")
			var/datum/objective/hijack/hijack = new
			hijack.owner = owner
			objectives += hijack
		if("glory")
			var/datum/objective/martyr/martyrdom = new
			martyrdom.owner = owner
			objectives += martyrdom
		if("protect")
			var/datum/objective/protect/P = new
			P.owner = owner
			var/list/owners = P.get_owners()
			P.find_target(owners,assasination)
			protection += P.target
			objectives += P

/datum/antagonist/heretic/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	add_antag_hud(antag_hud_type, antag_hud_name, current)
	handle_clown_mutation(current, mob_override ? null : "Древние знания, описанные в книге, позволяют мне преодолеть свою шутовскую натуру, позволяя эффективно использовать сложные предметы.")
	current.faction |= "heretics"

/datum/antagonist/heretic/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	remove_antag_hud(antag_hud_type, current)
	handle_clown_mutation(current, removing = FALSE)
	current.faction -= "heretics"

/datum/antagonist/heretic/get_admin_commands()
	. = ..()
	.["Equip"] = CALLBACK(src,PROC_REF(equip_cultist))

/datum/antagonist/heretic/roundend_report()
	var/list/parts = list()

	var/cultiewin = TRUE

	parts += printplayer(owner)
	parts += "<b>Sacrifices Made:</b> [total_sacrifices]"

	if(length(objectives))
		var/count = 1
		for(var/o in objectives)
			var/datum/objective/objective = o
			if(objective.check_completion())
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='greentext'>Success!</b></span>"
			else
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
				cultiewin = FALSE
			count++
	if(ascended)
		parts += "<span class='greentext big'>ЕРЕТИК ВОЗНЕССЯ!</span>"
	else
		if(cultiewin)
			parts += span_greentext("Еретик приблизился к Богам!")
		else
			parts += span_redtext("Еретик потерпел поражение.")

	parts += "<b>Knowledge Researched:</b> "

	var/list/knowledge_message = list()
	var/list/knowledge = get_all_knowledge()
	for(var/X in knowledge)
		var/datum/eldritch_knowledge/EK = knowledge[X]
		knowledge_message += "[EK.name]"
	parts += knowledge_message.Join(", ")

	return parts.Join("<br>")
////////////////
// Knowledge //
////////////////

/datum/antagonist/heretic/proc/gain_knowledge(datum/eldritch_knowledge/EK)
	if(get_knowledge(EK))
		return FALSE
	var/datum/eldritch_knowledge/initialized_knowledge = new EK
	researched_knowledge[initialized_knowledge.type] = initialized_knowledge
	initialized_knowledge.on_gain(owner.current)
	return TRUE

/datum/antagonist/heretic/proc/get_researchable_knowledge()
	var/list/researchable_knowledge = list()
	var/list/banned_knowledge = list()
	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		researchable_knowledge |= EK.next_knowledge
		banned_knowledge |= EK.banned_knowledge
		banned_knowledge |= EK.type
	researchable_knowledge -= banned_knowledge
	return researchable_knowledge

/datum/antagonist/heretic/proc/get_knowledge(wanted)
	return researched_knowledge[wanted]

/datum/antagonist/heretic/proc/get_all_knowledge()
	return researched_knowledge

////////////////
// Objectives //
////////////////

/datum/objective/sacrifice_ecult
	name = "sacrifice"

/datum/objective/sacrifice_ecult/update_explanation_text()
	. = ..()
	target_amount = rand(2,6)
	explanation_text = "Sacrifice at least [target_amount] people."

/datum/objective/sacrifice_ecult/check_completion()
	if(!owner)
		return FALSE
	var/datum/antagonist/heretic/cultie = owner.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return FALSE
	return cultie.total_sacrifices >= target_amount
