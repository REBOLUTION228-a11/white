/datum/admins/proc/CheckAdminHref(href, href_list)
	var/auth = href_list["admin_token"]
	. = auth && (auth == href_token || auth == GLOB.href_token)
	if(.)
		return
	var/msg = !auth ? "no" : "a bad"
	message_admins("[key_name_admin(usr)] clicked an href with [msg] authorization key!")
	if(CONFIG_GET(flag/debug_admin_hrefs))
		message_admins("Debug mode enabled, call not blocked. Please ask your coders to review this round's logs.")
		log_world("UAH: [href]")
		return TRUE
	log_admin_private("[key_name(usr)] clicked an href with [msg] authorization key! [href]")

/datum/admins/Topic(href, href_list)
	..()

	if(usr.client != src.owner || !check_rights(0))
		message_admins("[usr.key] has attempted to override the admin panel!")
		log_admin("[key_name(usr)] tried to use the admin panel without authorization.")
		return

	if(!CheckAdminHref(href, href_list))
		return

	if(href_list["ahelp"])
		if(!check_rights(R_ADMIN, TRUE))
			return

		var/ahelp_ref = href_list["ahelp"]
		var/datum/admin_help/AH = locate(ahelp_ref)
		if(AH)
			AH.Action(href_list["ahelp_action"])
		else
			to_chat(usr, "Ticket [ahelp_ref] has been deleted!")

	else if(href_list["ahelp_tickets"])
		GLOB.ahelp_tickets.BrowseTickets(text2num(href_list["ahelp_tickets"]))

	else if(href_list["stickyban"])
		stickyban(href_list["stickyban"],href_list)

	else if(href_list["getplaytimewindow"])
		if(!check_rights(R_ADMIN))
			return
		var/mob/M = locate(href_list["getplaytimewindow"]) in GLOB.mob_list
		if(!M)
			to_chat(usr, span_danger("ERROR: Mob not found."))
			return
		cmd_show_exp_panel(M.client)

	else if(href_list["toggleexempt"])
		if(!check_rights(R_PERMISSIONS))
			return
		var/client/C = locate(href_list["toggleexempt"]) in GLOB.clients
		if(!C)
			to_chat(usr, span_danger("ERROR: Client not found."))
			return
		toggle_exempt_status(C)

	else if(href_list["makeAntag"])
		if(!check_rights(R_ADMIN))
			return
		if (!SSticker.mode)
			to_chat(usr, span_danger("Not until the round starts!"))
			return
		switch(href_list["makeAntag"])
			if("traitors")
				if(src.makeTraitors())
					message_admins("[key_name_admin(usr)] created traitors.")
					log_admin("[key_name(usr)] created traitors.")
				else
					message_admins("[key_name_admin(usr)] tried to create traitors. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to create traitors.")
			if("changelings")
				if(src.makeChangelings())
					message_admins("[key_name(usr)] created changelings.")
					log_admin("[key_name(usr)] created changelings.")
				else
					message_admins("[key_name_admin(usr)] tried to create changelings. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to create changelings.")
			if("revs")
				if(src.makeRevs())
					message_admins("[key_name(usr)] started a revolution.")
					log_admin("[key_name(usr)] started a revolution.")
				else
					message_admins("[key_name_admin(usr)] tried to start a revolution. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to start a revolution.")
			if("cult")
				if(src.makeCult())
					message_admins("[key_name(usr)] started a cult.")
					log_admin("[key_name(usr)] started a cult.")
				else
					message_admins("[key_name_admin(usr)] tried to start a cult. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to start a cult.")
			if("wizard")
				message_admins("[key_name(usr)] is creating a wizard...")
				if(src.makeWizard())
					message_admins("[key_name(usr)] created a wizard.")
					log_admin("[key_name(usr)] created a wizard.")
				else
					message_admins("[key_name_admin(usr)] tried to create a wizard. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to create a wizard.")
			if("nukeops")
				message_admins("[key_name(usr)] is creating a nuke team...")
				if(src.makeNukeTeam())
					message_admins("[key_name(usr)] created a nuke team.")
					log_admin("[key_name(usr)] created a nuke team.")
				else
					message_admins("[key_name_admin(usr)] tried to create a nuke team. Unfortunately, there were not enough candidates available.")
					log_admin("[key_name(usr)] failed to create a nuke team.")
			if("ninja")
				message_admins("[key_name(usr)] spawned a ninja.")
				log_admin("[key_name(usr)] spawned a ninja.")
				src.makeSpaceNinja()
			if("aliens")
				message_admins("[key_name(usr)] started an alien infestation.")
				log_admin("[key_name(usr)] started an alien infestation.")
				src.makeAliens()
			if("deathsquad")
				message_admins("[key_name(usr)] is creating a death squad...")
				if(src.makeDeathsquad())
					message_admins("[key_name(usr)] created a death squad.")
					log_admin("[key_name(usr)] created a death squad.")
				else
					message_admins("[key_name_admin(usr)] tried to create a death squad. Unfortunately, there were not enough candidates available.")
					log_admin("[key_name(usr)] failed to create a death squad.")
			if("blob")
				var/strength = input("Set Blob Resource Gain Rate","Set Resource Rate",1) as num|null
				if(!strength)
					return
				message_admins("[key_name(usr)] spawned a blob with base resource gain [strength].")
				log_admin("[key_name(usr)] spawned a blob with base resource gain [strength].")
				new/datum/round_event/ghost_role/blob(TRUE, strength)
			if("centcom")
//				if(!check_rights(R_PERMISSIONS))
//					return
				message_admins("[key_name(usr)] is creating a CentCom response team...")
				if(src.makeEmergencyresponseteam())
					message_admins("[key_name(usr)] created a CentCom response team.")
					log_admin("[key_name(usr)] created a CentCom response team.")
				else
					message_admins("[key_name_admin(usr)] tried to create a CentCom response team. Unfortunately, there were not enough candidates available.")
					log_admin("[key_name(usr)] failed to create a CentCom response team.")
			if("abductors")
				message_admins("[key_name(usr)] is creating an abductor team...")
				if(src.makeAbductorTeam())
					message_admins("[key_name(usr)] created an abductor team.")
					log_admin("[key_name(usr)] created an abductor team.")
				else
					message_admins("[key_name_admin(usr)] tried to create an abductor team. Unfortunately there were not enough candidates available.")
					log_admin("[key_name(usr)] failed to create an abductor team.")
			if("revenant")
				if(src.makeRevenant())
					message_admins("[key_name(usr)] created a revenant.")
					log_admin("[key_name(usr)] created a revenant.")
				else
					message_admins("[key_name_admin(usr)] tried to create a revenant. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to create a revenant.")
			if("nerd")
				if(src.makeNerd())
					message_admins("[key_name(usr)] created a nanotrasen emergency response drone.")
					log_admin("[key_name(usr)] created a nanotrasen emergency response drone.")
				else
					message_admins("[key_name_admin(usr)] tried to create a nanotrasen emergency response drone. Unfortunately, there were no candidates available.")
					log_admin("[key_name(usr)] failed to create a nanotrasen emergency response drone.")

	else if(href_list["forceevent"])
		if(!check_rights(R_FUN))
			return
		var/datum/round_event_control/E = locate(href_list["forceevent"]) in SSevents.control
		if(E)
			E.admin_setup(usr)
			var/datum/round_event/event = E.runEvent()
			if(event.announceWhen>0)
				event.processing = FALSE
				var/prompt = tgui_alert(usr, "Would you like to alert the crew?", "Alert", list("Yes", "No", "Cancel"))
				switch(prompt)
					if("Yes")
						event.announceChance = 100
					if("Cancel")
						event.kill()
						return
					if("No")
						event.announceChance = 0
				event.on_admin_trigger()
				event.processing = TRUE
			message_admins("[key_name_admin(usr)] has triggered an event. ([E.name])")
			log_admin("[key_name(usr)] has triggered an event. ([E.name])")
		return

	else if(href_list["editrightsbrowser"])
		edit_admin_permissions(0)

	else if(href_list["editrightsbrowserlog"])
		edit_admin_permissions(1, href_list["editrightstarget"], href_list["editrightsoperation"], href_list["editrightspage"])

	if(href_list["editrightsbrowsermanage"])
		if(href_list["editrightschange"])
			change_admin_rank(ckey(href_list["editrightschange"]), href_list["editrightschange"], TRUE)
		else if(href_list["editrightsremove"])
			remove_admin(ckey(href_list["editrightsremove"]), href_list["editrightsremove"], TRUE)
		else if(href_list["editrightsremoverank"])
			remove_rank(href_list["editrightsremoverank"])
		edit_admin_permissions(2)

	else if(href_list["editrights"])
		edit_rights_topic(href_list)

	else if(href_list["gamemode_panel"])
		if(!check_rights(R_ADMIN))
			return
		SSticker.mode.admin_panel()

	else if(href_list["call_shuttle"])
		if(!check_rights(R_ADMIN))
			return


		switch(href_list["call_shuttle"])
			if("1")
				if(EMERGENCY_AT_LEAST_DOCKED)
					return
				SSshuttle.emergency.request()
				log_admin("[key_name(usr)] called the Emergency Shuttle.")
				message_admins(span_adminnotice("[key_name_admin(usr)] called the Emergency Shuttle to the station."))

			if("2")
				if(EMERGENCY_AT_LEAST_DOCKED)
					return
				switch(SSshuttle.emergency.mode)
					if(SHUTTLE_CALL)
						SSshuttle.emergency.cancel()
						log_admin("[key_name(usr)] sent the Emergency Shuttle back.")
						message_admins(span_adminnotice("[key_name_admin(usr)] sent the Emergency Shuttle back."))
					else
						SSshuttle.emergency.cancel()
						log_admin("[key_name(usr)] called the Emergency Shuttle.")
						message_admins(span_adminnotice("[key_name_admin(usr)] called the Emergency Shuttle to the station."))



	else if(href_list["edit_shuttle_time"])
		if(!check_rights(R_SERVER))
			return

		var/timer = input("Enter new shuttle duration (seconds):","Edit Shuttle Timeleft", SSshuttle.emergency.timeLeft() ) as num|null
		if(!timer)
			return
		SSshuttle.emergency.setTimer(timer SECONDS)
		log_admin("[key_name(usr)] edited the Emergency Shuttle's timeleft to [timer] seconds.")
		minor_announce("Эвакуационный шаттл прибудет через [DisplayTimeText(timer SECONDS)].")
		message_admins(span_adminnotice("[key_name_admin(usr)] edited the Emergency Shuttle's timeleft to [timer] seconds."))
	else if(href_list["trigger_centcom_recall"])
		if(!check_rights(R_ADMIN))
			return

		usr.client.trigger_centcom_recall()

	else if(href_list["move_shuttle"])
		if(!check_rights(R_ADMIN))
			return

		var/obj/docking_port/mobile/shuttle = SSshuttle.getShuttle(href_list["move_shuttle"])
		if(!shuttle)
			return
		shuttle.admin_fly_shuttle(usr)

	else if(href_list["unlock_shuttle"])
		if(!check_rights(R_ADMIN))
			return

		var/obj/machinery/computer/shuttle_flight/shuttle_console = locate(href_list["unlock_shuttle"])
		if(!shuttle_console)
			return
		shuttle_console.admin_controlled = !shuttle_console.admin_controlled
		to_chat(usr, "[shuttle_console] was [shuttle_console.admin_controlled ? "locked" : "unlocked"].")

	else if(href_list["toggle_continuous"])
		if(!check_rights(R_ADMIN))
			return
		var/list/continuous = CONFIG_GET(keyed_list/continuous)
		if(!continuous[SSticker.mode.config_tag])
			continuous[SSticker.mode.config_tag] = TRUE
		else
			continuous[SSticker.mode.config_tag] = FALSE

		message_admins(span_adminnotice("[key_name_admin(usr)] toggled the round to [continuous[SSticker.mode.config_tag] ? "continue if all antagonists die" : "end with the antagonists"]."))
		check_antagonists()

	else if(href_list["toggle_midround_antag"])
		if(!check_rights(R_ADMIN))
			return

		var/list/midround_antag = CONFIG_GET(keyed_list/midround_antag)
		if(!midround_antag[SSticker.mode.config_tag])
			midround_antag[SSticker.mode.config_tag] = TRUE
		else
			midround_antag[SSticker.mode.config_tag] = FALSE

		message_admins(span_adminnotice("[key_name_admin(usr)] toggled the round to [midround_antag[SSticker.mode.config_tag] ? "use" : "skip"] the midround antag system."))
		check_antagonists()

	else if(href_list["alter_midround_time_limit"])
		if(!check_rights(R_ADMIN))
			return

		var/timer = input("Enter new maximum time",, CONFIG_GET(number/midround_antag_time_check)) as num|null
		if(!timer)
			return
		CONFIG_SET(number/midround_antag_time_check, timer)
		message_admins(span_adminnotice("[key_name_admin(usr)] edited the maximum midround antagonist time to [timer] minutes."))
		check_antagonists()

	else if(href_list["alter_midround_life_limit"])
		if(!check_rights(R_ADMIN))
			return

		var/ratio = input("Enter new life ratio",, CONFIG_GET(number/midround_antag_life_check) * 100) as num|null
		if(!ratio)
			return
		CONFIG_SET(number/midround_antag_life_check, ratio / 100)

		message_admins(span_adminnotice("[key_name_admin(usr)] edited the midround antagonist living crew ratio to [ratio]% alive."))
		check_antagonists()

	else if(href_list["toggle_noncontinuous_behavior"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.mode.round_ends_with_antag_death)
			SSticker.mode.round_ends_with_antag_death = 1
		else
			SSticker.mode.round_ends_with_antag_death = 0

		message_admins(span_adminnotice("[key_name_admin(usr)] edited the midround antagonist system to [SSticker.mode.round_ends_with_antag_death ? "end the round" : "continue as extended"] upon failure."))
		check_antagonists()

	else if(href_list["delay_round_end"])
		if(!check_rights(R_SERVER))
			return
		if(!SSticker.delay_end)
			SSticker.admin_delay_notice = input(usr, "Enter a reason for delaying the round end", "Round Delay Reason") as null|text
			if(isnull(SSticker.admin_delay_notice))
				return
		else
			if(tgui_alert(usr, "Really cancel current round end delay? The reason for the current delay is: \"[SSticker.admin_delay_notice]\"", "Undelay round end", list("Yes", "No")) != "Yes")
				return
			SSticker.admin_delay_notice = null
		SSticker.delay_end = !SSticker.delay_end
		var/reason = SSticker.delay_end ? "for reason: [SSticker.admin_delay_notice]" : "."//laziness
		var/msg = "[SSticker.delay_end ? "delayed" : "undelayed"] the round end [reason]"
		log_admin("[key_name(usr)] [msg]")
		message_admins("[key_name_admin(usr)] [msg]")
		if(SSticker.ready_for_reboot && !SSticker.delay_end) //we undelayed after standard reboot would occur
			SSticker.standard_reboot()

	else if(href_list["end_round"])
		if(!check_rights(R_ADMIN))
			return

		message_admins(span_adminnotice("[key_name_admin(usr)] is considering ending the round."))
		if(tgui_alert(usr, "This will end the round, are you SURE you want to do this?", "Confirmation", list("Yes", "No")) == "Yes")
			if(tgui_alert(usr, "Final Confirmation: End the round NOW?", "Confirmation", list("Yes", "No")) == "Yes")
				message_admins(span_adminnotice("[key_name_admin(usr)] has ended the round."))
				SSticker.force_ending = 1 //Yeah there we go APC destroyed mission accomplished
				return
			else
				message_admins(span_adminnotice("[key_name_admin(usr)] decided against ending the round."))
		else
			message_admins(span_adminnotice("[key_name_admin(usr)] decided against ending the round."))

	else if(href_list["simplemake"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/M = locate(href_list["mob"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return

		var/delmob = TRUE
		if(!isobserver(M))
			switch(tgui_alert(usr,"Delete old mob?","Message",list("Yes","No","Cancel")))
				if("Cancel")
					return
				if("No")
					delmob = FALSE

		log_admin("[key_name(usr)] has used rudimentary transformation on [key_name(M)]. Transforming to [href_list["simplemake"]].; deletemob=[delmob]")
		message_admins(span_adminnotice("[key_name_admin(usr)] has used rudimentary transformation on [key_name_admin(M)]. Transforming to [href_list["simplemake"]].; deletemob=[delmob]"))
		switch(href_list["simplemake"])
			if("observer")
				M.change_mob_type( /mob/dead/observer , null, null, delmob )
			if("drone")
				M.change_mob_type( /mob/living/carbon/alien/humanoid/drone , null, null, delmob )
			if("hunter")
				M.change_mob_type( /mob/living/carbon/alien/humanoid/hunter , null, null, delmob )
			if("queen")
				M.change_mob_type( /mob/living/carbon/alien/humanoid/royal/queen , null, null, delmob )
			if("praetorian")
				M.change_mob_type( /mob/living/carbon/alien/humanoid/royal/praetorian , null, null, delmob )
			if("sentinel")
				M.change_mob_type( /mob/living/carbon/alien/humanoid/sentinel , null, null, delmob )
			if("larva")
				M.change_mob_type( /mob/living/carbon/alien/larva , null, null, delmob )
			if("human")
				var/posttransformoutfit = usr.client.robust_dress_shop()
				if (!posttransformoutfit)
					return
				var/mob/living/carbon/human/newmob = M.change_mob_type( /mob/living/carbon/human , null, null, delmob )
				if(posttransformoutfit && istype(newmob))
					newmob.equipOutfit(posttransformoutfit)
			if("slime")
				M.change_mob_type( /mob/living/simple_animal/slime , null, null, delmob )
			if("monkey")
				M.change_mob_type( /mob/living/carbon/human/species/monkey , null, null, delmob )
			if("robot")
				M.change_mob_type( /mob/living/silicon/robot , null, null, delmob )
			if("cat")
				M.change_mob_type( /mob/living/simple_animal/pet/cat , null, null, delmob )
			if("runtime")
				M.change_mob_type( /mob/living/simple_animal/pet/cat/runtime , null, null, delmob )
			if("corgi")
				M.change_mob_type( /mob/living/simple_animal/pet/dog/corgi , null, null, delmob )
			if("ian")
				M.change_mob_type( /mob/living/simple_animal/pet/dog/corgi/ian , null, null, delmob )
			if("pug")
				M.change_mob_type( /mob/living/simple_animal/pet/dog/pug , null, null, delmob )
			if("crab")
				M.change_mob_type( /mob/living/simple_animal/crab , null, null, delmob )
			if("coffee")
				M.change_mob_type( /mob/living/simple_animal/crab/coffee , null, null, delmob )
			if("parrot")
				M.change_mob_type( /mob/living/simple_animal/parrot , null, null, delmob )
			if("polyparrot")
				M.change_mob_type( /mob/living/simple_animal/parrot/poly , null, null, delmob )
			if("constructjuggernaut")
				M.change_mob_type( /mob/living/simple_animal/hostile/construct/juggernaut , null, null, delmob )
			if("constructartificer")
				M.change_mob_type( /mob/living/simple_animal/hostile/construct/artificer , null, null, delmob )
			if("constructwraith")
				M.change_mob_type( /mob/living/simple_animal/hostile/construct/wraith , null, null, delmob )
			if("shade")
				M.change_mob_type( /mob/living/simple_animal/shade , null, null, delmob )

	else if(href_list["boot2"])
		if(!check_rights(R_ADMIN))
			return
		var/mob/M = locate(href_list["boot2"])
		if(ismob(M))
			if(!check_if_greater_rights_than(M.client))
				to_chat(usr, span_danger("Error: They have more rights than you do."))
				return
			if(tgui_alert(usr, "Kick [key_name(M)]?", "Confirm", list("Yes", "No")) != "Yes")
				return
			if(!M)
				to_chat(usr, span_danger("Error: [M] no longer exists!"))
				return
			if(!M.client)
				to_chat(usr, span_danger("Error: [M] no longer has a client!"))
				return
			//to_chat(M, span_danger("You have been kicked from the server by [usr.client.holder.fakekey ? "an Administrator" : "[usr.client.key]"]."))
			log_admin("[key_name(usr)] kicked [key_name(M)].")
			message_admins(span_adminnotice("[key_name_admin(usr)] kicked [key_name_admin(M)]."))
			qdel(M.client)

	else if(href_list["addmessage"])
		if(!check_rights(R_ADMIN))
			return
		var/target_key = href_list["addmessage"]
		create_message("message", target_key, secret = 0)

	else if(href_list["addnote"])
		if(!check_rights(R_ADMIN))
			return
		var/target_key = href_list["addnote"]
		create_message("note", target_key)

	else if(href_list["addwatch"])
		if(!check_rights(R_ADMIN))
			return
		var/target_key = href_list["addwatch"]
		create_message("watchlist entry", target_key, secret = 1)

	else if(href_list["addmemo"])
		if(!check_rights(R_ADMIN))
			return
		create_message("memo", secret = 0, browse = 1)

	else if(href_list["addmessageempty"])
		if(!check_rights(R_ADMIN))
			return
		create_message("message", secret = 0)

	else if(href_list["addnoteempty"])
		if(!check_rights(R_ADMIN))
			return
		create_message("note")

	else if(href_list["addwatchempty"])
		if(!check_rights(R_ADMIN))
			return
		create_message("watchlist entry", secret = 1)

	else if(href_list["deletemessage"])
		if(!check_rights(R_ADMIN))
			return
		var/safety = tgui_alert(usr,"Delete message/note?",,list("Yes","No"));
		if (safety == "Yes")
			var/message_id = href_list["deletemessage"]
			delete_message(message_id)

	else if(href_list["deletemessageempty"])
		if(!check_rights(R_ADMIN))
			return
		var/safety = tgui_alert(usr,"Delete message/note?",,list("Yes","No"));
		if (safety == "Yes")
			var/message_id = href_list["deletemessageempty"]
			delete_message(message_id, browse = TRUE)

	else if(href_list["editmessage"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["editmessage"]
		edit_message(message_id)

	else if(href_list["editmessageempty"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["editmessageempty"]
		edit_message(message_id, browse = 1)

	else if(href_list["editmessageexpiry"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["editmessageexpiry"]
		edit_message_expiry(message_id)

	else if(href_list["editmessageexpiryempty"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["editmessageexpiryempty"]
		edit_message_expiry(message_id, browse = 1)

	else if(href_list["editmessageseverity"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["editmessageseverity"]
		edit_message_severity(message_id)

	else if(href_list["secretmessage"])
		if(!check_rights(R_ADMIN))
			return
		var/message_id = href_list["secretmessage"]
		toggle_message_secrecy(message_id)

	else if(href_list["searchmessages"])
		if(!check_rights(R_ADMIN))
			return
		var/target = href_list["searchmessages"]
		browse_messages(index = target)

	else if(href_list["nonalpha"])
		if(!check_rights(R_ADMIN))
			return
		var/target = href_list["nonalpha"]
		target = text2num(target)
		browse_messages(index = target)

	else if(href_list["showmessages"])
		if(!check_rights(R_ADMIN))
			return
		var/target = href_list["showmessages"]
		browse_messages(index = target)

	else if(href_list["showmemo"])
		if(!check_rights(R_ADMIN))
			return
		browse_messages("memo")

	else if(href_list["showwatch"])
		if(!check_rights(R_ADMIN))
			return
		browse_messages("watchlist entry")

	else if(href_list["showwatchfilter"])
		if(!check_rights(R_ADMIN))
			return
		browse_messages("watchlist entry", filter = 1)

	else if(href_list["showmessageckey"])
		if(!check_rights(R_ADMIN))
			return
		var/target = href_list["showmessageckey"]
		var/agegate = TRUE
		if (href_list["showall"])
			agegate = FALSE
		browse_messages(target_ckey = target, agegate = agegate)

	else if(href_list["showmessageckeylinkless"])
		var/target = href_list["showmessageckeylinkless"]
		browse_messages(target_ckey = target, linkless = 1)

	else if(href_list["messageedits"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/db_query/query_get_message_edits = SSdbcore.NewQuery(
			"SELECT edits FROM [format_table_name("messages")] WHERE id = :message_id",
			list("message_id" = href_list["messageedits"])
		)
		if(!query_get_message_edits.warn_execute())
			qdel(query_get_message_edits)
			return
		if(query_get_message_edits.NextRow())
			var/edit_log = query_get_message_edits.item[1]
			if(!QDELETED(usr))
				var/datum/browser/browser = new(usr, "Note edits", "Note edits")
				browser.set_content(jointext(edit_log, ""))
				browser.open()
		qdel(query_get_message_edits)

	else if(href_list["mute"])
		if(!check_rights(R_ADMIN))
			return
		cmd_admin_mute(href_list["mute"], text2num(href_list["mute_type"]))

	else if(href_list["c_mode"])
		return HandleCMode()

	else if(href_list["f_secret"])
		return HandleFSecret()

	else if(href_list["f_dynamic_roundstart"])
		if(!check_rights(R_ADMIN))
			return
		if(SSticker?.mode)
			return tgui_alert(usr, "The game has already started.")
		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode.")
		var/roundstart_rules = list()
		for (var/rule in subtypesof(/datum/dynamic_ruleset/roundstart))
			var/datum/dynamic_ruleset/roundstart/newrule = new rule()
			roundstart_rules[newrule.name] = newrule
		var/added_rule = input(usr,"What ruleset do you want to force? This will bypass threat level and population restrictions.", "Rigging Roundstart", null) as null|anything in sort_list(roundstart_rules)
		if (added_rule)
			GLOB.dynamic_forced_roundstart_ruleset += roundstart_rules[added_rule]
			log_admin("[key_name(usr)] set [added_rule] to be a forced roundstart ruleset.")
			message_admins("[key_name(usr)] set [added_rule] to be a forced roundstart ruleset.", 1)
			Game()

	else if(href_list["f_dynamic_roundstart_clear"])
		if(!check_rights(R_ADMIN))
			return
		GLOB.dynamic_forced_roundstart_ruleset = list()
		Game()
		log_admin("[key_name(usr)] cleared the rigged roundstart rulesets. The mode will pick them as normal.")
		message_admins("[key_name(usr)] cleared the rigged roundstart rulesets. The mode will pick them as normal.", 1)

	else if(href_list["f_dynamic_roundstart_remove"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/dynamic_ruleset/roundstart/rule = locate(href_list["f_dynamic_roundstart_remove"])
		GLOB.dynamic_forced_roundstart_ruleset -= rule
		Game()
		log_admin("[key_name(usr)] removed [rule] from the forced roundstart rulesets.")
		message_admins("[key_name(usr)] removed [rule] from the forced roundstart rulesets.", 1)

	else if (href_list["f_dynamic_options"])
		if(!check_rights(R_ADMIN))
			return

		if(SSticker?.mode)
			return tgui_alert(usr, "The game has already started.")
		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode!")

		dynamic_mode_options(usr)
	else if(href_list["f_dynamic_force_extended"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode!")

		GLOB.dynamic_forced_extended = !GLOB.dynamic_forced_extended
		log_admin("[key_name(usr)] set 'forced_extended' to [GLOB.dynamic_forced_extended].")
		message_admins("[key_name(usr)] set 'forced_extended' to [GLOB.dynamic_forced_extended].")
		dynamic_mode_options(usr)

	else if(href_list["f_dynamic_no_stacking"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode!")

		GLOB.dynamic_no_stacking = !GLOB.dynamic_no_stacking
		log_admin("[key_name(usr)] set 'no_stacking' to [GLOB.dynamic_no_stacking].")
		message_admins("[key_name(usr)] set 'no_stacking' to [GLOB.dynamic_no_stacking].")
		dynamic_mode_options(usr)
	else if(href_list["f_dynamic_stacking_limit"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode!")

		GLOB.dynamic_stacking_limit = input(usr,"Change the threat limit at which round-endings rulesets will start to stack.", "Change stacking limit", null) as num
		log_admin("[key_name(usr)] set 'stacking_limit' to [GLOB.dynamic_stacking_limit].")
		message_admins("[key_name(usr)] set 'stacking_limit' to [GLOB.dynamic_stacking_limit].")
		dynamic_mode_options(usr)

	else if(href_list["f_dynamic_forced_threat"])
		if(!check_rights(R_ADMIN))
			return

		if(SSticker?.mode)
			return tgui_alert(usr, "The game has already started.")

		if(!SSticker.is_mode("dynamic"))
			return tgui_alert(usr, "The game mode has to be dynamic mode!")

		var/new_value = input(usr, "Enter the forced threat level for dynamic mode.", "Forced threat level") as num
		if (new_value > 100)
			return tgui_alert(usr, "The value must be be under 100.")
		GLOB.dynamic_forced_threat_level = new_value

		log_admin("[key_name(usr)] set 'forced_threat_level' to [GLOB.dynamic_forced_threat_level].")
		message_admins("[key_name(usr)] set 'forced_threat_level' to [GLOB.dynamic_forced_threat_level].")
		dynamic_mode_options(usr)

	else if(href_list["c_mode2"])
		if(!check_rights(R_ADMIN|R_SERVER))
			return

		if (SSticker.HasRoundStarted())
			if (tgui_alert(usr, "The game has already started. Would you like to save this as the default mode effective next round?", "Save mode", list("Yes", "Cancel"), timeout = 0) == "Yes")
				SSticker.save_mode(href_list["c_mode2"])
			HandleCMode()
			return
		GLOB.master_mode = href_list["c_mode2"]
		log_admin("[key_name(usr)] set the mode as [GLOB.master_mode].")
		message_admins(span_adminnotice("[key_name_admin(usr)] set the mode as [GLOB.master_mode]."))
		to_chat(world, span_adminnotice("<b>Режим: [GLOB.master_mode]</b>"))
		Game() // updates the main game menu
		if (tgui_alert(usr, "Оставляем навсегда?", "Сохранение", list("Да", "Нет"), timeout = 0) == "Да")
			SSticker.save_mode(GLOB.master_mode)
		HandleCMode()

	else if(href_list["f_secret2"])
		if(!check_rights(R_ADMIN|R_SERVER))
			return

		if(SSticker.HasRoundStarted())
			return tgui_alert(usr, "The game has already started.", null, null, null, null)
		if(GLOB.master_mode != "secret")
			return tgui_alert(usr, "The game mode has to be secret!", null, null, null, null)
		GLOB.secret_force_mode = href_list["f_secret2"]
		log_admin("[key_name(usr)] set the forced secret mode as [GLOB.secret_force_mode].")
		message_admins(span_adminnotice("[key_name_admin(usr)] set the forced secret mode as [GLOB.secret_force_mode]."))
		Game() // updates the main game menu
		HandleFSecret()

	else if(href_list["monkeyone"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["monkeyone"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		log_admin("[key_name(usr)] attempting to monkeyize [key_name(H)].")
		message_admins(span_adminnotice("[key_name_admin(usr)] attempting to monkeyize [key_name_admin(H)]."))
		H.monkeyize()

	else if(href_list["humanone"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/Mo = locate(href_list["humanone"])
		if(!ismonkey(Mo))
			to_chat(usr, "This can only be used on monkeys.")
			return

		log_admin("[key_name(usr)] attempting to humanize [key_name(Mo)].")
		message_admins(span_adminnotice("[key_name_admin(usr)] attempting to humanize [key_name_admin(Mo)]."))
		Mo.humanize()

	else if(href_list["corgione"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["corgione"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		log_admin("[key_name(usr)] attempting to corgize [key_name(H)].")
		message_admins(span_adminnotice("[key_name_admin(usr)] attempting to corgize [key_name_admin(H)]."))
		H.corgize()


	else if(href_list["sendtoprison"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["sendtoprison"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return
		if(isAI(M))
			to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
			return

		if(tgui_alert(usr, "Send [key_name(M)] to Prison?", "Message", list("Yes", "No")) != "Yes")
			return

		M.forceMove(pick(GLOB.prisonwarp))
		//to_chat(M, span_adminnotice("You have been sent to Prison!"))

		log_admin("[key_name(usr)] has sent [key_name(M)] to Prison!")
		message_admins("[key_name_admin(usr)] has sent [key_name_admin(M)] to Prison!")

	else if(href_list["sendbacktolobby"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["sendbacktolobby"])

		if(!isobserver(M))
			to_chat(usr, span_notice("You can only send ghost players back to the Lobby."))
			return

		if(!M.client)
			to_chat(usr, span_warning("[M] doesn't seem to have an active client."))
			return

		if(tgui_alert(usr, "Send [key_name(M)] back to Lobby?", "Message", list("Yes", "No")) != "Yes")
			return

		log_admin("[key_name(usr)] has sent [key_name(M)] back to the Lobby.")
		message_admins("[key_name(usr)] has sent [key_name(M)] back to the Lobby.")

		var/mob/dead/new_player/NP = new()
		NP.ckey = M.ckey
		qdel(M)

	else if(href_list["tdome1"])
		if(!check_rights(R_FUN))
			return

		if(tgui_alert(usr, "Confirm?", "Message", list("Yes", "No")) != "Yes")
			return

		var/mob/M = locate(href_list["tdome1"])
		if(!isliving(M))
			to_chat(usr, "This can only be used on instances of type /mob/living.")
			return
		if(isAI(M))
			to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
			return
		var/mob/living/L = M

		for(var/obj/item/I in L)
			L.dropItemToGround(I, TRUE)

		L.Unconscious(100)
		sleep(5)
		L.forceMove(pick(GLOB.tdome1))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), L, span_adminnotice("You have been sent to the Thunderdome.")), 5 SECONDS)
		log_admin("[key_name(usr)] has sent [key_name(L)] to the thunderdome. (Team 1)")
		message_admins("[key_name_admin(usr)] has sent [key_name_admin(L)] to the thunderdome. (Team 1)")

	else if(href_list["tdome2"])
		if(!check_rights(R_FUN))
			return

		if(tgui_alert(usr, "Confirm?", "Message", list("Yes", "No")) != "Yes")
			return

		var/mob/M = locate(href_list["tdome2"])
		if(!isliving(M))
			to_chat(usr, "This can only be used on instances of type /mob/living.")
			return
		if(isAI(M))
			to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
			return
		var/mob/living/L = M

		for(var/obj/item/I in L)
			L.dropItemToGround(I, TRUE)

		L.Unconscious(100)
		sleep(5)
		L.forceMove(pick(GLOB.tdome2))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), L, span_adminnotice("You have been sent to the Thunderdome.")), 5 SECONDS)
		log_admin("[key_name(usr)] has sent [key_name(L)] to the thunderdome. (Team 2)")
		message_admins("[key_name_admin(usr)] has sent [key_name_admin(L)] to the thunderdome. (Team 2)")

	else if(href_list["tdomeadmin"])
		if(!check_rights(R_FUN))
			return

		if(tgui_alert(usr, "Confirm?", "Message", list("Yes", "No")) != "Yes")
			return

		var/mob/M = locate(href_list["tdomeadmin"])
		if(!isliving(M))
			to_chat(usr, "This can only be used on instances of type /mob/living.")
			return
		if(isAI(M))
			to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
			return
		var/mob/living/L = M

		L.Unconscious(100)
		sleep(5)
		L.forceMove(pick(GLOB.tdomeadmin))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), L, span_adminnotice("You have been sent to the Thunderdome.")), 5 SECONDS)
		log_admin("[key_name(usr)] has sent [key_name(L)] to the thunderdome. (Admin.)")
		message_admins("[key_name_admin(usr)] has sent [key_name_admin(L)] to the thunderdome. (Admin.)")

	else if(href_list["tdomeobserve"])
		if(!check_rights(R_FUN))
			return

		if(tgui_alert(usr, "Confirm?", "Message", list("Yes", "No")) != "Yes")
			return

		var/mob/M = locate(href_list["tdomeobserve"])
		if(!isliving(M))
			to_chat(usr, "This can only be used on instances of type /mob/living.")
			return
		if(isAI(M))
			to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
			return
		var/mob/living/L = M

		for(var/obj/item/I in L)
			L.dropItemToGround(I, TRUE)

		if(ishuman(L))
			var/mob/living/carbon/human/observer = L
			observer.equip_to_slot_or_del(new /obj/item/clothing/under/suit/black(observer), ITEM_SLOT_ICLOTHING)
			observer.equip_to_slot_or_del(new /obj/item/clothing/shoes/sneakers/black(observer), ITEM_SLOT_FEET)
		L.Unconscious(100)
		sleep(5)
		L.forceMove(pick(GLOB.tdomeobserve))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), L, span_adminnotice("You have been sent to the Thunderdome.")), 5 SECONDS)
		log_admin("[key_name(usr)] has sent [key_name(L)] to the thunderdome. (Observer.)")
		message_admins("[key_name_admin(usr)] has sent [key_name_admin(L)] to the thunderdome. (Observer.)")

	else if(href_list["revive"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/L = locate(href_list["revive"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /mob/living.")
			return

		L.revive(full_heal = TRUE, admin_revive = TRUE)
		message_admins(span_danger("Admin [key_name_admin(usr)] healed / revived [key_name_admin(L)]!"))
		log_admin("[key_name(usr)] healed / Revived [key_name(L)].")

	else if(href_list["makeai"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["makeai"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		var/move = TRUE
		switch(tgui_alert(usr,"Move new AI to AI spawn location?","Move AI?", list("Yes", "No","Cancel")))
			if("Cancel")
				return
			if("No")
				move = FALSE
		if(QDELETED(H))
			to_chat(usr, span_danger("Subject was deleted already. Transform canceled."))
			return
		message_admins(span_danger("Admin [key_name_admin(usr)] AIized [key_name_admin(H)]!"))
		log_admin("[key_name(usr)] AIized [key_name(H)].")
		H.AIize(TRUE, H.client, move)

	else if(href_list["makealien"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["makealien"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		usr.client.cmd_admin_alienize(H)

	else if(href_list["makeslime"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["makeslime"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		usr.client.cmd_admin_slimeize(H)

	else if(href_list["makeblob"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["makeblob"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		usr.client.cmd_admin_blobize(H)


	else if(href_list["makerobot"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/living/carbon/human/H = locate(href_list["makerobot"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return

		usr.client.cmd_admin_robotize(H)

	else if(href_list["makeanimal"])
		if(!check_rights(R_SPAWN))
			return

		var/mob/M = locate(href_list["makeanimal"])
		if(isnewplayer(M))
			to_chat(usr, "This cannot be used on instances of type /mob/dead/new_player.")
			return

		usr.client.cmd_admin_animalize(M)

	else if(href_list["adminplayeropts"])
		var/mob/M = locate(href_list["adminplayeropts"])
		show_player_panel(M)

	else if(href_list["adminplayerobservefollow"])
		if(!isobserver(usr) && !check_rights(R_ADMIN))
			return

		var/atom/movable/AM = locate(href_list["adminplayerobservefollow"])

		var/client/C = usr.client
		var/can_ghost = TRUE
		if(!isobserver(usr))
			can_ghost = C.admin_ghost()

		if(!can_ghost)
			return
		var/mob/dead/observer/A = C.mob
		A.ManualFollow(AM)

	else if(href_list["admingetmovable"])
		if(!check_rights(R_ADMIN))
			return

		var/atom/movable/AM = locate(href_list["admingetmovable"])
		if(QDELETED(AM))
			return
		AM.forceMove(get_turf(usr))

	else if(href_list["adminplayerobservecoodjump"])
		if(!isobserver(usr) && !check_rights(R_ADMIN))
			return

		var/x = text2num(href_list["X"])
		var/y = text2num(href_list["Y"])
		var/z = text2num(href_list["Z"])

		var/client/C = usr.client
		if(!isobserver(usr))
			C.admin_ghost()
		sleep(2)
		C.jumptocoord(x,y,z)

	else if(href_list["adminchecklaws"])
		if(!check_rights(R_ADMIN))
			return
		output_ai_laws()

	else if(href_list["admincheckdevilinfo"])
		if(!check_rights(R_ADMIN))
			return
		var/mob/M = locate(href_list["admincheckdevilinfo"])
		output_devil_info(M)


	else if(href_list["adminmoreinfo"])
		var/mob/M = locate(href_list["adminmoreinfo"]) in GLOB.mob_list
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return

		var/location_description = ""
		var/special_role_description = ""
		var/health_description = ""
		var/gender_description = ""
		var/turf/T = get_turf(M)

		//Location
		if(isturf(T))
			if(isarea(T.loc))
				location_description = "([M.loc == T ? "at coordinates " : "in [M.loc] at coordinates "] [T.x], [T.y], [T.z] in area <b>[T.loc]</b>)"
			else
				location_description = "([M.loc == T ? "at coordinates " : "in [M.loc] at coordinates "] [T.x], [T.y], [T.z])"

		//Job + antagonist
		if(M.mind)
			special_role_description = "Role: <b>[M.mind.assigned_role]</b>; Antagonist: <font color='red'><b>"
			var/i = 0
			for(var/datum/antagonist/A in M.mind.antag_datums)
				special_role_description += "[A.name]"
				if(++i != length(M.mind.antag_datums))
					special_role_description += ", "
			special_role_description += "</b></font>"
		else
			special_role_description = "Role: <i>Mind datum missing</i> Antagonist: <i>Mind datum missing</i>"

		//Health
		if(isliving(M))
			var/mob/living/L = M
			var/status
			switch (M.stat)
				if(CONSCIOUS)
					status = "Alive"
				if(SOFT_CRIT)
					status = "<font color='orange'><b>Dying</b></font>"
				if(UNCONSCIOUS)
					status = "<font color='orange'><b>Unconscious</b></font>"
				if(HARD_CRIT)
					status = "<font color='orange'><b>Unconscious and Dying</b></font>"
				if(DEAD)
					status = span_red("<b>Dead</b>")
			health_description = "Status = [status]"
			health_description += "<BR>Oxy: [L.getOxyLoss()] - Tox: [L.getToxLoss()] - Fire: [L.getFireLoss()] - Brute: [L.getBruteLoss()] - Clone: [L.getCloneLoss()] - Brain: [L.getOrganLoss(ORGAN_SLOT_BRAIN)] - Stamina: [L.getStaminaLoss()]"
		else
			health_description = "This mob type has no health to speak of."

		//Gender
		switch(M.gender)
			if(MALE,FEMALE,PLURAL)
				gender_description = "[M.gender]"
			else
				gender_description = span_red("<b>[M.gender]</b>")

		to_chat(src.owner, "<b>Info about [M.name]:</b> ")
		to_chat(src.owner, "Mob type = [M.type]; Gender = [gender_description] Damage = [health_description]")
		to_chat(src.owner, "Name = <b>[M.name]</b>; Real_name = [M.real_name]; Mind_name = [M.mind?"[M.mind.name]":""]; Key = <b>[M.key]</b>;")
		to_chat(src.owner, "Location = [location_description];")
		to_chat(src.owner, "[special_role_description]")
		to_chat(src.owner, ADMIN_FULLMONTY_NONAME(M))

	else if(href_list["addjobslot"])
		if(!check_rights(R_ADMIN))
			return

		var/Add = href_list["addjobslot"]

		for(var/datum/job/job in SSjob.occupations)
			if(job.title == Add)
				job.total_positions += 1
				break

		src.manage_free_slots()


	else if(href_list["customjobslot"])
		if(!check_rights(R_ADMIN))
			return

		var/Add = href_list["customjobslot"]

		for(var/datum/job/job in SSjob.occupations)
			if(job.title == Add)
				var/newtime = null
				newtime = input(usr, "How many jebs do you want?", "Add wanted posters", "[newtime]") as num|null
				if(!newtime)
					to_chat(src.owner, "Setting to amount of positions filled for the job")
					job.total_positions = job.current_positions
					break
				job.total_positions = newtime

		src.manage_free_slots()

	else if(href_list["removejobslot"])
		if(!check_rights(R_ADMIN))
			return

		var/Remove = href_list["removejobslot"]

		for(var/datum/job/job in SSjob.occupations)
			if(job.title == Remove && job.total_positions - job.current_positions > 0)
				job.total_positions -= 1
				break

		src.manage_free_slots()

	else if(href_list["unlimitjobslot"])
		if(!check_rights(R_ADMIN))
			return

		var/Unlimit = href_list["unlimitjobslot"]

		for(var/datum/job/job in SSjob.occupations)
			if(job.title == Unlimit)
				job.total_positions = -1
				break

		src.manage_free_slots()

	else if(href_list["limitjobslot"])
		if(!check_rights(R_ADMIN))
			return

		var/Limit = href_list["limitjobslot"]

		for(var/datum/job/job in SSjob.occupations)
			if(job.title == Limit)
				job.total_positions = job.current_positions
				break

		src.manage_free_slots()


	else if(href_list["adminspawncookie"])
		if(!check_rights(R_ADMIN|R_FUN))
			return

		var/mob/living/carbon/human/H = locate(href_list["adminspawncookie"])
		if(!ishuman(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human.")
			return
		//let's keep it simple
		//milk to plasmemes and skeletons, meat to lizards, electricity bars to ethereals, cookies to everyone else
		var/cookiealt = /obj/item/food/cookie
		if(isskeleton(H))
			cookiealt = /obj/item/reagent_containers/food/condiment/milk
		else if(isplasmaman(H))
			cookiealt = /obj/item/reagent_containers/food/condiment/milk
		else if(isethereal(H))
			cookiealt = /obj/item/food/energybar
		else if(islizard(H))
			cookiealt = /obj/item/food/meat/slab
		var/obj/item/new_item = new cookiealt(H)
		if(H.put_in_hands(new_item))
			H.update_inv_hands()
		else
			qdel(new_item)
			log_admin("[key_name(H)] has their hands full, so they did not receive their [new_item.name], spawned by [key_name(src.owner)].")
			message_admins("[key_name(H)] has their hands full, so they did not receive their [new_item.name], spawned by [key_name(src.owner)].")
			return

		log_admin("[key_name(H)] got their [new_item], spawned by [key_name(src.owner)].")
		message_admins("[key_name(H)] got their [new_item], spawned by [key_name(src.owner)].")
		SSblackbox.record_feedback("amount", "admin_cookies_spawned", 1)
		to_chat(H, span_adminnotice("Your prayers have been answered!! You received the <b>best [new_item.name]!</b>"))
		SEND_SOUND(H, sound('sound/effects/pray_chaplain.ogg'))

	else if(href_list["adminsmite"])
		if(!check_rights(R_ADMIN|R_FUN))
			return

		var/mob/living/carbon/human/H = locate(href_list["adminsmite"]) in GLOB.mob_list
		if(!H || !istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human")
			return

		usr.client.smite(H)

	else if(href_list["CentComReply"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["CentComReply"])
		usr.client.admin_headset_message(M, RADIO_CHANNEL_CENTCOM)

	else if(href_list["SyndicateReply"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["SyndicateReply"])
		usr.client.admin_headset_message(M, RADIO_CHANNEL_SYNDICATE)

	else if(href_list["HeadsetMessage"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["HeadsetMessage"])
		usr.client.admin_headset_message(M)

	else if(href_list["reject_custom_name"])
		if(!check_rights(R_ADMIN))
			return
		var/obj/item/station_charter/charter = locate(href_list["reject_custom_name"])
		if(istype(charter))
			charter.reject_proposed(usr)
	else if(href_list["jumpto"])
		if(!isobserver(usr) && !check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["jumpto"])
		usr.client.jumptomob(M)

	else if(href_list["getmob"])
		if(!check_rights(R_ADMIN))
			return

		if(tgui_alert(usr, "Confirm?", "Message", list("Yes", "No")) != "Yes")
			return
		var/mob/M = locate(href_list["getmob"])
		usr.client.Getmob(M)

	else if(href_list["sendmob"])
		if(!check_rights(R_FUN))
			return

		var/mob/M = locate(href_list["sendmob"])
		usr.client.sendmob(M)

	else if(href_list["narrateto"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["narrateto"])
		usr.client.cmd_admin_direct_narrate(M)

	else if(href_list["subtlemessage"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["subtlemessage"])
		usr.client.cmd_admin_subtle_message(M)

	else if(href_list["playsoundto"])
		if(!check_rights(R_SOUND))
			return

		var/mob/M = locate(href_list["playsoundto"])
		var/S = input("", "Select a sound file",) as null|sound
		if(S)
			usr.client.play_direct_mob_sound(S, M)

	else if(href_list["individuallog"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["individuallog"]) in GLOB.mob_list
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return

		show_individual_logging_panel(M, href_list["log_src"], href_list["log_type"])
	else if(href_list["languagemenu"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["languagemenu"]) in GLOB.mob_list
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return
		var/datum/language_holder/H = M.get_language_holder()
		H.open_language_menu(usr)

	else if(href_list["traitor"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.HasRoundStarted())
			tgui_alert(usr,"The game hasn't started yet!")
			return

		var/mob/M = locate(href_list["traitor"])
		if(!ismob(M))
			var/datum/mind/D = M
			if(!istype(D))
				to_chat(usr, "This can only be used on instances of type /mob and /mind")
				return
			else
				D.traitor_panel()
		else
			show_traitor_panel(M)

	else if(href_list["skill"])
		if(!check_rights(R_ADMIN))
			return

		if(!SSticker.HasRoundStarted())
			tgui_alert(usr,"The game hasn't started yet!")
			return

		var/target = locate(href_list["skill"])
		var/datum/mind/target_mind
		if(ismob(target))
			var/mob/target_mob = target
			target_mind = target_mob.mind
		else if (istype(target, /datum/mind))
			target_mind = target
		else
			to_chat(usr, "This can only be used on instances of type /mob and /mind")
			return
		show_skill_panel(target_mind)

	else if(href_list["borgpanel"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["borgpanel"])
		if(!iscyborg(M))
			to_chat(usr, "This can only be used on cyborgs")
		else
			open_borgopanel(M)

	else if(href_list["initmind"])
		if(!check_rights(R_ADMIN))
			return
		var/mob/M = locate(href_list["initmind"])
		if(!ismob(M) || M.mind)
			to_chat(usr, "This can only be used on instances on mindless mobs")
			return
		M.mind_initialize()

	else if(href_list["create_object"])
		if(!check_rights(R_SPAWN))
			return
		return create_object(usr)

	else if(href_list["quick_create_object"])
		if(!check_rights(R_SPAWN))
			return
		return quick_create_object(usr)

	else if(href_list["create_turf"])
		if(!check_rights(R_SPAWN))
			return
		return create_turf(usr)

	else if(href_list["create_mob"])
		if(!check_rights(R_SPAWN))
			return
		return create_mob(usr)

	else if(href_list["dupe_marked_datum"])
		if(!check_rights(R_SPAWN))
			return
		return DuplicateObject(marked_datum, perfectcopy=1, newloc=get_turf(usr))

	else if(href_list["object_list"])			//this is the laggiest thing ever
		if(!check_rights(R_SPAWN))
			return

		var/atom/loc = usr.loc

		var/dirty_paths
		if (istext(href_list["object_list"]))
			dirty_paths = list(href_list["object_list"])
		else if (istype(href_list["object_list"], /list))
			dirty_paths = href_list["object_list"]

		var/paths = list()

		for(var/dirty_path in dirty_paths)
			var/path = text2path(dirty_path)
			if(!path)
				continue
			else if(!ispath(path, /obj) && !ispath(path, /turf) && !ispath(path, /mob))
				continue
			paths += path

		if(!paths)
			tgui_alert(usr,"The path list you sent is empty.")
			return
		if(length(paths) > 5)
			tgui_alert(usr,"Select fewer object types, (max 5).")
			return

		var/list/offset = splittext(href_list["offset"],",")
		var/number = clamp(text2num(href_list["object_count"]), 1, ADMIN_SPAWN_CAP)
		var/X = offset.len > 0 ? text2num(offset[1]) : 0
		var/Y = offset.len > 1 ? text2num(offset[2]) : 0
		var/Z = offset.len > 2 ? text2num(offset[3]) : 0
		var/obj_dir = text2num(href_list["object_dir"])
		if(obj_dir && !(obj_dir in list(1,2,4,8,5,6,9,10)))
			obj_dir = null
		var/obj_name = sanitize(href_list["object_name"])


		var/atom/target //Where the object will be spawned
		var/where = href_list["object_where"]
		if (!( where in list("onfloor","frompod","inhand","inmarked")))
			where = "onfloor"


		switch(where)
			if("inhand")
				if (!iscarbon(usr) && !iscyborg(usr))
					to_chat(usr, "Can only spawn in hand when you're a carbon mob or cyborg.")
					where = "onfloor"
				target = usr

			if("onfloor", "frompod")
				switch(href_list["offset_type"])
					if ("absolute")
						target = locate(0 + X,0 + Y,0 + Z)
					if ("relative")
						target = locate(loc.x + X,loc.y + Y,loc.z + Z)
			if("inmarked")
				if(!marked_datum)
					to_chat(usr, "You don't have any object marked. Abandoning spawn.")
					return
				else if(!istype(marked_datum, /atom))
					to_chat(usr, "The object you have marked cannot be used as a target. Target must be of type /atom. Abandoning spawn.")
					return
				else
					target = marked_datum

		var/obj/structure/closet/supplypod/centcompod/pod

		if(target)
			if(where == "frompod")
				pod = new()

			for (var/path in paths)
				for (var/i = 0; i < number; i++)
					if(path in typesof(/turf))
						var/turf/O = target
						var/turf/N = O.ChangeTurf(path)
						if(N && obj_name)
							N.name = obj_name
					else
						var/atom/O
						if(where == "frompod")
							O = new path(pod)
						else
							O = new path(target)

						if(!QDELETED(O))
							O.flags_1 |= ADMIN_SPAWNED_1
							if(obj_dir)
								O.setDir(obj_dir)
							if(obj_name)
								O.name = obj_name
								if(ismob(O))
									var/mob/M = O
									M.real_name = obj_name
							if(where == "inhand" && isliving(usr) && isitem(O))
								var/mob/living/L = usr
								var/obj/item/I = O
								L.put_in_hands(I)
								if(iscyborg(L))
									var/mob/living/silicon/robot/R = L
									if(R.module)
										R.module.add_module(I, TRUE, TRUE)
										R.activate_module(I)

		if(pod)
			new /obj/effect/pod_landingzone(target, pod)

		if (number == 1)
			log_admin("[key_name(usr)] created a [english_list(paths)]")
			for(var/path in paths)
				if(ispath(path, /mob))
					message_admins("[key_name_admin(usr)] created a [english_list(paths)]")
					break
		else
			log_admin("[key_name(usr)] created [number]ea [english_list(paths)]")
			for(var/path in paths)
				if(ispath(path, /mob))
					message_admins("[key_name_admin(usr)] created [number]ea [english_list(paths)]")
					break
		return

	else if(href_list["ac_view_wanted"])            //Admin newscaster Topic() stuff be here
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen = 18                 //The ac_ prefix before the hrefs stands for AdminCaster.
		src.access_news_network()

	else if(href_list["ac_set_channel_name"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_feed_channel.channel_name = stripped_input(usr, "Provide a Feed Channel Name.", "Network Channel Handler", "")
		src.access_news_network()

	else if(href_list["ac_set_channel_lock"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_feed_channel.locked = !src.admincaster_feed_channel.locked
		src.access_news_network()

	else if(href_list["ac_submit_new_channel"])
		if(!check_rights(R_ADMIN))
			return
		var/check = 0
		for(var/datum/newscaster/feed_channel/FC in GLOB.news_network.network_channels)
			if(FC.channel_name == src.admincaster_feed_channel.channel_name)
				check = 1
				break
		if(src.admincaster_feed_channel.channel_name == "" || src.admincaster_feed_channel.channel_name == "\[REDACTED\]" || check )
			src.admincaster_screen=7
		else
			var/choice = tgui_alert(usr,"Please confirm Feed channel creation.","Network Channel Handler",list("Confirm","Cancel"))
			if(choice=="Confirm")
				GLOB.news_network.CreateFeedChannel(src.admincaster_feed_channel.channel_name, src.admin_signature, src.admincaster_feed_channel.locked, 1)
				SSblackbox.record_feedback("tally", "newscaster_channels", 1, src.admincaster_feed_channel.channel_name)
				log_admin("[key_name(usr)] created command feed channel: [src.admincaster_feed_channel.channel_name]!")
				src.admincaster_screen=5
		src.access_news_network()

	else if(href_list["ac_set_channel_receiving"])
		if(!check_rights(R_ADMIN))
			return
		var/list/available_channels = list()
		for(var/datum/newscaster/feed_channel/F in GLOB.news_network.network_channels)
			available_channels += F.channel_name
		src.admincaster_feed_channel.channel_name = adminscrub(input(usr, "Choose receiving Feed Channel.", "Network Channel Handler") in sort_list(available_channels) )
		src.access_news_network()

	else if(href_list["ac_set_new_message"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_feed_message.body = adminscrub(stripped_input(usr, "Write your Feed story.", "Network Channel Handler", ""))
		src.access_news_network()

	else if(href_list["ac_submit_new_message"])
		if(!check_rights(R_ADMIN))
			return
		if(src.admincaster_feed_message.returnBody(-1) =="" || src.admincaster_feed_message.returnBody(-1) =="\[REDACTED\]" || src.admincaster_feed_channel.channel_name == "" )
			src.admincaster_screen = 6
		else
			GLOB.news_network.SubmitArticle(src.admincaster_feed_message.returnBody(-1), src.admin_signature, src.admincaster_feed_channel.channel_name, null, 1)
			SSblackbox.record_feedback("amount", "newscaster_stories", 1)
			src.admincaster_screen=4

		for(var/obj/machinery/newscaster/NEWSCASTER in GLOB.allCasters)
			NEWSCASTER.newsAlert(src.admincaster_feed_channel.channel_name)

		log_admin("[key_name(usr)] submitted a feed story to channel: [src.admincaster_feed_channel.channel_name]!")
		src.access_news_network()

	else if(href_list["ac_create_channel"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen=2
		src.access_news_network()

	else if(href_list["ac_create_feed_story"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen=3
		src.access_news_network()

	else if(href_list["ac_menu_censor_story"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen=10
		src.access_news_network()

	else if(href_list["ac_menu_censor_channel"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen=11
		src.access_news_network()

	else if(href_list["ac_menu_wanted"])
		if(!check_rights(R_ADMIN))
			return
		var/already_wanted = 0
		if(GLOB.news_network.wanted_issue.active)
			already_wanted = 1

		if(already_wanted)
			src.admincaster_wanted_message.criminal  = GLOB.news_network.wanted_issue.criminal
			src.admincaster_wanted_message.body = GLOB.news_network.wanted_issue.body
		src.admincaster_screen = 14
		src.access_news_network()

	else if(href_list["ac_set_wanted_name"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_wanted_message.criminal = adminscrub(stripped_input(usr, "Provide the name of the Wanted person.", "Network Security Handler", ""))
		src.access_news_network()

	else if(href_list["ac_set_wanted_desc"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_wanted_message.body = adminscrub(stripped_input(usr, "Provide the a description of the Wanted person and any other details you deem important.", "Network Security Handler", ""))
		src.access_news_network()

	else if(href_list["ac_submit_wanted"])
		if(!check_rights(R_ADMIN))
			return
		var/input_param = text2num(href_list["ac_submit_wanted"])
		if(src.admincaster_wanted_message.criminal == "" || src.admincaster_wanted_message.body == "")
			src.admincaster_screen = 16
		else
			var/choice = tgui_alert(usr,"Please confirm Wanted Issue [(input_param==1) ? ("creation.") : ("edit.")]","Network Security Handler",list("Confirm","Cancel"))
			if(choice=="Confirm")
				if(input_param==1)          //If input_param == 1 we're submitting a new wanted issue. At 2 we're just editing an existing one. See the else below
					GLOB.news_network.submitWanted(admincaster_wanted_message.criminal, admincaster_wanted_message.body, admin_signature, null, 1, 1)
					src.admincaster_screen = 15
				else
					GLOB.news_network.submitWanted(admincaster_wanted_message.criminal, admincaster_wanted_message.body, admin_signature)
					src.admincaster_screen = 19
				log_admin("[key_name(usr)] issued a Station-wide Wanted Notification for [src.admincaster_wanted_message.criminal]!")
		src.access_news_network()

	else if(href_list["ac_cancel_wanted"])
		if(!check_rights(R_ADMIN))
			return
		var/choice = tgui_alert(usr,"Please confirm Wanted Issue removal.","Network Security Handler",list("Confirm","Cancel"))
		if(choice=="Confirm")
			GLOB.news_network.deleteWanted()
			src.admincaster_screen=17
		src.access_news_network()

	else if(href_list["ac_censor_channel_author"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_channel/FC = locate(href_list["ac_censor_channel_author"])
		FC.toggleCensorAuthor()
		src.access_news_network()

	else if(href_list["ac_censor_channel_story_author"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_message/MSG = locate(href_list["ac_censor_channel_story_author"])
		MSG.toggleCensorAuthor()
		src.access_news_network()

	else if(href_list["ac_censor_channel_story_body"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_message/MSG = locate(href_list["ac_censor_channel_story_body"])
		MSG.toggleCensorBody()
		src.access_news_network()

	else if(href_list["ac_pick_d_notice"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_channel/FC = locate(href_list["ac_pick_d_notice"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen=13
		src.access_news_network()

	else if(href_list["ac_toggle_d_notice"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_channel/FC = locate(href_list["ac_toggle_d_notice"])
		FC.toggleCensorDclass()
		src.access_news_network()

	else if(href_list["ac_view"])
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen=1
		src.access_news_network()

	else if(href_list["ac_setScreen"]) //Brings us to the main menu and resets all fields~
		if(!check_rights(R_ADMIN))
			return
		src.admincaster_screen = text2num(href_list["ac_setScreen"])
		if (src.admincaster_screen == 0)
			if(src.admincaster_feed_channel)
				src.admincaster_feed_channel = new /datum/newscaster/feed_channel
			if(src.admincaster_feed_message)
				src.admincaster_feed_message = new /datum/newscaster/feed_message
			if(admincaster_wanted_message)
				admincaster_wanted_message = new /datum/newscaster/wanted_message
		src.access_news_network()

	else if(href_list["ac_show_channel"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_channel/FC = locate(href_list["ac_show_channel"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen = 9
		src.access_news_network()

	else if(href_list["ac_pick_censor_channel"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_channel/FC = locate(href_list["ac_pick_censor_channel"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen = 12
		src.access_news_network()

	else if(href_list["ac_refresh"])
		if(!check_rights(R_ADMIN))
			return
		src.access_news_network()

	else if(href_list["ac_set_signature"])
		if(!check_rights(R_ADMIN))
			return
		src.admin_signature = adminscrub(input(usr, "Provide your desired signature.", "Network Identity Handler", ""))
		src.access_news_network()

	else if(href_list["ac_del_comment"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_comment/FC = locate(href_list["ac_del_comment"])
		var/datum/newscaster/feed_message/FM = locate(href_list["ac_del_comment_msg"])
		FM.comments -= FC
		qdel(FC)
		src.access_news_network()

	else if(href_list["ac_lock_comment"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/newscaster/feed_message/FM = locate(href_list["ac_lock_comment"])
		FM.locked ^= 1
		src.access_news_network()

	else if(href_list["check_antagonist"])
		if(!check_rights(R_ADMIN))
			return
		usr.client.check_antagonists()

	else if(href_list["kick_all_from_lobby"])
		if(!check_rights(R_ADMIN))
			return
		if(SSticker.IsRoundInProgress())
			var/afkonly = text2num(href_list["afkonly"])
			if(tgui_alert(usr,"Are you sure you want to kick all [afkonly ? "AFK" : ""] clients from the lobby??","Message",list("Yes","Cancel")) != "Yes")
				to_chat(usr, "Kick clients from lobby aborted")
				return
			var/list/listkicked = kick_clients_in_lobby(span_danger("You were kicked from the lobby by [usr.client.holder.fakekey ? "an Administrator" : "[usr.client.key]"].") , afkonly)

			var/strkicked = ""
			for(var/name in listkicked)
				strkicked += "[name], "
			message_admins("[key_name_admin(usr)] has kicked [afkonly ? "all AFK" : "all"] clients from the lobby. [length(listkicked)] clients kicked: [strkicked ? strkicked : "--"]")
			log_admin("[key_name(usr)] has kicked [afkonly ? "all AFK" : "all"] clients from the lobby. [length(listkicked)] clients kicked: [strkicked ? strkicked : "--"]")
		else
			to_chat(usr, "You may only use this when the game is running.")

	else if(href_list["create_outfit_finalize"])
		if(!check_rights(R_ADMIN))
			return
		create_outfit_finalize(usr,href_list)
	else if(href_list["load_outfit"])
		if(!check_rights(R_ADMIN))
			return
		load_outfit(usr)
	else if(href_list["create_outfit_menu"])
		if(!check_rights(R_ADMIN))
			return
		create_outfit(usr)
	else if(href_list["delete_outfit"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/outfit/O = locate(href_list["chosen_outfit"]) in GLOB.custom_outfits
		delete_outfit(usr,O)
	else if(href_list["save_outfit"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/outfit/O = locate(href_list["chosen_outfit"]) in GLOB.custom_outfits
		save_outfit(usr,O)
	else if(href_list["set_selfdestruct_code"])
		if(!check_rights(R_ADMIN))
			return
		var/code = random_nukecode()
		for(var/obj/machinery/nuclearbomb/selfdestruct/SD in GLOB.nuke_list)
			SD.r_code = code
		message_admins("[key_name_admin(usr)] has set the self-destruct \
			code to \"[code]\".")

	else if(href_list["add_station_goal"])
		if(!check_rights(R_ADMIN))
			return
		var/list/type_choices = typesof(/datum/station_goal)
		var/picked = tgui_input_list(usr, "Choose goal type",, type_choices)
		if(!picked)
			return
		var/datum/station_goal/G = new picked()
		if(picked == /datum/station_goal)
			var/newname = input("Enter goal name:") as text|null
			if(!newname)
				return
			G.name = newname
			var/description = input("Enter CentCom message contents:") as message|null
			if(!description)
				return
			G.report_message = description
		message_admins("[key_name(usr)] created \"[G.name]\" station goal.")
		SSticker.mode.station_goals += G
		modify_goals()

	else if(href_list["change_lag_switch"])
		if(!check_rights(R_ADMIN))
			return

		switch(href_list["change_lag_switch"])
			if("ALL_ON")
				SSlag_switch.set_all_measures(TRUE)
				log_admin("[key_name(usr)] turned all Lag Switch measures ON.")
				message_admins("[key_name_admin(usr)] turned all Lag Switch measures ON.")
			if("ALL_OFF")
				SSlag_switch.set_all_measures(FALSE)
				log_admin("[key_name(usr)] turned all Lag Switch measures OFF.")
				message_admins("[key_name_admin(usr)] turned all Lag Switch measures OFF.")
			else
				var/switch_index = text2num(href_list["change_lag_switch"])
				if(!SSlag_switch.set_measure(switch_index, !LAZYACCESS(SSlag_switch.measures, switch_index)))
					to_chat(src, span_danger("Something went wrong when trying to toggle that Lag Switch. Check runtimes for more info."))
				else
					log_admin("[key_name(usr)] turned a Lag Switch measure at index ([switch_index]) [LAZYACCESS(SSlag_switch.measures, switch_index) ? "ON" : "OFF"]")
					message_admins("[key_name_admin(usr)] turned a Lag Switch measure [LAZYACCESS(SSlag_switch.measures, switch_index) ? "ON" : "OFF"]")

		src.show_lag_switch_panel()

	else if(href_list["change_lag_switch_option"])
		if(!check_rights(R_ADMIN))
			return

		switch(href_list["change_lag_switch_option"])
			if("CANCEL")
				if(SSlag_switch.cancel_auto_enable_in_progress())
					log_admin("[key_name(usr)] canceled the automatic Lag Switch activation in progress.")
					message_admins("[key_name_admin(usr)] canceled the automatic Lag Switch activation in progress.")
				return // return here to avoid (re)rendering the panel for this case
			if("TOGGLE_AUTO")
				SSlag_switch.toggle_auto_enable()
				log_admin("[key_name(usr)] toggled automatic Lag Switch activation [SSlag_switch.auto_switch ? "ON" : "OFF"].")
				message_admins("[key_name_admin(usr)] toggled automatic Lag Switch activation [SSlag_switch.auto_switch ? "ON" : "OFF"].")
			if("NUM")
				var/new_num = input("Enter new threshold value:", "Num") as null|num
				if(!isnull(new_num))
					SSlag_switch.trigger_pop = new_num
					log_admin("[key_name(usr)] set the Lag Switch automatic trigger pop to [new_num].")
					message_admins("[key_name_admin(usr)] set the Lag Switch automatic trigger pop to [new_num].")
			if("SLOWCOOL")
				var/new_num = input("Enter new cooldown in seconds:", "Num") as null|num
				if(!isnull(new_num))
					SSlag_switch.change_slowmode_cooldown(new_num)
					log_admin("[key_name(usr)] set the Lag Switch slowmode cooldown to [new_num] seconds.")
					message_admins("[key_name_admin(usr)] set the Lag Switch slowmode cooldown to [new_num] seconds.")

		src.show_lag_switch_panel()

	else if(href_list["viewruntime"])
		var/datum/error_viewer/error_viewer = locate(href_list["viewruntime"])
		if(!istype(error_viewer))
			to_chat(usr, span_warning("That runtime viewer no longer exists."))
			return

		if(href_list["viewruntime_backto"])
			error_viewer.show_to(owner, locate(href_list["viewruntime_backto"]), href_list["viewruntime_linear"])
		else
			error_viewer.show_to(owner, null, href_list["viewruntime_linear"])

	else if(href_list["showrelatedacc"])
		if(!check_rights(R_ADMIN))
			return
		var/client/C = locate(href_list["client"]) in GLOB.clients
		var/thing_to_check
		if(href_list["showrelatedacc"] == "cid")
			thing_to_check = C.related_accounts_cid
		else
			thing_to_check = C.related_accounts_ip
		thing_to_check = splittext(thing_to_check, ", ")


		var/list/dat = list("Related accounts by [uppertext(href_list["showrelatedacc"])]:")
		dat += thing_to_check

		usr << browse(dat.Join("<br>"), "window=related_[C];size=420x300")

	else if(href_list["centcomlookup"])
		if(!check_rights(R_ADMIN))
			return

		if(!CONFIG_GET(string/centcom_ban_db))
			to_chat(usr, span_warning("Centcom Galactic Ban DB is disabled!"))
			return

		var/ckey = href_list["centcomlookup"]

		// Make the request
		var/datum/http_request/request = new()
		request.prepare(RUSTG_HTTP_METHOD_GET, "[CONFIG_GET(string/centcom_ban_db)]/[ckey]", "", "", null)
		request.begin_async()
		UNTIL(request.is_complete() || !usr)
		if (!usr)
			return
		var/datum/http_response/response = request.into_response()

		var/list/bans

		var/list/dat = list("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><body>")

		if(response.errored)
			dat += "<br>Failed to connect to CentCom."
		else if(response.status_code != 200)
			dat += "<br>Failed to connect to CentCom. Status code: [response.status_code]"
		else
			if(response.body == "[]")
				dat += "<center><b>0 bans detected for [ckey]</b></center>"
			else
				bans = json_decode(response["body"])

				//Ignore bans from non-whitelisted sources, if a whitelist exists
				var/list/valid_sources
				if(CONFIG_GET(string/centcom_source_whitelist))
					valid_sources = splittext(CONFIG_GET(string/centcom_source_whitelist), ",")
					dat += "<center><b>Bans detected for [ckey]</b></center>"
				else
					//Ban count is potentially inaccurate if they're using a whitelist
					dat += "<center><b>[bans.len] ban\s detected for [ckey]</b></center>"

				for(var/list/ban in bans)
					if(valid_sources && !(ban["sourceName"] in valid_sources))
						continue
					dat += "<b>Server: </b> [sanitize(ban["sourceName"])]<br>"
					dat += "<b>RP Level: </b> [sanitize(ban["sourceRoleplayLevel"])]<br>"
					dat += "<b>Type: </b> [sanitize(ban["type"])]<br>"
					dat += "<b>Banned By: </b> [sanitize(ban["bannedBy"])]<br>"
					dat += "<b>Reason: </b> [sanitize(ban["reason"])]<br>"
					dat += "<b>Datetime: </b> [sanitize(ban["bannedOn"])]<br>"
					var/expiration = ban["expires"]
					dat += "<b>Expires: </b> [expiration ? "[sanitize(expiration)]" : "Permanent"]<br>"
					if(ban["type"] == "job")
						dat += "<b>Jobs: </b> "
						var/list/jobs = ban["jobs"]
						dat += sanitize(jobs.Join(", "))
						dat += "<br>"
					dat += "<hr>"

		dat += "<br></body>"
		var/datum/browser/popup = new(usr, "centcomlookup-[ckey]", "<div align='center'>Central Command Galactic Ban Database</div>", 700, 600)
		popup.set_content(dat.Join())
		popup.open(0)

	else if(href_list["modantagrep"])
		if(!check_rights(R_ADMIN))
			return

		var/mob/M = locate(href_list["mob"]) in GLOB.mob_list
		var/client/C = M.client
		usr.client.cmd_admin_mod_antag_rep(C, href_list["modantagrep"])
		show_player_panel(M)

	else if(href_list["pushmetocrawler"])
		if(!check_rights(R_ADMIN))
			return

		var/client/C = locate(href_list["pushmetocrawler"]) in GLOB.clients

		usr << link("https://crawler.station13.ru/?ckey=[C.ckey]")

	else if(href_list["changemetacash"])
		if(!check_rights(R_SECURED))
			return

		var/amount = input(usr, "Че ставим?") as null|num

		if (amount)
			var/mob/M = locate(href_list["changemetacash"]) in GLOB.mob_list
			var/client/C = M.client
			C.set_metacoin_count(amount)
			message_admins("[key_name(usr)] изменяет баланс метакэша [key_name(C)] на [amount].")

	else if(href_list["slowquery"])
		if(!check_rights(R_ADMIN))
			return
		var/answer = href_list["slowquery"]
		if(answer == "yes")
			log_query_debug("[usr.key] | Reported a server hang")
			if(tgui_alert(usr, "Had you just press any admin buttons?", "Query server hang report", list("Yes", "No")) == "Yes")
				var/response = input(usr,"What were you just doing?","Query server hang report") as null|text
				if(response)
					log_query_debug("[usr.key] | [response]")
		else if(answer == "no")
			log_query_debug("[usr.key] | Reported no server hang")

	else if(href_list["ctf_toggle"])
		if(!check_rights(R_ADMIN))
			return
		toggle_id_ctf(usr, "centcom")

	else if(href_list["rebootworld"])
		if(!check_rights(R_ADMIN))
			return
		var/confirm = tgui_alert(usr,"Are you sure you want to reboot the server?", "Confirm Reboot", list("Yes", "No"))
		if(confirm == "No")
			return
		if(confirm == "Yes")
			restart()

	else if(href_list["check_teams"])
		if(!check_rights(R_ADMIN))
			return
		check_teams()

	else if(href_list["team_command"])
		if(!check_rights(R_ADMIN))
			return
		switch(href_list["team_command"])
			if("create_team")
				admin_create_team(usr)
			if("rename_team")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(T)
					T.admin_rename(usr)
			if("communicate")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(T)
					T.admin_communicate(usr)
			if("delete_team")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(T)
					T.admin_delete(usr)
			if("add_objective")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(T)
					T.admin_add_objective(usr)
			if("remove_objective")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(!T)
					return
				var/datum/objective/O = locate(href_list["tobjective"]) in T.objectives
				if(O)
					T.admin_remove_objective(usr,O)
			if("add_member")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(T)
					T.admin_add_member(usr)
			if("remove_member")
				var/datum/team/T = locate(href_list["team"]) in GLOB.antagonist_teams
				if(!T)
					return
				var/datum/mind/M = locate(href_list["tmember"]) in T.members
				if(M)
					T.admin_remove_member(usr,M)
		check_teams()

	else if(href_list["newbankey"])
		var/player_key = href_list["newbankey"]
		var/player_ip = href_list["newbanip"]
		var/player_cid = href_list["newbancid"]
		ban_panel(player_key, player_ip, player_cid)

	else if(href_list["intervaltype"]) //check for ban panel, intervaltype is used as it's the only value which will always be present
		if(href_list["roleban_delimiter"])
			ban_parse_href(href_list)
		else
			ban_parse_href(href_list, TRUE)

	else if(href_list["searchunbankey"] || href_list["searchunbanadminkey"] || href_list["searchunbanip"] || href_list["searchunbancid"])
		var/player_key = href_list["searchunbankey"]
		var/admin_key = href_list["searchunbanadminkey"]
		var/player_ip = href_list["searchunbanip"]
		var/player_cid = href_list["searchunbancid"]
		unban_panel(player_key, admin_key, player_ip, player_cid)

	else if(href_list["unbanpagecount"])
		var/page = href_list["unbanpagecount"]
		var/player_key = href_list["unbankey"]
		var/admin_key = href_list["unbanadminkey"]
		var/player_ip = href_list["unbanip"]
		var/player_cid = href_list["unbancid"]
		unban_panel(player_key, admin_key, player_ip, player_cid, page)

	else if(href_list["editbanid"])
		var/edit_id = href_list["editbanid"]
		var/player_key = href_list["editbankey"]
		var/player_ip = href_list["editbanip"]
		var/player_cid = href_list["editbancid"]
		var/role = href_list["editbanrole"]
		var/duration = href_list["editbanduration"]
		var/applies_to_admins = text2num(href_list["editbanadmins"])
		var/reason = url_decode(href_list["editbanreason"])
		var/page = href_list["editbanpage"]
		var/admin_key = href_list["editbanadminkey"]
		ban_panel(player_key, player_ip, player_cid, role, duration, applies_to_admins, reason, edit_id, page, admin_key)

	else if(href_list["unbanid"])
		var/ban_id = href_list["unbanid"]
		var/player_key = href_list["unbankey"]
		var/player_ip = href_list["unbanip"]
		var/player_cid = href_list["unbancid"]
		var/role = href_list["unbanrole"]
		var/page = href_list["unbanpage"]
		var/admin_key = href_list["unbanadminkey"]
		unban(ban_id, player_key, player_ip, player_cid, role, page, admin_key)

	else if(href_list["unbanlog"])
		var/ban_id = href_list["unbanlog"]
		ban_log(ban_id)

	else if(href_list["beakerpanel"])
		beaker_panel_act(href_list)

	else if(href_list["reloadpolls"])
		GLOB.polls.Cut()
		GLOB.poll_options.Cut()
		load_poll_data()
		poll_list_panel()

	else if(href_list["newpoll"])
		poll_management_panel()

	else if(href_list["editpoll"])
		var/datum/poll_question/poll = locate(href_list["editpoll"]) in GLOB.polls
		poll_management_panel(poll)

	else if(href_list["deletepoll"])
		var/datum/poll_question/poll = locate(href_list["deletepoll"]) in GLOB.polls
		poll.delete_poll()
		poll_list_panel()

	else if(href_list["initializepoll"])
		poll_parse_href(href_list)

	else if(href_list["submitpoll"])
		var/datum/poll_question/poll = locate(href_list["submitpoll"]) in GLOB.polls
		poll_parse_href(href_list, poll)

	else if(href_list["clearpollvotes"])
		var/datum/poll_question/poll = locate(href_list["clearpollvotes"]) in GLOB.polls
		poll.clear_poll_votes()
		poll_management_panel(poll)

	else if(href_list["addpolloption"])
		var/datum/poll_question/poll = locate(href_list["addpolloption"]) in GLOB.polls
		poll_option_panel(poll)

	else if(href_list["editpolloption"])
		var/datum/poll_option/option = locate(href_list["editpolloption"]) in GLOB.poll_options
		var/datum/poll_question/poll = locate(href_list["parentpoll"]) in GLOB.polls
		poll_option_panel(poll, option)

	else if(href_list["deletepolloption"])
		var/datum/poll_option/option = locate(href_list["deletepolloption"]) in GLOB.poll_options
		var/datum/poll_question/poll = option.delete_option()
		poll_management_panel(poll)

	else if(href_list["submitoption"])
		var/datum/poll_option/option = locate(href_list["submitoption"]) in GLOB.poll_options
		var/datum/poll_question/poll = locate(href_list["submitoptionpoll"]) in GLOB.polls
		poll_option_parse_href(href_list, poll, option)

	else if(href_list["admincommend"])
		var/mob/heart_recepient = locate(href_list["admincommend"])
		if(tgui_alert(usr, "Хочешь выдать сердечко в ООС [heart_recepient.ckey]?", "<3?", list("Да", "Нет")) == "Нет")
			return
		heart_recepient.receive_heart(usr, instant = TRUE)

	else if(href_list["force_war"])
		if(!check_rights(R_ADMIN))
			return
		var/obj/item/nuclear_challenge/button = locate(href_list["force_war"])
		button.force_war()

	else if (href_list["interview"])
		if(!check_rights(R_ADMIN))
			return
		var/datum/interview/I = locate(href_list["interview"])
		if (I)
			I.ui_interact(usr)

	else if (href_list["interview_man"])
		if(!check_rights(R_ADMIN))
			return
		GLOB.interviews.ui_interact(usr)

/datum/admins/proc/HandleCMode()
	if(!check_rights(R_ADMIN))
		return

	var/dat = {"<B>What mode do you wish to play?</B><HR>"}
	for(var/mode in config.modes)
		dat += {"<A href='?src=[REF(src)];[HrefToken()];c_mode2=[mode]'>[config.mode_names[mode]]</A><br>"}
	dat += {"<A href='?src=[REF(src)];[HrefToken()];c_mode2=secret'>Secret</A><br>"}
	dat += {"<A href='?src=[REF(src)];[HrefToken()];c_mode2=random'>Random</A><br>"}
	dat += {"Now: [GLOB.master_mode]"}
	usr << browse(dat, "window=c_mode")

/datum/admins/proc/HandleFSecret()
	if(!check_rights(R_ADMIN))
		return

	if(SSticker.HasRoundStarted())
		return tgui_alert(usr, "The game has already started.", null, null, null, null)
	if(GLOB.master_mode != "secret")
		return tgui_alert(usr, "The game mode has to be secret!", null, null, null, null)
	var/dat = {"<B>What game mode do you want to force secret to be? Use this if you want to change the game mode, but want the players to believe it's secret. This will only work if the current game mode is secret.</B><HR>"}
	for(var/mode in config.modes)
		dat += {"<A href='?src=[REF(src)];[HrefToken()];f_secret2=[mode]'>[config.mode_names[mode]]</A><br>"}
	dat += {"<A href='?src=[REF(src)];[HrefToken()];f_secret2=secret'>Random (default)</A><br>"}
	dat += {"Now: [GLOB.secret_force_mode]"}
	usr << browse(dat, "window=f_secret")
