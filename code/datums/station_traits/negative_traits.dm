/datum/station_trait/carp_infestation
	name = "Заражение карпами"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	report_message = "В районе станции присутствует опасная фауна."
	trait_to_give = STATION_TRAIT_CARP_INFESTATION

/datum/station_trait/distant_supply_lines
	name = "Линии дальнего снабжения"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 3
	show_in_report = TRUE
	report_message = "Из-за удаленности от наших обычных линий снабжения заказы на грузовые перевозки обходятся дороже."
	blacklist = list(/datum/station_trait/strong_supply_lines)

/datum/station_trait/distant_supply_lines/on_round_start()
	SSeconomy.pack_price_modifier *= 1.2
/*
/datum/station_trait/late_arrivals
	name = "Late Arrivals"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 2
	show_in_report = TRUE
	report_message = "Sorry for that, we didn't expect to fly into that vomiting goose while bringing you to your new station."
	trait_to_give = STATION_TRAIT_LATE_ARRIVALS
	blacklist = list(/datum/station_trait/random_spawns, /datum/station_trait/hangover)

/datum/station_trait/random_spawns
	name = "Drive-by landing"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 2
	show_in_report = TRUE
	report_message = "Sorry for that, we missed your station by a few miles, so we just launched you towards your station in pods. Hope you don't mind!"
	trait_to_give = STATION_TRAIT_RANDOM_ARRIVALS
	blacklist = list(/datum/station_trait/late_arrivals, /datum/station_trait/hangover)
*/
/datum/station_trait/hangover
	name = "Похмелье"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 2
	show_in_report = TRUE
	report_message = "Ох... Чувак... Тот обязательный корпоратив из прошлой смены... Боже, это было круто... Я проснулся в каком-то случайном туалете в трех секторах отсюда..."
	trait_to_give = STATION_TRAIT_HANGOVER
	//blacklist = list(/datum/station_trait/late_arrivals, /datum/station_trait/random_spawns)

/datum/station_trait/hangover/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN, PROC_REF(on_job_after_spawn))


/datum/station_trait/hangover/proc/on_job_after_spawn(datum/source, datum/job/job, mob/living/spawned_mob)
	SIGNAL_HANDLER

	if(!prob(35))
		return
	var/obj/item/hat = pick(
		/obj/item/clothing/head/sombrero,
		/obj/item/clothing/head/fedora,
		/obj/item/clothing/mask/balaclava,
		/obj/item/clothing/head/ushanka,
		/obj/item/clothing/head/cardborg,
		/obj/item/clothing/head/pirate,
		/obj/item/clothing/head/cone,
		)
	hat = new hat(spawned_mob)
	spawned_mob.equip_to_slot_or_del(hat, ITEM_SLOT_HEAD)


/datum/station_trait/blackout
	name = "Затемнение"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 3
	show_in_report = TRUE
	report_message = "Освещение станции повреждено, будьте осторожны, начиная свою смену сегодня."

/datum/station_trait/blackout/on_round_start()
	. = ..()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(is_station_level(apc.z) && prob(60))
			apc.overload_lighting()
/*
/datum/station_trait/empty_maint
	name = "Cleaned out maintenance"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Our workers cleaned out most of the junk in the maintenace areas."
	blacklist = list(/datum/station_trait/filled_maint)
	trait_to_give = STATION_TRAIT_EMPTY_MAINT
*/

/datum/station_trait/overflow_job_bureaucracy
	name = "Ошибка переполнения бюрократии"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	var/chosen_job

/datum/station_trait/overflow_job_bureaucracy/New()
	. = ..()
	var/list/jobs_to_use = list(
		/datum/job/clown,
		/datum/job/bartender,
		/datum/job/cook,
		/datum/job/botanist,
		/datum/job/cargo_technician,
		/datum/job/mime,
		/datum/job/janitor,
		/datum/job/prisoner,
		)
	chosen_job = pick(jobs_to_use)
	RegisterSignal(SSjob, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(set_overflow_job_override))

/datum/station_trait/overflow_job_bureaucracy/get_report()
	return "[name] - Похоже, по какой-то причине мы выставили неправильный список вакансий для роли переполнения в эту смену... Надеюсь, вам понравится [chosen_job]s."

/datum/station_trait/overflow_job_bureaucracy/proc/set_overflow_job_override(datum/source, new_overflow_role)
	SIGNAL_HANDLER
	SSjob.set_overflow_role(chosen_job)

/datum/station_trait/slow_shuttle
	name = "Медленный шаттл"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Из-за удаленности от нашей станции снабжения грузовой шаттл будет лететь медленнее к вашему грузовому отделу."
	blacklist = list(/datum/station_trait/quick_shuttle)

/datum/station_trait/slow_shuttle/on_round_start()
	. = ..()
	SSshuttle.supply.callTime *= 1.5

/datum/station_trait/bot_languages
	name = "Неисправность матрицы языка ботов"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 3
	show_in_report = TRUE
	report_message = "У дружественных ботов вашей станции языковая матрица сгорела из-за какого-то события, что привело к появлению некоторых странных и незнакомых речевых моделей."

/datum/station_trait/bot_languages/New()
	. = ..()
	/// What "caused" our robots to go haywire (fluff)
	var/event_source = pick(list("ионный шторм", "попытка взлома синдиката", "сбой", "проблемы с ИИ на станции", "ошибки интерна", "урезания бюджета"))
	report_message = "Матрица языков дружелюбных ботов вашей станции сгорела из-за того, что [event_source] привели к странностям при общении с машинами."

/datum/station_trait/bot_languages/on_round_start()
	. = ..()
	//All bots that exist round start have their set language randomized.
	for(var/mob/living/simple_animal/bot/found_bot in GLOB.alive_mob_list)
		/// The bot's language holder - so we can randomize and change their language
		var/datum/language_holder/bot_languages = found_bot.get_language_holder()
		bot_languages.selected_language = bot_languages.get_random_spoken_language()

/datum/station_trait/revenge_of_pun_pun
	name = "Месть Пун-Пуна"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 2
	var/static/list/weapon_types

/datum/station_trait/revenge_of_pun_pun/New()
	if(!weapon_types)
		weapon_types = list(
			/obj/item/chair = 20,
			/obj/item/tailclub = 10,
			/obj/item/melee/baseball_bat = 10,
			/obj/item/melee/chainofcommand/tailwhip = 10,
			/obj/item/melee/chainofcommand/tailwhip/kitty = 10,
			/obj/item/reagent_containers/food/drinks/bottle = 20,
			/obj/item/reagent_containers/food/drinks/bottle/kong = 5,
			///obj/item/switchblade/extended = 10,
			///obj/item/sign/random = 10,
			/obj/item/gun/ballistic/automatic/pistol = 1,
		)

	RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(arm_monke))

/datum/station_trait/revenge_of_pun_pun/proc/arm_monke()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/species/monkey/punpun/punpun = locate()
	if(!punpun)
		return
	var/weapon_type = pickweight(weapon_types)
	var/obj/item/weapon = new weapon_type
	if(!punpun.put_in_l_hand(weapon) && !punpun.put_in_r_hand(weapon))
		// Guess they did all this with whatever they have in their hands already
		qdel(weapon)
		weapon = punpun.get_active_held_item() || punpun.get_inactive_held_item()

	weapon?.add_mob_blood(punpun)
	punpun.add_mob_blood(punpun)

	new /datum/ai_controller/monkey/angry(punpun)

	var/area/place = get_area(punpun)

	var/list/area_open_turfs = list()
	for(var/turf/location in place)
		if(location.density)
			continue
		area_open_turfs += location

	punpun.forceMove(pick(area_open_turfs))

	for(var/i in 1 to rand(10, 40))
		new /obj/effect/decal/cleanable/blood(pick(area_open_turfs))

	var/list/blood_path = list()
	for(var/i in 1 to 10) // Only 10 attempts
		var/turf/destination = pick(area_open_turfs)
		var/turf/next_step = get_step_to(punpun, destination)
		for(var/k in 1 to 30) // Max 30 steps
			if(!next_step)
				break
			blood_path += next_step
			next_step = get_step_to(next_step, destination)
		if(length(blood_path))
			break
	if(!length(blood_path))
		CRASH("Unable to make a path from punpun")

	var/turf/last_location
	for(var/turf/location as anything in blood_path)
		last_location = location

		if(prob(80))
			new /obj/effect/decal/cleanable/blood(location)

		if(prob(50))
			var/static/blood_types = list(
				/obj/effect/decal/cleanable/blood/splatter,
				/obj/effect/decal/cleanable/blood/gibs,
			)
			var/blood_type = pick(blood_types)
			new blood_type(get_turf(pick(orange(location, 2))))

	new /obj/effect/decal/cleanable/blood/gibs/torso(last_location)
