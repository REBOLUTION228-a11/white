#define DECONVERTER_STATION_WIN "gamemode_station_win"
#define DECONVERTER_REVS_WIN "gamemode_revs_win"
//How often to check for promotion possibility
#define HEAD_UPDATE_PERIOD 300

/datum/antagonist/rev
	name = "Революционер"
	roundend_category = "revolutionaries" // if by some miracle revolutionaries without revolution happen
	antagpanel_category = "Revolution"
	job_rank = ROLE_REV
	antag_moodlet = /datum/mood_event/revolution
	antag_hud_type = ANTAG_HUD_REV
	antag_hud_name = "rev"
	var/datum/team/revolution/rev_team
	greentext_reward = 20

	/// What message should the player receive when they are being demoted, and the revolution has won?
	var/victory_message = "Революция взяла верх над командным составом! Да здравствует революция! Казните всех начальников отделов и охрану, если найдете их живыми."

/datum/antagonist/rev/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(.)
		if(new_owner.assigned_role in GLOB.command_positions)
			return FALSE
		if(new_owner.unconvertable)
			return FALSE
		if(new_owner.current && HAS_TRAIT(new_owner.current, TRAIT_MINDSHIELD))
			return FALSE

/datum/antagonist/rev/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, M)
	handle_clown_mutation(M, mob_override ? null : "Ваши тренировки позволили вам преодолеть свою клоунскую натуру, позволяя вам владеть оружием без вреда для себя.")

/datum/antagonist/rev/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	remove_antag_hud(antag_hud_type, M)
	handle_clown_mutation(M, removing = FALSE)

/datum/antagonist/rev/proc/equip_rev()
	return

/datum/antagonist/rev/on_gain()
	. = ..()
	create_objectives()
	equip_rev()
	owner.current.log_message("has been converted to the revolution!", LOG_ATTACK, color="red")

/datum/antagonist/rev/on_removal()
	remove_objectives()
	. = ..()

/datum/antagonist/rev/greet()
	to_chat(owner, span_userdanger("Теперь вы революционер! Помогайте своему делу. Не причиняйте вреда своим товарищам по борьбе за свободу. Вы можете узнать своих товарищей по красным \"R\" значкам, а своих лидеров по синим \"R\" значкам. Помогите им убить главарей, чтобы одержать победу!"))
	owner.announce_objectives()

/datum/antagonist/rev/create_team(datum/team/revolution/new_team)
	if(!new_team)
		//For now only one revolution at a time
		for(var/datum/antagonist/rev/head/H in GLOB.antagonists)
			if(!H.owner)
				continue
			if(H.rev_team)
				rev_team = H.rev_team
				return
		rev_team = new /datum/team/revolution
		rev_team.update_objectives()
		rev_team.update_heads()
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	rev_team = new_team

/datum/antagonist/rev/get_team()
	return rev_team

/datum/antagonist/rev/proc/create_objectives()
	objectives |= rev_team.objectives

/datum/antagonist/rev/proc/remove_objectives()
	objectives -= rev_team.objectives

//Bump up to head_rev
/datum/antagonist/rev/proc/promote()
	var/old_team = rev_team
	var/datum/mind/old_owner = owner
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev)
	var/datum/antagonist/rev/head/new_revhead = new()
	new_revhead.silent = TRUE
	old_owner.add_antag_datum(new_revhead,old_team)
	new_revhead.silent = FALSE
	to_chat(old_owner, span_userdanger("Вы доказали свою преданность революции! Теперь вы главный революционер!"))

/datum/antagonist/rev/get_admin_commands()
	. = ..()
	.["Promote"] = CALLBACK(src,PROC_REF(admin_promote))

/datum/antagonist/rev/proc/admin_promote(mob/admin)
	var/datum/mind/O = owner
	promote()
	message_admins("[key_name_admin(admin)] has head-rev'ed [O].")
	log_admin("[key_name(admin)] has head-rev'ed [O].")

/datum/antagonist/rev/head/admin_add(datum/mind/new_owner,mob/admin)
	give_flash = TRUE
	give_hud = TRUE
	remove_clumsy = TRUE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has head-rev'ed [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has head-rev'ed [key_name(new_owner)].")
	to_chat(new_owner.current, span_userdanger("Теперь вы являетесь лидером революционеров!"))

/datum/antagonist/rev/head/get_admin_commands()
	. = ..()
	. -= "Promote"
	.["Take flash"] = CALLBACK(src,PROC_REF(admin_take_flash))
	.["Give flash"] = CALLBACK(src,PROC_REF(admin_give_flash))
	.["Repair flash"] = CALLBACK(src,PROC_REF(admin_repair_flash))
	.["Demote"] = CALLBACK(src,PROC_REF(admin_demote))

/datum/antagonist/rev/head/proc/admin_take_flash(mob/admin)
	var/list/L = owner.current.get_contents()
	var/obj/item/assembly/flash/handheld/flash = locate() in L
	if (!flash)
		to_chat(admin, span_danger("Deleting flash failed!"))
		return
	qdel(flash)

/datum/antagonist/rev/head/proc/admin_give_flash(mob/admin)
	//This is probably overkill but making these impact state annoys me
	var/old_give_flash = give_flash
	var/old_give_hud = give_hud
	var/old_remove_clumsy = remove_clumsy
	give_flash = TRUE
	give_hud = FALSE
	remove_clumsy = FALSE
	equip_rev()
	give_flash = old_give_flash
	give_hud = old_give_hud
	remove_clumsy = old_remove_clumsy

/datum/antagonist/rev/head/proc/admin_repair_flash(mob/admin)
	var/list/L = owner.current.get_contents()
	var/obj/item/assembly/flash/handheld/flash = locate() in L
	if (!flash)
		to_chat(admin, span_danger("Repairing flash failed!"))
	else
		flash.burnt_out = FALSE
		flash.update_icon()

/datum/antagonist/rev/head/proc/admin_demote(datum/mind/target,mob/user)
	message_admins("[key_name_admin(user)] has demoted [key_name_admin(owner)] from head revolutionary.")
	log_admin("[key_name(user)] has demoted [key_name(owner)] from head revolutionary.")
	demote()

/datum/antagonist/rev/head
	name = "Head Revolutionary"
	antag_hud_name = "rev_head"
	var/remove_clumsy = FALSE
	var/give_flash = FALSE
	var/give_hud = TRUE
	greentext_reward = 25

/datum/antagonist/rev/head/on_removal()
	if(give_hud)
		var/mob/living/carbon/C = owner.current
		var/obj/item/organ/cyberimp/eyes/hud/security/syndicate/S = C.getorganslot(ORGAN_SLOT_HUD)
		if(S)
			S.Remove(C)
	return ..()

/datum/antagonist/rev/head/antag_listing_name()
	return ..() + "(Leader)"

/datum/antagonist/rev/proc/can_be_converted(mob/living/candidate)
	if(!candidate.mind)
		return FALSE
	if(!can_be_owned(candidate.mind))
		return FALSE
	var/mob/living/carbon/C = candidate //Check to see if the potential rev is implanted
	if(!istype(C)) //Can't convert simple animals
		return FALSE
	return TRUE

/datum/antagonist/rev/proc/add_revolutionary(datum/mind/rev_mind,stun = TRUE)
	if(!can_be_converted(rev_mind.current))
		return FALSE
	if(stun)
		if(iscarbon(rev_mind.current))
			var/mob/living/carbon/carbon_mob = rev_mind.current
			carbon_mob.silent = max(carbon_mob.silent, 5)
			carbon_mob.flash_act(1, 1)
		rev_mind.current.Stun(100)
	rev_mind.add_antag_datum(/datum/antagonist/rev,rev_team)
	rev_mind.special_role = ROLE_REV
	return TRUE

/datum/antagonist/rev/head/proc/demote()
	var/datum/mind/old_owner = owner
	var/old_team = rev_team
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev/head)
	var/datum/antagonist/rev/new_rev = new /datum/antagonist/rev()
	new_rev.silent = TRUE
	old_owner.add_antag_datum(new_rev,old_team)
	new_rev.silent = FALSE
	to_chat(old_owner, span_userdanger("Революция разочаровалась в ваших лидерских качествах! Теперь вы обычный революционер!"))

/// Checks if the revolution succeeded, and lets them know.
/datum/antagonist/rev/proc/announce_victorious()
	. = rev_team.check_rev_victory()

	if (!.)
		return

	to_chat(owner, "<span class='deconversion_message bold'>[victory_message]</span>")
	var/policy = get_policy(ROLE_REV_SUCCESSFUL)
	if (policy)
		to_chat(owner, policy)

/datum/antagonist/rev/farewell()
	if (announce_victorious())
		return

	if(ishuman(owner.current))
		owner.current.visible_message(span_deconversion_message("[owner.current], похоже, вспомнил[owner.current.ru_a()] свою истинную верность!") , null, null, null, owner.current)
		to_chat(owner, "<span class ='deconversion_message bold'>Вы больше не революционер с промытыми мозгами! Ваша память затуманена с тех пор, как вы были бунтарем... единственное, что вы помните, это имя того, кто промыл вам мозги...</span>")
	else if(issilicon(owner.current))
		owner.current.visible_message(span_deconversion_message("Рамка удовлетворенно пищит, очищая враждебную программу памяти от ММИ, прежде чем инициализировать его.") , null, null, null, owner.current)
		to_chat(owner, span_userdanger("Прошивка рамки обнаруживает и удаляет ваше нейронное перепрограммирование! Вы не помните ничего, кроме имени того, кто вас прошил."))

/datum/antagonist/rev/head/farewell()
	if (announce_victorious())
		return

	if((ishuman(owner.current)))
		if(owner.current.stat != DEAD)
			owner.current.visible_message(span_deconversion_message("[owner.current], похоже, вспомнил[owner.current.ru_a()] свою истинную верность!") , null, null, null, owner.current)
			to_chat(owner, "<span class ='deconversion_message bold'>Вы отказались от своей цели - свержения командного состава. Вы больше не являетесь главным революционером.</span>")
		else
			to_chat(owner, "<span class ='deconversion_message bold'>Сладкое освобождение от смерти. Вы больше не являетесь главным революционером.</span>")
	else if(issilicon(owner.current))
		owner.current.visible_message(span_deconversion_message("Рамка удовлетворенно пищит, подавляя нелояльные черты личности из ММИ, прежде чем инициализировать его.") , null, null, null, owner.current)
		to_chat(owner, span_userdanger("Микропрограмма рамки обнаруживает и подавляет ваши нежелательные черты характера! Вы чувствуете себя более довольным руководством в этих местах."))

//blunt trauma deconversions call this through species.dm spec_attacked_by()
/datum/antagonist/rev/proc/remove_revolutionary(borged, deconverter)
	log_attack("[key_name(owner.current)] has been deconverted from the revolution by [ismob(deconverter) ? key_name(deconverter) : deconverter]!")
	if(borged)
		message_admins("[ADMIN_LOOKUPFLW(owner.current)] has been borged while being a [name]")
	owner.special_role = null
	if(iscarbon(owner.current) && deconverter != DECONVERTER_REVS_WIN)
		var/mob/living/carbon/C = owner.current
		C.Unconscious(100)
	owner.remove_antag_datum(type)

/datum/antagonist/rev/head/remove_revolutionary(borged,deconverter)
	if(borged || deconverter == DECONVERTER_STATION_WIN || deconverter == DECONVERTER_REVS_WIN)
		. = ..()

/datum/antagonist/rev/head/equip_rev()
	var/mob/living/carbon/C = owner.current
	if(!ishuman(C))
		return

	if(give_flash)
		var/obj/item/assembly/flash/handheld/T = new(C)
		var/list/slots = list (
			"backpack" = ITEM_SLOT_BACKPACK,
			"left pocket" = ITEM_SLOT_LPOCKET,
			"right pocket" = ITEM_SLOT_RPOCKET
		)
		var/where = C.equip_in_one_of_slots(T, slots)
		if (!where)
			to_chat(C, "Синдикат, к сожалению, не смог достать для вас вспышку.")
		else
			to_chat(C, "Вспышка в вашей [where] поможет вам убедить членов экипажа присоединиться к вашему делу.")

	if(give_hud)
		var/obj/item/organ/cyberimp/eyes/hud/security/syndicate/S = new()
		S.Insert(C)
		to_chat(C, "В ваши глаза был имплантирован кибернетический HUD безопасности, который поможет вам отслеживать тех, кто был имплантирован щитом разума и не может быть завербован.")

/// "Enemy of the Revolutionary", given to heads and security when the revolution wins
/datum/antagonist/revolution_enemy
	name = "Враг Революции"
	show_in_antagpanel = FALSE
	greentext_reward = 30

/datum/antagonist/revolution_enemy/on_gain()
	owner.special_role = "revolution enemy"

	var/datum/objective/survive/survive = new /datum/objective/survive
	survive.owner = owner
	survive.explanation_text = "Станция захвачена революционерами. Останьтесь в живых до конца."
	objectives += survive

	return ..()

/datum/team/revolution
	name = "Революция"
	var/max_headrevs = 3
	var/list/ex_headrevs = list() // Dynamic removes revs on loss, used to keep a list for the roundend report.
	var/list/ex_revs = list()

/datum/team/revolution/proc/update_objectives(initial = FALSE)
	var/untracked_heads = SSjob.get_all_heads()
	for(var/datum/objective/mutiny/O in objectives)
		untracked_heads -= O.target
	for(var/datum/mind/M in untracked_heads)
		var/datum/objective/mutiny/new_target = new()
		new_target.team = src
		new_target.target = M
		new_target.update_explanation_text()
		objectives += new_target
	for(var/datum/mind/M in members)
		var/datum/antagonist/rev/R = M.has_antag_datum(/datum/antagonist/rev)
		R.objectives |= objectives

	addtimer(CALLBACK(src,PROC_REF(update_objectives)),HEAD_UPDATE_PERIOD,TIMER_UNIQUE)

/datum/team/revolution/proc/head_revolutionaries()
	. = list()
	for(var/datum/mind/M in members)
		if(M.has_antag_datum(/datum/antagonist/rev/head))
			. += M

/datum/team/revolution/proc/update_heads()
	if(SSticker.HasRoundStarted())
		var/list/datum/mind/head_revolutionaries = head_revolutionaries()
		var/list/datum/mind/heads = SSjob.get_all_heads()
		var/list/sec = SSjob.get_all_sec()

		if(head_revolutionaries.len < max_headrevs && head_revolutionaries.len < round(heads.len - ((8 - sec.len) / 3)))
			var/list/datum/mind/non_heads = members - head_revolutionaries
			var/list/datum/mind/promotable = list()
			var/list/datum/mind/nonhuman_promotable = list()
			for(var/datum/mind/khrushchev in non_heads)
				if(khrushchev.current && !khrushchev.current.incapacitated() && !HAS_TRAIT(khrushchev.current, TRAIT_RESTRAINED) && khrushchev.current.client)
					if(ROLE_REV in khrushchev.current.client.prefs.be_special)
						if(ishuman(khrushchev.current))
							promotable += khrushchev
						else
							nonhuman_promotable += khrushchev
			if(!promotable.len && nonhuman_promotable.len) //if only nonhuman revolutionaries remain, promote one of them to the leadership.
				promotable = nonhuman_promotable
			if(promotable.len)
				var/datum/mind/new_leader = pick(promotable)
				var/datum/antagonist/rev/rev = new_leader.has_antag_datum(/datum/antagonist/rev)
				rev.promote()

	addtimer(CALLBACK(src,PROC_REF(update_heads)),HEAD_UPDATE_PERIOD,TIMER_UNIQUE)

/datum/team/revolution/proc/save_members()
	ex_headrevs = get_antag_minds(/datum/antagonist/rev/head, TRUE)
	ex_revs = get_antag_minds(/datum/antagonist/rev, TRUE)

/// Checks if revs have won
/datum/team/revolution/proc/check_rev_victory()
	for(var/datum/objective/mutiny/objective in objectives)
		if(!(objective.check_completion()))
			return FALSE
	return TRUE

/// Checks if heads have won
/datum/team/revolution/proc/check_heads_victory()
	for(var/datum/mind/rev_mind in head_revolutionaries())
		var/turf/rev_turf = get_turf(rev_mind.current)
		if(!considered_afk(rev_mind) && considered_alive(rev_mind) && is_station_level(rev_turf.z))
			if(ishuman(rev_mind.current))
				return FALSE
	return TRUE

/// Updates the state of the world depending on if revs won or loss.
/// Returns who won, at which case this method should no longer be called.
/// If revs_win_injection_amount is passed, then that amount of threat will be added if the revs win.
/datum/team/revolution/proc/process_victory(revs_win_injection_amount)
	if (check_rev_victory())
		. = REVOLUTION_VICTORY
	else if (check_heads_victory())
		. = STATION_VICTORY
	else
		return

	SSshuttle.clearHostileEnvironment(src)
	save_members()

	// Remove everyone as a revolutionary
	for (var/_rev_mind in members)
		var/datum/mind/rev_mind = _rev_mind
		if (rev_mind.has_antag_datum(/datum/antagonist/rev))
			var/datum/antagonist/rev/rev_antag = rev_mind.has_antag_datum(/datum/antagonist/rev)
			rev_antag.remove_revolutionary(FALSE, . == STATION_VICTORY ? DECONVERTER_STATION_WIN : DECONVERTER_REVS_WIN)
			LAZYADD(rev_mind.special_statuses, span_bad("Former [(rev_mind in ex_headrevs) ? "head revolutionary" : "revolutionary"]"))

	if (. == STATION_VICTORY)
		// If the revolution was quelled, make rev heads unable to be revived through pods
		for (var/_rev_head_mind in ex_revs)
			var/datum/mind/rev_head_mind = _rev_head_mind
			var/mob/living/carbon/rev_head_body = rev_head_mind.current
			if(istype(rev_head_body) && rev_head_body.stat == DEAD)
				rev_head_body.makeUncloneable()

		priority_announce("Похоже, мятеж подавлен. Пожалуйста, верните себя и своих недееспособных коллег к работе. \
		Мы дистанционно внесли главных революционеров в черный список в ваших медицинских записях, чтобы предотвратить случайное оживление.", null, null, null, "Отдел мониторинга лояльности Центрального Командования")
	else
		for (var/_player in GLOB.player_list)
			var/mob/player = _player
			var/datum/mind/mind = player.mind

			if (isnull(mind))
				continue

			if (!(mind.assigned_role in GLOB.command_positions + GLOB.security_positions))
				continue

			var/mob/living/carbon/target_body = mind.current

			mind.add_antag_datum(/datum/antagonist/revolution_enemy)

			if (!istype(target_body))
				continue

			if (target_body.stat == DEAD)
				target_body.makeUncloneable()
			else
				mind.announce_objectives()

		for (var/job_name in GLOB.command_positions + GLOB.security_positions)
			var/datum/job/job = SSjob.GetJob(job_name)
			job.allow_bureaucratic_error = FALSE
			job.total_positions = 0

		if (revs_win_injection_amount)
			var/datum/game_mode/dynamic/dynamic = SSticker.mode
			dynamic.create_threat(revs_win_injection_amount)
			dynamic.threat_log += "[worldtime2text()]: Revolution victory. Added [revs_win_injection_amount] threat."

		priority_announce("Недавняя оценка вашей станции отметила ее как зону серьезного риска для высокопоставленных чиновников NanoTrasen. \
		В целях безопасности нашего персонала, мы внесли вашу станцию в черный список для новых сотрудников службы безопасности и командования. \
		[pick(world.file2list("strings/anti_union_propaganda.txt"))]", null, null, null, "Отдел мониторинга лояльности Центрального Командования")

/// Mutates the ticker to report that the revs have won
/datum/team/revolution/proc/round_result(finished)
	if (finished == REVOLUTION_VICTORY)
		SSticker.mode_result = "win - heads killed"
		SSticker.news_report = REVS_WIN
	else if (finished == STATION_VICTORY)
		SSticker.mode_result = "loss - rev heads killed"
		SSticker.news_report = REVS_LOSE

/datum/team/revolution/roundend_report()
	if(!members.len && !ex_headrevs.len)
		return

	var/list/result = list()

	result += "<div class='panel redborder'>"

	var/list/targets = list()
	var/list/datum/mind/headrevs
	var/list/datum/mind/revs
	if(ex_headrevs.len)
		headrevs = ex_headrevs
	else
		headrevs = get_antag_minds(/datum/antagonist/rev/head, TRUE)

	if(ex_revs.len)
		revs = ex_revs
	else
		revs = get_antag_minds(/datum/antagonist/rev, TRUE)

	var/num_revs = 0
	var/num_survivors = 0
	for(var/mob/living/carbon/survivor in GLOB.alive_mob_list)
		if(survivor.ckey)
			num_survivors += 1
			if ((survivor.mind in revs) || (survivor.mind in headrevs))
				num_revs += 1

	if(num_survivors)
		result += "Command's Approval Rating: <B>[100 - round((num_revs/num_survivors)*100, 0.1)]%</B><br>"

	if(headrevs.len)
		var/list/headrev_part = list()
		headrev_part += span_header("Главами революции были:")
		headrev_part += printplayerlist(headrevs, !check_rev_victory())
		result += headrev_part.Join("<br>")

	if(revs.len)
		var/list/rev_part = list()
		rev_part += span_header("Революцинерами были:")
		rev_part += printplayerlist(revs, !check_rev_victory())
		result += rev_part.Join("<br>")

	var/list/heads = SSjob.get_all_heads()
	if(heads.len)
		var/head_text = span_header("Главами отделов были:")
		head_text += "<ul class='playerlist'>"
		for(var/datum/mind/head in heads)
			var/target = (head in targets)
			head_text += "<li>"
			if(target)
				head_text += span_redtext("Target")
			head_text += "[printplayer(head, 1)]</li>"
		head_text += "</ul><br>"
		result += head_text

	result += "</div>"

	return result.Join()

/datum/team/revolution/antag_listing_entry()
	var/common_part = ""
	var/list/parts = list()
	parts += "<b>[antag_listing_name()]</b><br>"
	parts += "<table cellspacing=5>"

	var/list/heads = get_team_antags(/datum/antagonist/rev/head,TRUE)

	for(var/datum/antagonist/A in heads | get_team_antags())
		parts += A.antag_listing_entry()

	parts += "</table>"
	parts += antag_listing_footer()
	common_part = parts.Join()

	var/heads_report = "<b>Heads of Staff</b><br>"
	heads_report += "<table cellspacing=5>"
	for(var/datum/mind/N in SSjob.get_living_heads())
		var/mob/M = N.current
		if(M)
			heads_report += "<tr><td><a href='?_src_=holder;[HrefToken()];adminplayeropts=[REF(M)]'>[M.real_name]</a>[M.client ? "" : " <i>(No Client)</i>"][M.stat == DEAD ? " <b><font color=red>(DEAD)</font></b>" : ""]</td>"
			heads_report += "<td><A href='?priv_msg=[M.ckey]'>PM</A></td>"
			heads_report += "<td><A href='?_src_=holder;[HrefToken()];adminplayerobservefollow=[REF(M)]'>FLW</a></td>"
			var/turf/mob_loc = get_turf(M)
			heads_report += "<td>[mob_loc.loc]</td></tr>"
		else
			heads_report += "<tr><td><a href='?_src_=vars;[HrefToken()];Vars=[REF(N)]'>[N.name]([N.key])</a><i>Head body destroyed!</i></td>"
			heads_report += "<td><A href='?priv_msg=[N.key]'>PM</A></td></tr>"
	heads_report += "</table>"
	return common_part + heads_report

/datum/team/revolution/is_gamemode_hero()
	return SSticker.mode.name == "revolution"

#undef DECONVERTER_STATION_WIN
#undef DECONVERTER_REVS_WIN
