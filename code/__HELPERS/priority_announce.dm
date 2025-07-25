/proc/priority_announce(text, title = "", sound, type, sender_override, has_important_message)
	if(!text)
		return

	var/announcement
	if(!istype(sound, /sound))
		sound = SSstation.announcer.event_sounds[sound] || SSstation.announcer.get_rand_alert_sound()

	//announcement += "<hr class='veryalert'>"

	if(type == "Priority")
		announcement += "<h1 class='alert'>Срочное Объявление</h1>"
		if (title && length(title) > 0)
			announcement += "<h2 class='alert'>[html_encode(title)]</h2>"
	else if(type == "Captain")
		announcement += "<h1 class='alert'>Капитан Объявляет</h1>"
		GLOB.news_network.SubmitArticle(text, "Капитан Объявляет", "Станционные Объявления", null)

	else
		if(!sender_override)
			announcement += "<h1 class='alert'>[command_name()]</h1>"
		else
			announcement += "<h1 class='alert'>[sender_override]</h1>"
		if (title && length(title) > 0)
			announcement += "<h2 class='alert'>[html_encode(title)]</h2>"

		if(!sender_override)
			if(title == "")
				GLOB.news_network.SubmitArticle(text, "Центральное Командование", "Станционные Объявления", null)
			else
				GLOB.news_network.SubmitArticle(title + "\n" + text, "Центральное Командование", "Станционные Объявления", null)

	///If the announcer overrides alert messages, use that message.
	if(SSstation.announcer.custom_alert_message && !has_important_message)
		announcement +=  SSstation.announcer.custom_alert_message
	else
		announcement += span_alert("<big>[html_encode(text)]</big>")
	announcement += "\n\n"

	var/s = sound(sound)
	for(var/mob/M in GLOB.player_list)
		var/turf/T = get_turf(M)
		if(!isnewplayer(M) && M.can_hear() && (is_station_level(T.z) || is_mining_level(T.z) || is_centcom_level(T.z)))
			to_chat(M, announcement)
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				SEND_SOUND(M, s)

/**
 * Summon the crew for an emergency meeting
 *
 * Teleports the crew to a specified area, and tells everyone (via an announcement) who called the meeting. Should only be used during april fools!
 * Arguments:
 * * user - Mob who called the meeting
 * * button_zone - Area where the meeting was called and where everyone will get teleported to
 */
/proc/call_emergency_meeting(user, area/button_zone)
	var/meeting_sound = sound('sound/misc/emergency_meeting.ogg')
	var/announcement
	announcement += "<h1 class='alert'>ТРЕВОГА!</h1>"
	announcement += "<br><span class='alert'>[user] делает экстренный сбор!</span><br><br>"

	for(var/mob/mob_to_teleport in GLOB.player_list) //gotta make sure the whole crew's here!
		if(isnewplayer(mob_to_teleport) || iscameramob(mob_to_teleport))
			continue

		to_chat(mob_to_teleport, announcement)
		SEND_SOUND(mob_to_teleport, meeting_sound) //no preferences here, you must hear the funny sound
		mob_to_teleport.overlay_fullscreen("emergency_meeting", /atom/movable/screen/fullscreen/emergency_meeting, 1)
		addtimer(CALLBACK(mob_to_teleport, TYPE_PROC_REF(/mob, clear_fullscreen), "emergency_meeting"), 3 SECONDS)

		if (is_station_level(mob_to_teleport.z)) //teleport the mob to the crew meeting
			var/turf/target
			var/list/turf_list = get_area_turfs(button_zone)
			while (!target && turf_list.len)
				target = pick_n_take(turf_list)
				if (isclosedturf(target))
					target = null
					continue
				mob_to_teleport.forceMove(target)

/proc/print_command_report(text = "", title = null, announce=TRUE)
	if(!title)
		title = "Секретно: [command_name()]"

	if(announce)
		priority_announce("Отчет был загружен и распечатан на всех коммуникационных консолях.", "Входящее Секретное Сообщение", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)

	var/datum/comm_message/M  = new
	M.title = title
	M.content =  text

	SScommunications.send_message(M)

/proc/minor_announce(message, title = "Внимание!", alert, html_encode = TRUE)
	if(!message)
		return

	if (html_encode)
		title = html_encode(title)
		message = html_encode(message)

	for(var/mob/M in GLOB.player_list)
		var/turf/T = get_turf(M)
		if(!isnewplayer(M) && M.can_hear() && (is_station_level(T.z) || is_mining_level(T.z) || is_centcom_level(T.z)))
			to_chat(M, "<h1 class='alert'>[title]</h1><span class='alert'><big>[message]</big></span>\n\n")
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				if(alert)
					SEND_SOUND(M, sound('sound/misc/notice1.ogg'))
				else
					SEND_SOUND(M, sound('sound/misc/notice2.ogg'))

/proc/exploration_announce(text, z_value)
	var/announcement = "<meta charset='UTF-8'>"
	announcement += "<h1 class='alert'>Обновление Задания</h1>"
	announcement += "<span class='alert'><big>[html_encode(text)]</big></span>\n\n"

	for(var/mob/M in GLOB.player_list)
		if(isliving(M))
			var/turf/T = get_turf(M)
			if(istype(get_area(M), /area/shuttle/exploration) || T.z == z_value)
				to_chat(M, announcement)
		if(isobserver(M))
			to_chat(M, announcement)

	print_command_report(text, "Обновление Рейнджеров")
