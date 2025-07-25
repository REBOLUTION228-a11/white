/mob/living/simple_animal/bot/secbot
	name = "Секьюритрон"
	desc = "Маленький охранный робот. Он выглядит уставшим."
	icon = 'icons/mob/aibots.dmi'
	icon_state = "secbot"
	density = FALSE
	anchored = FALSE
	health = 25
	maxHealth = 25
	damage_coeff = list(BRUTE = 0.5, BURN = 0.7, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	pass_flags = PASSMOB | PASSFLAPS

	radio_key = /obj/item/encryptionkey/secbot //AI Priv + Security
	radio_channel = RADIO_CHANNEL_SECURITY //Security channel
	bot_type = SEC_BOT
	model = "Securitron"
	bot_core_type = /obj/machinery/bot_core/secbot
	window_id = "autosec"
	window_name = "Автоматический охранный юнит v1.6"
	allow_pai = 0
	data_hud_type = DATA_HUD_SECURITY_ADVANCED
	path_image_color = "#FF0000"

	a_intent = "harm"

	var/baton_type = /obj/item/melee/baton
	var/obj/item/weapon
	var/mob/living/carbon/target
	var/oldtarget_name
	var/threatlevel = FALSE
	var/target_lastloc //Loc of target when arrested.
	var/last_found //There's a delay
	var/declare_arrests = TRUE //When making an arrest, should it notify everyone on the security channel?
	var/idcheck = FALSE //If true, arrest people with no IDs
	var/weaponscheck = FALSE //If true, arrest people for weapons if they lack access
	var/check_records = TRUE //Does it check security records?
	var/arrest_type = FALSE //If true, don't handcuff
	var/ranged = FALSE //used for EDs

	var/fair_market_price_arrest = 250 // On arrest, charges the violator this much. If they don't have that much in their account, the securitron will beat them instead
	var/fair_market_price_detain = 50 // Charged each time the violator is stunned on detain
	var/weapon_force = 20 // Only used for NAP violation beatdowns on non-grievous securitrons
	var/market_verb = "Подозреваемый"
	var/payment_department = ACCOUNT_SEC

/mob/living/simple_animal/bot/secbot/beepsky
	name = "Командир Бипски"
	desc = "Это командир Бипски! Официально начальник всех ботов на станции, Бипски остается таким же скромным и преданным закону, как и в тот день, когда его сфабриковали."
	idcheck = FALSE
	weaponscheck = FALSE
	auto_patrol = TRUE
	commissioned = TRUE

/mob/living/simple_animal/bot/secbot/beepsky/jr
	name = "Офицер Кроха"
	desc = "Это Кроха, меньший по размеру и столь же агрессивный кузен Командира Бипски."
	commissioned = FALSE

/mob/living/simple_animal/bot/secbot/beepsky/jr/Initialize()
	. = ..()
	resize = 0.8
	update_transform()


/mob/living/simple_animal/bot/secbot/beepsky/explode()
	var/atom/Tsec = drop_location()
	new /obj/item/stock_parts/cell/potato(Tsec)
	var/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass/S = new(Tsec)
	S.reagents.add_reagent(/datum/reagent/consumable/ethanol/whiskey, 15)
	..()

/mob/living/simple_animal/bot/secbot/pingsky
	name = "Офицер Пингски"
	desc = "Это офицер Пингски! Ему поручено охранять спутник за укрывательство античеловеческих настроений." //"It's Officer Pingsky! Delegated to satellite guard duty for harbouring anti-human sentiment." - как это блять переводить?
	radio_channel = RADIO_CHANNEL_AI_PRIVATE

/mob/living/simple_animal/bot/secbot/Initialize()
	. = ..()
	weapon = new baton_type()
	update_icon()

	// Doing this hurts my soul, but simplebot access reworks are for another day.
	var/datum/id_trim/job/det_trim = SSid_access.trim_singletons_by_path[/datum/id_trim/job/detective]
	access_card.add_access(det_trim.access + det_trim.wildcard_access)
	prev_access = access_card.access.Copy()

	//SECHUD
	var/datum/atom_hud/secsensor = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	secsensor.add_hud_to(src)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/simple_animal/bot/secbot/Destroy()
	QDEL_NULL(weapon)
	return ..()

/mob/living/simple_animal/bot/secbot/update_icon()
	if(mode == BOT_HUNT)
		icon_state = "[initial(icon_state)]-c"
		return
	..()

/mob/living/simple_animal/bot/secbot/turn_off()
	..()
	mode = BOT_IDLE

/mob/living/simple_animal/bot/secbot/bot_reset()
	..()
	target = null
	oldtarget_name = null
	anchored = FALSE
	SSmove_manager.stop_looping(src)
	last_found = world.time

/mob/living/simple_animal/bot/secbot/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)//shocks only make him angry
	if(base_speed < initial(base_speed) + 3)
		base_speed += 3
		addtimer(VARSET_CALLBACK(src, base_speed, base_speed - 3), 60)
		playsound(src, 'sound/machines/defib_zap.ogg', 50)
		visible_message(span_warning("[capitalize(src.name)] пошатывается и ускоряется!"))

/mob/living/simple_animal/bot/secbot/set_custom_texts()
	text_hack = "Перегружаю систему идентификации [name]."
	text_dehack = "Перезагружаю и восстанавливаю систему идентификации [name]."
	text_dehack_fail = "[name] не воспринимает мои команды на перезапуск!"

/mob/living/simple_animal/bot/secbot/get_controls(mob/user)
	var/dat
	dat += hack(user)
	dat += showpai(user)
	dat += text({"
<TT><B>Управление Секьюритроном v1.6</B></TT><BR><BR>
Состояние: []<BR>
Управление поведением [locked ? "заблокировано" : "разблокировано"]<BR>
Техническая панель [open ? "открыта" : "закрыта"]"},

"<A href='?src=[REF(src)];power=1'>[on ? "Вкл" : "Выкл"]</A>" )

	if(!locked || issilicon(user) || isAdminGhostAI(user))
		dat += text({"<BR>
Арест неустановленных лиц: []<BR>
Арест за незаконное оружие: []<BR>
Арест по ордеру: []<BR>
Рабочий режим: []<BR>
Сообщать об арестах[]<BR>
Авто-патруль: []"},

"<A href='?src=[REF(src)];operation=idcheck'>[idcheck ? "Да" : "Нет"]</A>",
"<A href='?src=[REF(src)];operation=weaponscheck'>[weaponscheck ? "Да" : "Нет"]</A>",
"<A href='?src=[REF(src)];operation=ignorerec'>[check_records ? "Да" : "Нет"]</A>",
"<A href='?src=[REF(src)];operation=switchmode'>[arrest_type ? "Задержать" : "Арестовать"]</A>",
"<A href='?src=[REF(src)];operation=declarearrests'>[declare_arrests ? "Да" : "Нет"]</A>",
"<A href='?src=[REF(src)];operation=patrol'>[auto_patrol ? "Да" : "Нет"]</A>" )

	return	dat

/mob/living/simple_animal/bot/secbot/Topic(href, href_list)
	if(..())
		return 1

	switch(href_list["operation"])
		if("idcheck")
			idcheck = !idcheck
			update_controls()
		if("weaponscheck")
			weaponscheck = !weaponscheck
			update_controls()
		if("ignorerec")
			check_records = !check_records
			update_controls()
		if("switchmode")
			arrest_type = !arrest_type
			update_controls()
		if("declarearrests")
			declare_arrests = !declare_arrests
			update_controls()

/mob/living/simple_animal/bot/secbot/proc/retaliate(mob/living/carbon/human/H)
	var/judgement_criteria = judgement_criteria()
	threatlevel = H.assess_threat(judgement_criteria, weaponcheck=CALLBACK(src, PROC_REF(check_for_weapons)))
	threatlevel += 6
	if(threatlevel >= 4)
		target = H
		mode = BOT_HUNT

/mob/living/simple_animal/bot/secbot/proc/judgement_criteria()
	var/final = FALSE
	if(idcheck)
		final |= JUDGE_IDCHECK
	if(check_records)
		final |= JUDGE_RECORDCHECK
	if(weaponscheck)
		final |= JUDGE_WEAPONCHECK
	if(emagged == 2)
		final |= JUDGE_EMAGGED
	if(ranged)
		final |= JUDGE_IGNOREMONKEYS
	return final

/mob/living/simple_animal/bot/secbot/proc/special_retaliate_after_attack(mob/user) //allows special actions to take place after being attacked.
	return

/mob/living/simple_animal/bot/secbot/attack_hand(mob/living/carbon/human/H)
	if((H.a_intent == INTENT_HARM) || (H.a_intent == INTENT_DISARM))
		retaliate(H)
		if(special_retaliate_after_attack(H))
			return

		// Turns an oversight into a feature. Beepsky will now announce when pacifists taunt him over sec comms.
		if(HAS_TRAIT(H, TRAIT_PACIFISM))
			H.visible_message(span_notice("[H] насмехается над [src.name], провоцируя его на погоню!") , \
				span_notice("Насмехаюсь над [src.name], провоцируя его на погоню!") , span_hear("Слышу, как кто-то насмехается надо мной!") , DEFAULT_MESSAGE_RANGE, H)
			speak("Пацифистский отморозок <b>[H]</b> насмехается надо мной в [get_area(src)].", radio_channel)

			// Interrupt the attack chain. We've already handled this scenario for pacifists.
			return

	return ..()

/mob/living/simple_animal/bot/secbot/attackby(obj/item/W, mob/user, params)
	..()
	if(W.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM) // Any intent but harm will heal, so we shouldn't get angry.
		return
	if(W.tool_behaviour != TOOL_SCREWDRIVER && (W.force) && (!target) && (W.damtype != STAMINA) ) // Added check for welding tool to fix #2432. Welding tool behavior is handled in superclass.
		retaliate(user)
		if(special_retaliate_after_attack(user))
			return

/mob/living/simple_animal/bot/secbot/emag_act(mob/user)
	..()
	if(emagged == 2)
		if(user)
			to_chat(user, span_danger("Перепрограммирую систему идентификации преступников [src.name]."))
			oldtarget_name = user.name
		audible_message(span_danger("[capitalize(src.name)] громко жужжит!"))
		declare_arrests = FALSE
		update_icon()

/mob/living/simple_animal/bot/secbot/bullet_act(obj/projectile/Proj)
	if(istype(Proj , /obj/projectile/beam)||istype(Proj, /obj/projectile/bullet))
		if((Proj.damage_type == BURN) || (Proj.damage_type == BRUTE))
			if(!Proj.nodamage && Proj.damage < src.health && ishuman(Proj.firer))
				retaliate(Proj.firer)
	return ..()

/mob/living/simple_animal/bot/secbot/UnarmedAttack(atom/A)
	if(!on)
		return
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	if(iscarbon(A))
		var/mob/living/carbon/C = A
		if(!C.IsParalyzed() || arrest_type)
			if(!check_nap_violations())
				stun_attack(A, TRUE)
			else
				stun_attack(A)
		else if(C.canBeHandcuffed() && !C.handcuffed)
			cuff(A)
	else
		..()

/mob/living/simple_animal/bot/secbot/hitby(atom/movable/AM, skipcatch = FALSE, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(istype(AM, /obj/item))
		var/obj/item/I = AM
		var/mob/thrown_by = I.thrownby?.resolve()
		if(I.throwforce < src.health && thrown_by && ishuman(thrown_by))
			var/mob/living/carbon/human/H = thrown_by
			retaliate(H)
	..()

/mob/living/simple_animal/bot/secbot/proc/cuff(mob/living/carbon/C)
	mode = BOT_ARREST
	playsound(src, 'sound/weapons/cablecuff.ogg', 30, TRUE, -2)
	C.visible_message(span_danger("[capitalize(src.name)] пытается надеть стяжки на [C]!") ,\
						span_userdanger("[capitalize(src.name)] пытается надеть стяжки на меня!"))
	addtimer(CALLBACK(src, PROC_REF(attempt_handcuff), C), 60)

/mob/living/simple_animal/bot/secbot/proc/attempt_handcuff(mob/living/carbon/C)
	if( !on || !Adjacent(C) || !isturf(C.loc) ) //if he's in a closet or not adjacent, we cancel cuffing.
		return
	if(!C.handcuffed)
		C.set_handcuffed(new /obj/item/restraints/handcuffs/cable/zipties/used(C))
		C.update_handcuffed()
		playsound(src, "law_russian", 50, FALSE)
		back_to_idle()

/mob/living/simple_animal/bot/secbot/proc/stun_attack(mob/living/carbon/C, harm = FALSE)

	if(prob(35))
		C.visible_message(span_danger("<b>[capitalize(src.name)]</b> промахивается, пытаясь ударить <b>[C]</b>!") ,\
								span_userdanger("[capitalize(src.name)] промахивается, пытаясь ударить меня!"))
		return FALSE

	var/judgement_criteria = judgement_criteria()
	playsound(src, 'sound/weapons/egloves.ogg', 50, TRUE, -1)
	icon_state = "[initial(icon_state)]-c"
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_icon)), 2)
	var/threat = 5

	if(harm)
		weapon.attack(C, src)
	if(ishuman(C))
		C.stuttering = 5
		C.Paralyze(100)
		var/mob/living/carbon/human/H = C
		threat = H.assess_threat(judgement_criteria, weaponcheck=CALLBACK(src, PROC_REF(check_for_weapons)))
	else
		C.Paralyze(100)
		C.stuttering = 5
		threat = C.assess_threat(judgement_criteria, weaponcheck=CALLBACK(src, PROC_REF(check_for_weapons)))

	log_combat(src,C,"stunned")
	if(declare_arrests)
		var/area/location = get_area(src)
		speak("[arrest_type ? "Задерживаю" : "Арест"] преступника <b>[C]</b> уровня [threat] в [location].", radio_channel)
	C.visible_message(span_danger("<b>[capitalize(src.name)]</b> бьёт шокером <b>[C]</b>!") ,\
							span_userdanger("[capitalize(src.name)] бьёт меня шокером!"))

/mob/living/simple_animal/bot/secbot/handle_automated_action()
	if(!..())
		return

	switch(mode)

		if(BOT_IDLE)		// idle

			SSmove_manager.stop_looping(src)
			look_for_perp()	// see if any criminals are in range
			if(!mode && auto_patrol)	// still idle, and set to patrol
				mode = BOT_START_PATROL	// switch to patrol mode

		if(BOT_HUNT)		// hunting for perp

			// if can't reach perp for long enough, go idle
			if(frustration >= 8)
				SSmove_manager.stop_looping(src)
				back_to_idle()
				return

			if(target)		// make sure target exists
				if(Adjacent(target) && isturf(target.loc))	// if right next to perp
					if(!check_nap_violations())
						stun_attack(target, TRUE)
					else
						stun_attack(target)

					mode = BOT_PREP_ARREST
					set_anchored(TRUE)
					target_lastloc = target.loc
					return

				else								// not next to perp
					var/turf/olddist = get_dist(src, target)
					SSmove_manager.move_to(src, target, 1, 4)
					if((get_dist(src, target)) >= (olddist))
						frustration++
					else
						frustration = 0
			else
				back_to_idle()

		if(BOT_PREP_ARREST)		// preparing to arrest target

			// see if he got away. If he's no no longer adjacent or inside a closet or about to get up, we hunt again.
			if( !Adjacent(target) || !isturf(target.loc) ||  target.AmountParalyzed() < 40)
				back_to_hunt()
				return

			if(iscarbon(target) && target.canBeHandcuffed())
				if(!arrest_type)
					if(!target.handcuffed)  //he's not cuffed? Try to cuff him!
						cuff(target)
					else
						back_to_idle()
						return
			else
				back_to_idle()
				return

		if(BOT_ARREST)
			if(!target)
				set_anchored(FALSE)
				mode = BOT_IDLE
				last_found = world.time
				frustration = 0
				return

			if(target.handcuffed) //no target or target cuffed? back to idle.
				if(!check_nap_violations())
					stun_attack(target, TRUE)
					return
				back_to_idle()
				return

			if(!Adjacent(target) || !isturf(target.loc) || (target.loc != target_lastloc && target.AmountParalyzed() < 40)) //if he's changed loc and about to get up or not adjacent or got into a closet, we prep arrest again.
				back_to_hunt()
				return
			else //Try arresting again if the target escapes.
				mode = BOT_PREP_ARREST
				set_anchored(FALSE)

		if(BOT_START_PATROL)
			look_for_perp()
			start_patrol()

		if(BOT_PATROL)
			look_for_perp()
			bot_patrol()


	return

/mob/living/simple_animal/bot/secbot/proc/back_to_idle()
	anchored = FALSE
	mode = BOT_IDLE
	target = null
	last_found = world.time
	frustration = 0
	INVOKE_ASYNC(src, PROC_REF(handle_automated_action))

/mob/living/simple_animal/bot/secbot/proc/back_to_hunt()
	anchored = FALSE
	frustration = 0
	mode = BOT_HUNT
	INVOKE_ASYNC(src, PROC_REF(handle_automated_action))
// look for a criminal in view of the bot

/mob/living/simple_animal/bot/secbot/proc/look_for_perp()
	anchored = FALSE
	var/judgement_criteria = judgement_criteria()
	for (var/mob/living/carbon/C in view(7,src)) //Let's find us a criminal
		if((C.stat) || (C.handcuffed))
			continue

		if((C.name == oldtarget_name) && (world.time < last_found + 100))
			continue

		threatlevel = C.assess_threat(judgement_criteria, weaponcheck=CALLBACK(src, PROC_REF(check_for_weapons)))

		if(!threatlevel)
			continue

		else if(threatlevel >= 4)
			target = C
			oldtarget_name = C.name
			speak("Уровень [threatlevel], предупреждение о нарушении!")
			if(ranged)
				playsound(src, pick('sound/voice/ed209_20sec.ogg', 'sound/voice/edplaceholder.ogg'), 50, FALSE)
			else
				//playsound(src, pick('sound/voice/beepsky/criminal.ogg', 'sound/voice/beepsky/justice.ogg', 'sound/voice/beepsky/freeze.ogg'), 50, FALSE)
				playsound(loc, pick('white/valtos/sounds/beepsky_russian/criminal.ogg', 'white/valtos/sounds/beepsky_russian/justice.ogg', 'white/valtos/sounds/beepsky_russian/freeze.ogg'), 50, FALSE)
			visible_message("<b>[capitalize(src.name)]</b> направляется в сторону [C.name]!")
			mode = BOT_HUNT
			INVOKE_ASYNC(src, PROC_REF(handle_automated_action))
			break
		else
			continue

/mob/living/simple_animal/bot/secbot/proc/check_for_weapons(obj/item/slot_item)
	if(slot_item && (slot_item.item_flags & NEEDS_PERMIT))
		return TRUE
	return FALSE

/mob/living/simple_animal/bot/secbot/explode()
	visible_message(span_boldannounce("[capitalize(src.name)] взрывается!"))
	var/atom/Tsec = drop_location()
	if(ranged)
		var/obj/item/bot_assembly/ed209/Sa = new (Tsec)
		Sa.build_step = 1
		Sa.add_overlay("hs_hole")
		Sa.created_name = name
		new /obj/item/assembly/prox_sensor(Tsec)
		var/obj/item/gun/energy/disabler/G = new (Tsec)
		G.cell.charge = 0
		G.update_icon()
		if(prob(50))
			new /obj/item/bodypart/l_leg/robot(Tsec)
			if(prob(25))
				new /obj/item/bodypart/r_leg/robot(Tsec)
		if(prob(25))//50% chance for a helmet OR vest
			if(prob(50))
				new /obj/item/clothing/head/helmet(Tsec)
			else
				new /obj/item/clothing/suit/armor/vest(Tsec)
	else
		var/obj/item/bot_assembly/secbot/Sa = new (Tsec)
		Sa.build_step = 1
		Sa.add_overlay("hs_hole")
		Sa.created_name = name
		new /obj/item/assembly/prox_sensor(Tsec)
		drop_part(baton_type, Tsec)

		if(prob(50))
			drop_part(robot_arm, Tsec)

	do_sparks(3, TRUE, src)

	new /obj/effect/decal/cleanable/oil(loc)
	..()

/mob/living/simple_animal/bot/secbot/attack_alien(mob/living/carbon/alien/user as mob)
	..()
	if(!isalien(target))
		target = user
		mode = BOT_HUNT

/mob/living/simple_animal/bot/secbot/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(has_gravity() && ismob(AM) && target)
		var/mob/living/carbon/C = AM
		if(!istype(C) || !C || in_range(src, target))
			return
		knockOver(C)
		return

/obj/machinery/bot_core/secbot
	req_access = list(ACCESS_SECURITY)

/// Returns false if the current target is unable to pay the fair_market_price for being arrested/detained
/mob/living/simple_animal/bot/secbot/proc/check_nap_violations()
	if(!SSeconomy.full_ancap)
		return TRUE

	if(target)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/obj/item/card/id/I = H.get_idcard(TRUE)
			if(I)
				var/datum/bank_account/insurance = I.registered_account
				if(!insurance)
					say("[market_verb] нарушает NAP: Банковский счет не найден.")
					nap_violation(target)
					return FALSE
				else
					var/fair_market_price = (arrest_type ? fair_market_price_detain : fair_market_price_arrest)
					if(!insurance.adjust_money(-fair_market_price))
						say("[market_verb] нарушает NAP: Невозможна оплата.")
						nap_violation(target)
						return FALSE
					var/datum/bank_account/D = SSeconomy.get_dep_account(payment_department)
					say("Спасибо за согласие. С аккаунта списано [fair_market_price] кредит[get_num_string(fair_market_price)].")
					if(D)
						D.adjust_money(fair_market_price)
			else
				say("[market_verb] нарушает NAP: Не обнаружено ID-карты.")
				nap_violation(target)
				return FALSE
	return TRUE

/// Does nothing
/mob/living/simple_animal/bot/secbot/proc/nap_violation(mob/violator)
	return
