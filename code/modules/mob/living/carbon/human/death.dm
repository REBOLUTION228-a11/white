GLOBAL_LIST_EMPTY(dead_players_during_shift)
/mob/living/carbon/human/gib_animation()
	new /obj/effect/temp_visual/gib_animation(loc, dna.species.gib_anim)

/mob/living/carbon/human/dust_animation()
	new /obj/effect/temp_visual/dust_animation(loc, dna?.species?.dust_anim)

/mob/living/carbon/human/spawn_gibs(with_bodyparts)
	if(with_bodyparts)
		new /obj/effect/gibspawner/human(drop_location(), src, get_static_viruses())
	else
		new /obj/effect/gibspawner/human/bodypartless(drop_location(), src, get_static_viruses())

/mob/living/carbon/human/spawn_dust(just_ash = FALSE)
	if(just_ash)
		new /obj/effect/decal/cleanable/ash(loc)
	else
		new /obj/effect/decal/remains/human(loc)

/mob/living/carbon/human/death(gibbed)
	if(stat == DEAD)
		return
	stop_sound_channel(CHANNEL_HEARTBEAT)
	var/obj/item/organ/heart/H = getorganslot(ORGAN_SLOT_HEART)
	if(H)
		H.beat = BEAT_NONE

	to_chat(client, \
	"<span class='notice'><i>Пришлось погибнуть. Было ли это по моей глупости или нет? Возможно моё тело ещё реанимируют, можно подождать...\
	\nГоворят, что после смерти есть возможность получить вторую жизнь, можно попробовать найти свой шанс...</i></span>")

	. = ..()

	dizziness = 0
	jitteriness = 0
	if(client && !suiciding && !(client in GLOB.dead_players_during_shift))
		GLOB.dead_players_during_shift += client
		GLOB.deaths_during_shift++

	if(!QDELETED(dna)) //The gibbed param is bit redundant here since dna won't exist at this point if they got deleted.
		dna.species.spec_death(gibbed, src)

	if(client && lastattackermob?.client)
		if(!HAS_TRAIT(src, TRAIT_YOHEI) && HAS_TRAIT(lastattackermob, TRAIT_YOHEI))
			if(GLOB.yohei_main_controller)
				var/obj/lab_monitor/yohei/LM = GLOB.yohei_main_controller
				if(!LM.is_this_target(src))
					SEND_SIGNAL(lastattackermob, COMSIG_ADD_MOOD_EVENT, "killed_innocent", /datum/mood_event/killed_innocent)

	if(SSticker.HasRoundStarted())
		SSblackbox.ReportDeath(src)
		log_message("has died (BRUTE: [src.getBruteLoss()], BURN: [src.getFireLoss()], TOX: [src.getToxLoss()], OXY: [src.getOxyLoss()], CLONE: [src.getCloneLoss()])", LOG_ATTACK)
	if(is_devil(src))
		INVOKE_ASYNC(is_devil(src), TYPE_PROC_REF(/datum/antagonist/devil, beginResurrectionCheck), src)

/client/proc/show_tgui_notice(header, msg)
	tgui_alert_async(src, header, msg, list("Понимаю"))

/mob/living/carbon/human/proc/makeSkeleton()
	ADD_TRAIT(src, TRAIT_DISFIGURED, TRAIT_GENERIC)
	set_species(/datum/species/skeleton)
	return TRUE


/mob/living/carbon/proc/Drain()
	become_husk(CHANGELING_DRAIN)
	ADD_TRAIT(src, TRAIT_BADDNA, CHANGELING_DRAIN)
	blood_volume = 0
	return TRUE

/mob/living/carbon/proc/makeUncloneable()
	ADD_TRAIT(src, TRAIT_BADDNA, MADE_UNCLONEABLE)
	blood_volume = 0
	return TRUE
