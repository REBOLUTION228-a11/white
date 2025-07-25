//Cleanbot
/mob/living/simple_animal/bot/hygienebot
	name = "Гигиенобот"
	desc = "Летающий робот-уборщик, преследующий людей, которые не умеют принимать душ."
	icon = 'icons/mob/aibots.dmi'
	icon_state = "hygienebot"
	base_icon_state = "hygienebot"
	pass_flags = PASSMOB | PASSFLAPS | PASSTABLE
	layer = MOB_UPPER_LAYER
	density = FALSE
	anchored = FALSE
	health = 100
	maxHealth = 100
	radio_key = /obj/item/encryptionkey/headset_service
	radio_channel = RADIO_CHANNEL_SERVICE //Service
	bot_type = HYGIENE_BOT
	model = "Cleanbot"
	bot_core_type = /obj/machinery/bot_core/hygienebot
	window_id = "autoclean"
	window_name = "Автоматический очиститель персонала X2"
	pass_flags = PASSMOB | PASSFLAPS
	path_image_color = "#993299"
	allow_pai = FALSE
	layer = ABOVE_MOB_LAYER

	///The human target the bot пытается wash.
	var/mob/living/carbon/human/target
	///The mob's current speed, which varies based on how long the bot chases it's target.
	var/currentspeed = 5
	///Is the bot currently washing it's target/everything else that crosses it?
	var/washing = FALSE
	///Have the target evaded the bot for long enough that it will swear at it like kirk did to kahn?
	var/mad = FALSE
	///The last time that the previous/current target was found.
	var/last_found
	///Name of the previous target the bot was pursuing.
	var/oldtarget_name
	///Visual overlay of the bot spraying water.
	var/mutable_appearance/water_overlay
	///Visual overlay of the bot commiting warcrimes.
	var/mutable_appearance/fire_overlay

/mob/living/simple_animal/bot/hygienebot/Initialize()
	. = ..()
	update_icon()

	// Doing this hurts my soul, but simplebot access reworks are for another day.
	var/datum/id_trim/job/jani_trim = SSid_access.trim_singletons_by_path[/datum/id_trim/job/janitor]
	access_card.add_access(jani_trim.access + jani_trim.wildcard_access)
	prev_access = access_card.access.Copy()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/simple_animal/bot/hygienebot/explode()
	visible_message(span_boldannounce("[capitalize(src.name)] взрывается и разбрызгивает вокруг пену!"))
	do_sparks(3, TRUE, src)
	on = FALSE
	new /obj/effect/particle_effect/foam(loc)

	..()

/mob/living/simple_animal/bot/hygienebot/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(washing)
		do_wash(AM)

/mob/living/simple_animal/bot/hygienebot/update_icon_state()
	. = ..()
	if(on)
		icon_state = "hygienebot-on"
	else
		icon_state = "hygienebot"


/mob/living/simple_animal/bot/hygienebot/update_overlays()
	. = ..()
	if(on)
		var/mutable_appearance/fire_overlay = mutable_appearance(icon, "hygienebot-flame")
		. +=fire_overlay


	if(washing)
		var/mutable_appearance/water_overlay = mutable_appearance(icon, emagged ? "hygienebot-fire" : "hygienebot-water")
		. += water_overlay


/mob/living/simple_animal/bot/hygienebot/turn_off()
	..()
	mode = BOT_IDLE

/mob/living/simple_animal/bot/hygienebot/bot_reset()
	..()
	target = null
	oldtarget_name = null
	SSmove_manager.stop_looping(src)
	last_found = world.time

/mob/living/simple_animal/bot/hygienebot/handle_automated_action()
	if(!..())
		return

	if(washing)
		do_wash(loc)
		for(var/AM in loc)
			do_wash(AM)
		if(isopenturf(loc) && !emagged)
			var/turf/open/tile = loc
			tile.MakeSlippery(TURF_WET_WATER, min_wet_time = 10 SECONDS, wet_time_to_add = 5 SECONDS)

	switch(mode)
		if(BOT_IDLE)		// idle
			SSmove_manager.stop_looping(src)
			look_for_lowhygiene()	// see if any disgusting fucks are in range
			if(!mode && auto_patrol)	// still idle, and set to patrol
				mode = BOT_START_PATROL	// switch to patrol mode

		if(BOT_HUNT)		// hunting for stinkman
			if(emagged) //lol fuck em up
				currentspeed = 3.5
				start_washing()
				mad = TRUE
			else
				switch(frustration)
					if(0 to 4)
						currentspeed = 5
						mad = FALSE
					if(5 to INFINITY)
						currentspeed = 2.5
						mad = TRUE
			if(target && !check_purity(target))
				if(target.loc == loc && isturf(target.loc)) //LADIES AND GENTLEMAN WE GOTEM PREPARE TO DUMP
					start_washing()
					if(mad)
						speak("На тебя ушло много времени, ебучий дегенерат.", "Неужели блять.", "Спасибо боже, ты наконец остановился, пидорас.")
						playsound(loc, 'sound/effects/hygienebot_angry.ogg', 60, 1)
						mad = FALSE
					mode = BOT_SHOWERSTANCE
				else
					stop_washing()
					var/olddist = get_dist(src, target)
					if(olddist > 20 || frustration > 100) // Focus on something else
						back_to_idle()
						return
					SSmove_manager.move_to(src, target, 0, currentspeed)
					if(mad && prob(min(frustration * 2, 60)))
						playsound(loc, 'sound/effects/hygienebot_angry.ogg', 60, 1)
						speak(pick("Вернись обратно, вонючий педик!", "ПРЕКРАТИ БЕЖАТЬ ИЛИ Я ВСКРОЮ ТЕБЕ БЕДРЕННУЮ АРТЕРИЮ!", "Дай же мне просто помыть тебя, ублюдок!", "ХВАТИТ. УБЕГАТЬ.", "Если ты сейчас же не перестанешь убегать от меня, то я выкину тебя в космос, блять.", "Я просто хочу помыть тебя, ебучий троглодит.", "Если ты сейчас же не подойдёшь ко мне, то я пущу в тебя зелёный дым."))
					if((get_dist(src, target)) >= olddist)
						frustration++
					else
						frustration = 0
			else
				back_to_idle()

		if(BOT_SHOWERSTANCE)
			if(check_purity(target))
				speak("Наслаждайтесь чистым и опрятным днем!")
				playsound(loc, 'sound/effects/hygienebot_happy.ogg', 60, 1)
				back_to_idle()
				return
			if(!target)
				last_found = world.time
			if(target.loc != loc || !isturf(target.loc))
				back_to_hunt()

		if(BOT_START_PATROL)
			look_for_lowhygiene()
			start_patrol()

		if(BOT_PATROL)
			look_for_lowhygiene()
			bot_patrol()

/mob/living/simple_animal/bot/hygienebot/proc/back_to_idle()
	mode = BOT_IDLE
	SSmove_manager.stop_looping(src)
	target = null
	frustration = 0
	last_found = world.time
	stop_washing()
	INVOKE_ASYNC(src, PROC_REF(handle_automated_action))

/mob/living/simple_animal/bot/hygienebot/proc/back_to_hunt()
	frustration = 0
	mode = BOT_HUNT
	stop_washing()
	INVOKE_ASYNC(src, PROC_REF(handle_automated_action))

/mob/living/simple_animal/bot/hygienebot/proc/look_for_lowhygiene()
	for (var/mob/living/carbon/human/H in view(7,src)) //Find the NEET
		if((H.name == oldtarget_name) && (world.time < last_found + 100))
			continue
		if(!check_purity(H)) //Theyre impure
			target = H
			oldtarget_name = H.name
			speak("Обнаружен антисанитарный клиент. Пожалуйста, стойте спокойно.")
			playsound(loc, 'sound/effects/hygienebot_happy.ogg', 60, 1)
			visible_message("<b>[capitalize(src.name)]</b> направляется к [H.name]!")
			mode = BOT_HUNT
			INVOKE_ASYNC(src, PROC_REF(handle_automated_action))
			break
		else
			continue

/mob/living/simple_animal/bot/hygienebot/proc/start_washing()
	washing = TRUE
	update_icon()

/mob/living/simple_animal/bot/hygienebot/proc/stop_washing()
	washing = FALSE
	update_icon()



/mob/living/simple_animal/bot/hygienebot/get_controls(mob/user)
	var/list/dat = list()
	dat += hack(user)
	dat += showpai(user)
	dat += {"
<TT><B>Автоматический санитарный юнит X2</B></TT><BR><BR>
Состояние: ["<A href='?src=[REF(src)];power=[TRUE]'>[on ? "Вкл" : "Выкл"]</A>"]<BR>
Управление поведением [locked ? "заблокировано" : "разблокировано"]<BR>
Техническая панель [open ? "открыта" : "закрыта"]"}

	if(!locked || issilicon(user) || isAdminGhostAI(user))
		dat += {"<BR> Авто-патруль: ["<A href='?src=[REF(src)];operation=patrol'>[auto_patrol ? "Вкл" : "Выкл"]</A>"]"}

	return	dat.Join("")

/mob/living/simple_animal/bot/hygienebot/proc/check_purity(mob/living/L)
	if((emagged == 2) && L.stat != DEAD)
		return FALSE

	for(var/X in list(ITEM_SLOT_HEAD, ITEM_SLOT_MASK, ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING, ITEM_SLOT_FEET))

		var/obj/item/I = L.get_item_by_slot(X)
		if(I && HAS_BLOOD_DNA(I))
			return FALSE
	return TRUE

/mob/living/simple_animal/bot/hygienebot/proc/do_wash(atom/A)
	if(emagged)
		A.fire_act()  //lol pranked no cleaning besides that
	else
		A.wash(CLEAN_WASH)



/obj/machinery/bot_core/hygienebot
	req_one_access = list(ACCESS_JANITOR, ACCESS_ROBOTICS)
